//
//  TimerSetData.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/04.
//

import Foundation
import RealmSwift

class TimerSet: Object {
    @objc dynamic var timeset: String = ""
   
}
class TimerSetData: Object{
    @objc dynamic var readynumber: Any = ""
    @objc dynamic var content: Any = ""
    @objc dynamic var time: Any = ""
    
//    Listの定義
    let timesetdatas = List<TimerSetData>()
}


