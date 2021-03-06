////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#include "sync/partial_sync.hpp"

#include "impl/collection_notifier.hpp"
#include "impl/notification_wrapper.hpp"
#include "impl/realm_coordinator.hpp"
#include "object_schema.hpp"
#include "object_store.hpp"
#include "results.hpp"
#include "shared_realm.hpp"
#include "sync/impl/work_queue.hpp"
#include "sync/subscription_state.hpp"
#include "sync/sync_config.hpp"
#include "sync/sync_session.hpp"

#include <realm/util/scope_exit.hpp>

#include <cstdint>
#include <limits>

using namespace std::chrono;

namespace {

    // Delete all subscriptions that are no longer relevant.
    // This method must be called within a write transaction.
    void cleanup_subscriptions(realm::Group& group, realm::Timestamp now)
    {
        // Remove all subscriptions no longer considered "active"
        // "inactive" is currently defined as any subscription with an `expires_at` < now()`
        //
        // Note, that we do not check if someone is actively using the subscription right now (this
        // is also hard to get right). This does leave some loop holes where a subscription might be
        // removed while still in use. E.g. consider a Kiosk app showing a screen 24/7 with a background
        // job that accidentially triggers the cleanup codepath. This case is considered rare, but should
        // still be documented.
        auto table = realm::ObjectStore::table_for_object_type(group, realm::partial_sync::result_sets_type_name);

        auto expires_at_col_ndx = table->get_column_key(realm::partial_sync::property_expires_at);
        realm::TableView results = table->where().less(expires_at_col_ndx, now).find_all();
        results.clear();
    }

    // Calculates the expiry date, claming at the high end if a timestamp overflows
    realm::Timestamp calculate_expiry_date(realm::Timestamp starting_time, int64_t user_ttl_ms)
    {
        auto tp = starting_time.get_time_point();
        using time_point = decltype(tp);
        milliseconds ttl(user_ttl_ms);
        if (time_point::max() - ttl < tp)
            return time_point::max();
        return tp + ttl;
    }

    using namespace ::realm;
    using namespace ::realm::partial_sync;
    struct ParitalSyncProperty {
        const char *name;
        DataType type;
        bool nullable;
        bool indexed;
    };

    static constexpr const ParitalSyncProperty s_partial_sync_schema[] = {
        {property_query, type_String, false, false},
        {property_matches_property_name, type_String, false, false},
        {property_status, type_Int, false, false},
        {property_error_message, type_String, false, false},
        {property_query_parse_counter, type_Int, false, false},

        // Add columns not required by Sync, but used by the bindings to offer better tracking of subscriptions.
        // These columns are not automatically added by the server, so we need to add them manually if needed.

        // Name used to uniquely identify a subscription. If a name isn't provided for a subscription one will be
        // autogenerated.
        {property_name, type_String, false, true},

        // Timestamp for when then the subscription is created. This should only be set the first time the subscription
        // is created.
        {property_created_at, type_Timestamp, false, false},

        // Timestamp for when the subscription is either updated or someone resubscribes to it.
        {property_updated_at, type_Timestamp, false, false},

        // Relative time-to-live in milliseconds. This indicates the period from when a subscription was last updated
        // to when it isn't considered valid anymore and can be safely deleted. Realm will attempt to perform this
        // cleanup automatically either when the app is started or someone discards the subscription token for it.
        {property_time_to_live, type_Int, true, false},  // null = infinite TTL

        // Timestamp representing the fixed point in time when this subscription isn't valid anymore and can
        // be safely deleted. This value should be considered read-only from the perspective of any Bindings
        // and should never be modified by itself, but only updated whenever the `updatedAt` or `timefield is.
        {property_expires_at, type_Timestamp, true, false},  // null = Subscription never expires
    };
}

