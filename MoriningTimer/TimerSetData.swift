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
    //Listの定義
    var order = List<String>()
    var todo = List<String>()
    var time = List<Int>()
}

class Tag: Object {
//    @objc dynamic var tagName = ""
    var timesetdatas: LinkingObjects<TimerSetData> {
        return LinkingObjects(fromType: TimerSetData.self, property: "order")
        return LinkingObjects(fromType: TimerSetData.self, property: "todo")
        return LinkingObjects(fromType: TimerSetData.self, property: "time")
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
