//
//  ViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/01.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UNUserNotificationCenterDelegate {

    @IBOutlet var pretimelabel: UILabel!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var setButton: UIButton!
    let realm = try! Realm()
    let timerSetDataArray = try! Realm().objects(TimerSetData.self)
    var sum: Int = 0
    var changedsum: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pretimelabel.text = "測定結果がありません。先に測定してください。"
        startButton.layer.cornerRadius = 50
        setButton.layer.cornerRadius = 50
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sum = 0
        if timerSetDataArray.count != 0{
            for i in 0...timerSetDataArray.count - 1{
                sum = sum + timerSetDataArray[i].time
            }
            sumchange()
            pretimelabel.text = "前回の測定では、準備にかかる合計時間は\(changedsum)でした。"
        } else {
            pretimelabel.text = "測定結果がありません。"
        }
    }

    @IBAction func timerstart(){
        if timerSetDataArray.count == 0 {
            let alert: UIAlertController = UIAlertController(title: "", message: "測定結果がありません。先に測定を行ってください。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
        }else{
//            if #available(iOS 10.0, *) {
//                // iOS 10
//                let center = UNUserNotificationCenter.current()
//                center.requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { (granted, error) in
//                    if error != nil {
//                        return
//                    }
//                    if granted {
//                        print("通知許可")
//                        let center = UNUserNotificationCenter.current()
//                        center.delegate = self
//                    } else {
//                        print("通知拒否")
//                    }
//                })
//            } else {
//                // iOS 9以下
//                let settings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
//                UIApplication.shared.registerUserNotificationSettings(settings)
//            }
            self.performSegue(withIdentifier: "totimer", sender: nil)
        }
    }
    @IBAction func timeset(){
        let alert: UIAlertController = UIAlertController(title: "", message: "測定を始めます。次の準備に移るときに「次の準備へ」を押してください。", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default,
                handler: { action in
                    self.dismiss(animated: true, completion: nil)
                }
            )
        )
        present(alert, animated: true, completion: nil)

    }
    
    func sumchange(){
        let second = sum % 60
        let minute = (sum - second) / 60
        changedsum = String(format: "%02d分%02d秒", minute,second)
    }

}