namespace realm {

namespace _impl {
using namespace ::realm::partial_sync;

void initialize_schema(Group& group)
{
    std::string result_sets_table_name = ObjectStore::table_name_for_object_type(result_sets_type_name);
    TableRef table = group.get_table(result_sets_table_name);
    if (!table) {
        // Create the schema required by Sync
        table = group.get_or_add_table(result_sets_table_name);
    }

    // Create all required properties which don't already exist
    for (auto& property : s_partial_sync_schema) {
        if (table->get_column_key(property.name))
            continue;
        auto idx = table->add_column(property.type, property.name, property.nullable);
        if (property.indexed)
            table->add_search_index(idx);
    }

    // Remove any subscriptions no longer relevant
    cleanup_subscriptions(group, system_clock::now());
}

void ensure_partial_sync_schema_initialized(Realm& realm)
{
    auto was_in_read = realm.is_in_read_transaction();
    auto cleanup = util::make_scope_exit([&]() noexcept {
        if (realm.is_in_transaction())
            realm.cancel_transaction();
        if (!was_in_read)
            realm.invalidate();
    });

    auto has_all_required_columns = [](auto& table) -> bool {
        return std::all_of(std::begin(s_partial_sync_schema), std::end(s_partial_sync_schema),
                           [&](auto& property) { return table.get_column_key(property.name).operator bool(); });
    };

    auto& group = realm.read_group();
    // Check if the result sets table already has the expected number of columns
    auto table = ObjectStore::table_for_object_type(group, result_sets_type_name);
    if (table && has_all_required_columns(*table))
        return;

    realm.begin_transaction();
    // Recheck after starting the transaction as it refreshes
    if (!table)
        table = ObjectStore::table_for_object_type(group, result_sets_type_name);
    if (table && has_all_required_columns(*table))
        return;
    initialize_schema(group);
    realm.commit_transaction();
}

// A stripped-down version of WriteTransaction that can promote an existing read transaction
// and that notifies the sync session after committing a change.
class WriteTransactionNotifyingSync {
public:
    WriteTransactionNotifyingSync(Realm::Config const& config, TransactionRef tr)
    : m_config(config)
    , m_tr(std::move(tr))
    {
        if (m_tr->get_transact_stage() == DB::TransactStage::transact_Reading)
            m_tr->promote_to_write();
    }

    ~WriteTransactionNotifyingSync()
    {
        if (m_tr)
            m_tr->rollback();
    }

    DB::version_type commit()
    {
        REALM_ASSERT(m_tr);
        auto version = m_tr->commit();
        m_tr = nullptr;

        auto session = SyncManager::shared().get_session(m_config.path, *m_config.sync_config, false);
        SyncSession::Internal::nonsync_transact_notify(*session, version);
        return version;
    }

    void rollback()
    {
        REALM_ASSERT(m_tr);
        m_tr->rollback();
        m_tr = nullptr;
    }

    Group& get_group() const noexcept
    {
        REALM_ASSERT(m_tr);
        return *m_tr;
    }

private:
    Realm::Config const& m_config;
    TransactionRef m_tr;
};

// Provides a convenient way for code in this file to access private details of `Realm`
// without having to add friend declarations for each individual use.
class PartialSyncHelper {
public:
    static decltype(auto) get_shared_group(Realm& realm)
    {
        return Realm::Internal::get_db(realm);
    }

