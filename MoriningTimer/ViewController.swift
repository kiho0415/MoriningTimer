//
//  ViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/01.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

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
                        self.dismiss(animated: true, completion: nil)
                    }
                )
            )
            present(alert, animated: true, completion: nil)
        }else{
            let alert: UIAlertController = UIAlertController(title: "タイマーを開始", message: "次の準備に移るタイミングを通知でお知らせします。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        self.performSegue(withIdentifier: "totimer", sender: nil)
                    }
                )
            )
            alert.addAction(
                UIAlertAction(
                    title: "キャンセル",
                    style: .cancel,
                    handler: { action in
                        self.navigationController?.popViewController(animated: true)
                    }
                )
            )
            present(alert, animated: true, completion: nil)
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

