//
//  TimerSetData.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/04.
//

import Foundation
import RealmSwift

//class TimerSet: Object {
//    @objc dynamic var timeset: String = ""
//
//}
class TimerSetData: Object{
    @objc dynamic var readynumber: Any = ""
    @objc dynamic var content: Any = ""
    @objc dynamic var time: Any = ""
    //Listの定義
    var tags = List<Tag>()
}

class Tag: Object {
//    @objc dynamic var tagName = ""
    var timesetdatas: LinkingObjects<TimerSetData> {
        return LinkingObjects(fromType: TimerSetData.self, property: "tags")
    }
}
//class Task: Object {
//    @objc dynamic var taskTitle: String = ""
//    //Listの定義
//    let tickets = List<Ticket>()
//}
//
//class Ticket: Object {
//    @objc dynamic var ticketTitle: String = ""
//}