    static decltype(auto) get_coordinator(Realm& realm)
    {
        return Realm::Internal::get_coordinator(realm);
    }
};

/*
template<typename... Args>
static auto export_for_handover(Realm& realm, Args&&... args)
{
    auto& sg = *PartialSyncHelper::get_shared_group(realm);
    sg.pin_version();
    auto handover = sg.export_for_handover(std::forward<Args>(args)...);
    // We need to store the handover object in a shared_ptr because it's captured
    // in a std::function<>, which requires copyable objects
    return std::make_shared<decltype(handover)>(std::move(handover));
}

template<typename T>
static auto import_from_handover(SharedGroup& sg, std::unique_ptr<SharedGroup::Handover<T>>& handover)
{
    sg.begin_read(handover->version);
    auto obj = sg.import_from_handover(std::move(handover));
    sg.unpin_version(sg.get_version_of_current_transaction());
    return *obj;
}
*/

} // namespace _impl

namespace partial_sync {

InvalidRealmStateException::InvalidRealmStateException(const std::string& msg)
: std::logic_error(msg)
{}

ExistingSubscriptionException::ExistingSubscriptionException(const std::string& msg)
: std::runtime_error(msg)
{}

QueryTypeMismatchException::QueryTypeMismatchException(const std::string& msg)
: std::logic_error(msg)
{}

namespace {

struct ResultSetsColumns {
    ResultSetsColumns(Table& table, std::string const& matches_property_name)
    {
        name = table.get_column_key(property_name);
        REALM_ASSERT(name);

        query = table.get_column_key(property_query);
        REALM_ASSERT(query);

        error_message = table.get_column_key(property_error_message);
        REALM_ASSERT(error_message);

        status = table.get_column_key(property_status);
        REALM_ASSERT(status);

        this->matches_property_name = table.get_column_key(property_matches_property_name);
        REALM_ASSERT(this->matches_property_name);

        created_at = table.get_column_key(property_created_at);
        REALM_ASSERT(created_at);

        updated_at = table.get_column_key(property_updated_at);
        REALM_ASSERT(updated_at);

        expires_at = table.get_column_key(property_expires_at);
        REALM_ASSERT(expires_at);

        time_to_live = table.get_column_key(property_time_to_live);
        REALM_ASSERT(time_to_live);

        // This may be `npos` if the column does not yet exist.
        matches_property = table.get_column_key(matches_property_name);
    }

