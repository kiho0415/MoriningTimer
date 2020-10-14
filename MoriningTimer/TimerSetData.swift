//
//  TimerSetData.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/04.
//

import Foundation
import RealmSwift


class TimerSetData: Object{
    @objc dynamic var order: String = ""
    @objc dynamic var todo: String = ""
    @objc dynamic var time: Int = 0
}

///リストを使うときにこれを復活させる
//class TimerSetData: Object{
//    //Listの定義
//    var order = List<String>()
//    var todo = List<String>()
//    var time = List<Int>()
//}
//
//class Tag: Object {
//    var timesetdatas: LinkingObjects<TimerSetData> {
//        return LinkingObjects(fromType: TimerSetData.self, property: "order")
//        return LinkingObjects(fromType: TimerSetData.self, property: "todo")
//        return LinkingObjects(fromType: TimerSetData.self, property: "time")
//    }
//}
