//
//  TimerSetData.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/04.
//

import Foundation
import RealmSwift

class TimerSetData: Object{
    @objc dynamic var readtnumber: String = ""
    @objc dynamic var content: String = ""
    @objc dynamic var time: Int = 0
    
//    func  remove() {
//        try! realm!.write {
//            realm!.delete(self)
//        }
//
//    }
}