    ColKey name;
    ColKey query;
    ColKey error_message;
    ColKey status;
    ColKey matches_property_name;
    ColKey matches_property;
    ColKey created_at;
    ColKey updated_at;
    ColKey expires_at;
    ColKey time_to_live;
};

// Performs the logic of actually writing the subscription (if needed) to the Realm and making sure
// that the `matches_property` field is setup correctly. This method will throw if the query cannot
// be serialized or the name is already used by another subscription.
//
// The row of the resulting subscription is returned. If an old subscription exists that matches
// the one about to be created, a new subscription is not created, but the old one is returned
// instead.
//
// If `update = true` and  if a subscription with `name` already exists, its query and time_to_live
// will be updated instead of an exception being thrown if the query parsed in was different than
// the persisted query.
Obj write_subscription(std::string const& object_type, std::string const& name, std::string const& query,
        util::Optional<int64_t> time_to_live_ms, bool update, Group& group)
{
    Timestamp now = system_clock::now();
    auto matches_property = std::string(object_type) + "_matches";

    auto table = ObjectStore::table_for_object_type(group, result_sets_type_name);
    ResultSetsColumns columns(*table, matches_property);

    // Update schema if needed.
    if (!columns.matches_property) {
        auto target_table = ObjectStore::table_for_object_type(group, object_type);
        columns.matches_property = table->add_column_link(type_LinkList, matches_property, *target_table);
    }
    else {
        // FIXME: Validate that the column type and link target are correct.
    }

    // Find existing subscription (if any)
    auto obj_key = table->find_first_string(columns.name, name);
    Obj subscription;
    if (obj_key) {
        subscription = table->get_object(obj_key);
        // Check that we don't attempt to replace an existing query with a query on a new type.
        // There is nothing that prevents Sync from handling this, but allowing it will complicate
        // Binding API's, so for now it is disallowed.
        auto existing_matching_property = subscription.get<String>(columns.matches_property_name);
        if (existing_matching_property != matches_property) {
            throw QueryTypeMismatchException(util::format("Replacing an existing query with a query on "
                                                          "a different type is not allowed: %1 vs. %2 for %3",
                                                          existing_matching_property, matches_property, name));
        }

        // If an subscription exist, we only update the query and TTL if allowed to.
        // TODO: Consider how Binding API's are going to use this. It might make sense to disallow
        // updating TTL using this API and instead require updates to TTL to go through a managed Subscription.
        if (update) {
            // If the query changed we must reset state to force the server to re-evaluate the subscription.
            if (subscription.get<String>(columns.query) != query) {
                subscription.set(columns.error_message, "");
                subscription.set(columns.status, 0);
            }
            subscription.set(columns.query, query);
            subscription.set(columns.time_to_live, time_to_live_ms);
        }
        else {
            StringData existing_query = subscription.get<String>(columns.query);
            if (existing_query != query)
                throw ExistingSubscriptionException(util::format("An existing subscription exists with the name '%1' "
                                                                 "but with a different query: '%1' vs '%2'",
                                                                 name, existing_query, query));
        }

    }
    else {
        // No existing subscription was found. Create a new one
        subscription = table->create_object();
        subscription.set(columns.name, name);
        subscription.set(columns.query, query);
        subscription.set(columns.matches_property_name, matches_property);
        subscription.set(columns.created_at, now);
        subscription.set(columns.time_to_live, time_to_live_ms);
    }

    // Always set updated_at/expires_at when a subscription is touched, no matter if it is new, updated or someone just
    // resubscribes.
    subscription.set(columns.updated_at, now);
    time_to_live_ms = subscription.get<util::Optional<Int>>(columns.time_to_live);
    if (!time_to_live_ms || *time_to_live_ms == std::numeric_limits<int64_t>::max()) {
        subscription.set_null(columns.expires_at);
    }
    else {
        subscription.set(columns.expires_at, calculate_expiry_date(now, *time_to_live_ms));
    }

    cleanup_subscriptions(group, now);
    return subscription;
}

void enqueue_registration(Realm& realm, std::string object_type, std::string query, std::string name,
                          util::Optional<int64_t> time_to_live, bool update,
                          std::function<void(std::exception_ptr)> callback)
{
    auto config = realm.config();
    auto transact = realm.duplicate();

    auto& work_queue = _impl::PartialSyncHelper::get_coordinator(realm).partial_sync_work_queue();
    work_queue.enqueue([object_type, query, name, transact=std::move(transact),
                        callback=std::move(callback), config=std::move(config), time_to_live=time_to_live, update=update] {
        try {
            _impl::WriteTransactionNotifyingSync write(config, std::move(transact));
            write_subscription(object_type, name, query, time_to_live, update, write.get_group());
            write.commit();
        } catch (...) {
            callback(std::current_exception());
            return;
        }

        callback(nullptr);
    });
}

void enqueue_unregistration(Object result_set, std::function<void()> callback)
{
    auto realm = result_set.realm();
    auto config = realm->config();
    auto transact = realm->duplicate();
    auto& work_queue = _impl::PartialSyncHelper::get_coordinator(*realm).partial_sync_work_queue();

    // Export a reference to the __ResultSets row so we can hand it to the worker thread.
    auto obj = result_set.obj();
    auto obj_key = obj.get_key();
    auto table_key = obj.get_table()->get_key();

    work_queue.enqueue([obj_key, table_key, transact=std::move(transact), callback=std::move(callback),
                        config=std::move(config)] () {
        _impl::WriteTransactionNotifyingSync write(config, std::move(transact));
        auto t = write.get_group().get_table(table_key);
        if (t->is_valid(obj_key)) {
            t->remove_object(obj_key);
            write.commit();
        }
        else {
            write.rollback();
        }
        callback();
    });
}

template<typename Notifier>
void enqueue_unregistration(Results const& result_set, std::shared_ptr<Notifier> notifier,
                            std::function<void()> callback)
{
    auto realm = result_set.get_realm();
    auto config = realm->config();
    auto& work_queue = _impl::PartialSyncHelper::get_coordinator(*realm).partial_sync_work_queue();

    // Export a reference to the query which will match the __ResultSets row
    // once it's created so we can hand it to the worker thread
    auto transact = realm->duplicate();
    auto tmp_query = result_set.get_query();
    std::shared_ptr<Query> query = transact->import_copy_of(tmp_query, PayloadPolicy::Move);

    work_queue.enqueue([query=std::move(query), transact=std::move(transact), callback=std::move(callback),
                        config=std::move(config), notifier=std::move(notifier)] () {

        // If creating the subscription failed there might be another
        // pre-existing subscription which matches our query, so we need to
        // not remove that
        if (notifier->failed())
            return;

        _impl::WriteTransactionNotifyingSync write(config, std::move(transact));
        auto obj_key = query->find();
        auto t = query->get_table();
        if (t->is_valid(obj_key)) {
            const_cast<Table&>(*t).remove_object(obj_key);
            write.commit();
        }
        else {
            // If unsubscribe() is called twice before the subscription is
            // even created the row might already be gone
            write.rollback();
        }
        callback();
    });
}

std::string default_name_for_query(const std::string& query, const std::string& object_type)
{
    return util::format("[%1] %2", object_type, query);
}

} // unnamed namespace


struct Subscription::Notifier : public _impl::CollectionNotifier {
    enum State {
        Creating,
        Complete,
        Removed,
    };

    Notifier(std::shared_ptr<Realm> realm)
    : _impl::CollectionNotifier(std::move(realm))
    , m_coordinator(&_impl::PartialSyncHelper::get_coordinator(*get_realm()))
    {
    }

    void run() override
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        if (m_has_results_to_deliver) {
            // Mark the object as being modified so that CollectionNotifier is aware
            // that there are changes to deliver.
            m_change.modify(0);
        }
    }

    void finished_subscribing(std::exception_ptr error)
    {
        {
            std::unique_lock<std::mutex> lock(m_mutex);
            m_pending_error = error;
            m_pending_state = Complete;
            m_has_results_to_deliver = true;
            m_failed = error != nullptr;
        }

        // Trigger processing of change notifications.
        m_coordinator->wake_up_notifier_worker();
    }

    void finished_unsubscribing()
    {
        {
            std::unique_lock<std::mutex> lock(m_mutex);

            m_pending_state = Removed;
            m_has_results_to_deliver = true;
        }

        // Trigger processing of change notifications.
        m_coordinator->wake_up_notifier_worker();
    }

    std::exception_ptr error() const
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        return m_error;
    }

    State state() const
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        return m_state;
    }

    bool failed() const
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        return m_failed;
    }

private:
    void do_attach_to(Transaction&) override { }

    bool do_add_required_change_info(_impl::TransactionChangeInfo&) override { return false; }
    bool prepare_to_deliver() override
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_error = m_pending_error;
        m_pending_error = nullptr;

        m_state = m_pending_state;
        bool had_results = m_has_results_to_deliver;
        m_has_results_to_deliver = false;
        return had_results;

    }

    _impl::RealmCoordinator *m_coordinator;

    mutable std::mutex m_mutex;
    std::exception_ptr m_pending_error = nullptr;
    std::exception_ptr m_error = nullptr;
    bool m_has_results_to_deliver = false;
    bool m_failed = false;

    State m_state = Creating;
    State m_pending_state = Creating;
};

Subscription subscribe(Results const& results, SubscriptionOptions options)
{
    auto realm = results.get_realm();

    auto sync_config = realm->config().sync_config;
    if (!sync_config || !sync_config->is_partial)
        throw InvalidRealmStateException("A Subscription can only be created in a Query-based Realm.");

    auto query = results.get_query().get_description(); // Throws if the query cannot be serialized.
    if (!results.get_descriptor_ordering().is_empty()) {
        query += " " + results.get_descriptor_ordering().get_description(results.get_query().get_table());
    }

    if (options.inclusions.is_valid()) {
        query += " " + options.inclusions.get_description(results.get_query().get_table());
    }

    std::string name = options.user_provided_name ? std::move(*options.user_provided_name)
                                                  : default_name_for_query(query, results.get_object_type());

    Subscription subscription(name, results.get_object_type(), realm);
    std::weak_ptr<Subscription::Notifier> weak_notifier = subscription.m_notifier;
    enqueue_registration(*realm, results.get_object_type(), std::move(query), std::move(name), std::move(options.time_to_live_ms), options.update,
                         [weak_notifier=std::move(weak_notifier)](std::exception_ptr error) {
        if (auto notifier = weak_notifier.lock())
            notifier->finished_subscribing(error);
    });
    return subscription;
}

Obj subscribe_blocking(Results const& results, util::Optional<std::string> user_provided_name,
                       util::Optional<int64_t> time_to_live_ms, bool update)
{

    auto realm = results.get_realm();
    if (!realm->is_in_transaction()) {
        throw InvalidRealmStateException("The subscription can only be created inside a write transaction.");
    }
    auto sync_config = realm->config().sync_config;
    if (!sync_config || !sync_config->is_partial) {
        throw InvalidRealmStateException("A Subscription can only be created in a Query-based Realm.");
    }

    auto query = results.get_query().get_description(); // Throws if the query cannot be serialized.
    if (!results.get_descriptor_ordering().is_empty()) {
        query += " " + results.get_descriptor_ordering().get_description(results.get_query().get_table());
    }
    std::string name = user_provided_name ? std::move(*user_provided_name)
                                          : default_name_for_query(query, results.get_object_type());
    return write_subscription(results.get_object_type(), name, query, time_to_live_ms, update, realm->read_group());
}

void unsubscribe(Subscription& subscription)
{
    if (auto result_set_object = subscription.result_set_object()) {
        // The subscription has its result set object, so we can queue up the unsubscription immediately.
        std::weak_ptr<Subscription::Notifier> weak_notifier = subscription.m_notifier;
        enqueue_unregistration(*result_set_object, [weak_notifier=std::move(weak_notifier)]() {
            if (auto notifier = weak_notifier.lock())
                notifier->finished_unsubscribing();
        });
        return;
    }

    switch (subscription.state()) {
        case SubscriptionState::Creating: {
            // The result set object is in the process of being created. Try unsubscribing again once it exists.
            std::weak_ptr<Subscription::Notifier> weak_notifier = subscription.m_notifier;
            enqueue_unregistration(subscription.m_result_sets, subscription.m_notifier, [weak_notifier=std::move(weak_notifier)]() {
                if (auto notifier = weak_notifier.lock())
                    notifier->finished_unsubscribing();
            });
            return;
        }

        case SubscriptionState::Error:
            // We encountered an error when creating the subscription. There's nothing to remove, so just
            // mark the subscription as removed.
            subscription.m_notifier->finished_unsubscribing();
            break;

        case SubscriptionState::Invalidated:
            // Nothing to do. We have already removed the subscription.
            break;

        case SubscriptionState::Pending:
        case SubscriptionState::Complete:
            // This should not be reachable as these states require the result set object to exist.
            REALM_ASSERT(false);
            break;
    }
}

void unsubscribe(Object&& subscription)
{
    REALM_ASSERT(subscription.get_object_schema().name == result_sets_type_name);
    auto realm = subscription.realm();
    enqueue_unregistration(std::move(subscription), [=] {
        // The partial sync worker thread bypasses the normal machinery which
        // would trigger notifications since it does its own notification things
        // in the other cases, so manually trigger it here.
        _impl::PartialSyncHelper::get_coordinator(*realm).wake_up_notifier_worker();
    });
}

Subscription::Subscription(std::string name, std::string object_type, std::shared_ptr<Realm> realm)
: m_object_schema(realm->read_group(), result_sets_type_name, TableKey())
{
    // FIXME: Why can't I do this in the initializer list?
    m_notifier = std::make_shared<Notifier>(realm);
    _impl::RealmCoordinator::register_notifier(m_notifier);

    auto matches_property = std::string(object_type) + "_matches";

    m_wrapper_created_at = system_clock::now();
    TableRef table = ObjectStore::table_for_object_type(realm->read_group(), result_sets_type_name);
    Query query = table->where();
    query.equal(m_object_schema.property_for_name(property_name)->column_key, name);
    query.equal(m_object_schema.property_for_name(property_matches_property_name)->column_key, matches_property);
    m_result_sets = Results(std::move(realm), std::move(query));
}

Subscription::~Subscription() = default;
Subscription::Subscription(Subscription&&) = default;
Subscription& Subscription::operator=(Subscription&&) = default;

SubscriptionNotificationToken Subscription::add_notification_callback(std::function<void ()> callback)
{
    auto callback_wrapper = std::make_shared<SubscriptionCallbackWrapper>(SubscriptionCallbackWrapper{callback, none});
    auto result_sets_token = m_result_sets.add_notification_callback([this, callback_wrapper] (CollectionChangeSet, std::exception_ptr) {
        run_callback(*callback_wrapper);
    });
    NotificationToken registration_token(m_notifier, m_notifier->add_callback([this, callback_wrapper] (CollectionChangeSet, std::exception_ptr) {
        run_callback(*callback_wrapper);
    }));

    return SubscriptionNotificationToken{std::move(registration_token), std::move(result_sets_token)};
}

util::Optional<Object> Subscription::result_set_object() const
{
    if (m_notifier->state() == Notifier::Complete) {
        if (auto row = m_result_sets.first())
            return Object(m_result_sets.get_realm(), m_object_schema, *row);
    }

    return util::none;
}

void Subscription::run_callback(SubscriptionCallbackWrapper& callback_wrapper) {
    // Store reference to underlying subscription object the first time we encounter it.
    // Used to track if anyone is later deleting it.
    if (!m_result_sets_object && m_result_sets.size() > 0) {
        m_result_sets_object = util::Optional<Obj>(m_result_sets.first());
    }

    // Verify this is a state change we actually want to report to the user
    auto new_state = state();
    if (callback_wrapper.last_state && callback_wrapper.last_state.value() == new_state)
        return;

    callback_wrapper.last_state = util::Optional<SubscriptionState>(new_state);

    // Finally trigger callback
    callback_wrapper.callback();
}

SubscriptionState Subscription::state() const
{
    // State transitions are complex due to multiple source being able to create and modify the subscriptions.
    // This means that there are unavoidable race conditions with regard to the states and we just make
    // a best effort to provide a sensible experience for the end user.
    //
    // In particular this means the following:
    //
    // - There is no guarantee that a user will see all the states from `Creating -> Pending -> Complete`
    //   They might only see `Pending -> Complete` or `Complete`
    //
    // What we do guarantee is:
    //
    // - States will never be reported twice in a row for the same callback. This could e.g. happen if some property
    //   like `updated_at` was updated while the status was still `Pending`, but these properties are not important
    //   until the subscription is actually created. So we intentionally swallow all duplicated state notifications.
    //
    // - When calling `subscribe()` with `update = true` we will never report `Complete` until the updated subscription
    //   reaches that state.

    // Errors take precedence over all other notifications
    if (m_notifier->error())
        return SubscriptionState::Error;

    // In some cases the subscription already exists. In that case we just report the state of the __ResultSets object.
    if (auto object = result_set_object()) {
        auto state = static_cast<SubscriptionState>(object->get_column_value<int64_t>(property_status));
        auto updated_at = object->get_column_value<Timestamp>(property_updated_at);

        if (updated_at < m_wrapper_created_at) {
            // If the `updated_at` property on an existing subscription wasn't updated after the wrapper was created,
            // it meant the query callback triggered before the async write completed. In that case we don't want
            // to return the state associated with the subscription before it was updated. So we override the state
            // in the actual subscription and return the expected state after the update.
            return partial_sync::SubscriptionState::Pending;
        } else {
            return state;
        }
    }

    // If no existing subscription exist, we can use the state of the Notifier as an indication of the underlying
    // progress.
    switch (m_notifier->state()) {
        case Notifier::Creating:
            return SubscriptionState::Creating;
        case Notifier::Removed:
            return SubscriptionState::Invalidated;
        case Notifier::Complete:
            break;
    }

    // If we previously had a reference to the subscription and that is now gone, we interpret that as
    // someone deleted the subscription (without using the explict unsubscribe API).
    if (m_result_sets_object && !m_result_sets_object->is_valid()) {
        return SubscriptionState::Invalidated;
    }

    // We may not have an object even if the subscription has completed if the completion callback fired
    // but the result sets callback is yet to fire.
    return SubscriptionState::Creating;
}

std::exception_ptr Subscription::error() const
{
    if (auto error = m_notifier->error())
        return error;

    if (auto object = result_set_object()) {
        auto message = object->get_column_value<StringData>("error_message");
        if (message.size())
            return make_exception_ptr(std::runtime_error(message));
    }

    return nullptr;
}

} // namespace partial_sync
} // namespace realm
