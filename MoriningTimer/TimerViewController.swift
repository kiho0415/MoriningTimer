//
//  TimerViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/02.
//

import UIKit
import RealmSwift
import UserNotifications

class TimerViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet var table: UITableView!
    @IBOutlet var readyContentLabel: UILabel!
    @IBOutlet var todoLabel: UILabel!
    @IBOutlet var tillEndLabel: UILabel!
    @IBOutlet var tillArriveLabel: UILabel!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    
    let realm = try! Realm()

    var timer:Timer = Timer()
//    var sumTimer:Timer = Timer()
    var timeCountNumbertop: Int = 0
    var timeCountNumber: Int = 0
    var sum: Int = 0
    var changedsum: String = ""
   
    var changedtimetop = String()
    var changedtime = String()
    let timerSetDataArray = try! Realm().objects(TimerSetData.self)
    var orderarray: [String] = []
    var todoarray: [String] = []
    var timearray = [Int]()

    var arrayInNumber :Int =  0

    
 
    override func viewDidLoad() {
        table.register(UINib(nibName: "TimerCell", bundle: nil), forCellReuseIdentifier: "TimerCell")
        
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        
        startButton.layer.cornerRadius = 20
        stopButton.layer.cornerRadius = 20
        
//        for i in 0...timerSetDataArray.count - 1{
//            sum = sum + timerSetDataArray[i].time
//        }
//        timechange()
//        tillArriveLabel.text = changedsum
        //必要な情報の表示　arrayInNumberは0
//        orderarray.append(timerSetDataArray.order)
        readyContentLabel.text = timerSetDataArray[arrayInNumber].order
        todoLabel.text = timerSetDataArray[arrayInNumber].todo
        timeCountNumbertop = timerSetDataArray[arrayInNumber].time
        timechangetop()
        tillEndLabel.text = changedtimetop
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timerSetDataArray.count - 1 - arrayInNumber
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimerCell", for: indexPath) as! TimerCell
        ///ここでfor分の繰り返し処理 配列の中身を全部表示する
//        for arrayInNumber in 0...timerSetDataArray.count - 1 {
            cell.nextnumberlabel?.text = String(timerSetDataArray[indexPath.row + arrayInNumber + 1].order)
            timeCountNumber = timerSetDataArray[indexPath.row + arrayInNumber + 1].time
            timechange()
            cell.nexttimelabel?.text =  String(changedtime)
//        }
        return cell
    }
    
    func startTimer() {
        if !timer.isValid{
            timer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(self.count),
                userInfo: nil,
                repeats: true)
        }
    }
    
//    func startSumTimer() {
//        if !sumTimer.isValid{
//            sumTimer = Timer.scheduledTimer(
//                timeInterval: 1,
//                target: self,
//                selector: #selector(self.sumcount),
//                userInfo: nil,
//                repeats: true)
//        }
//    }
    
    @objc func count(){
        if timeCountNumbertop > 0 {
            timeCountNumbertop = timeCountNumbertop - 1
            timechangetop()
            tillEndLabel.text = changedtimetop
        } else if timeCountNumbertop == 0{
            nexttimer()
            ///ここでセルの内容も変える
        }

    }
//    @objc func sumcount(){
//        timeCountNumbertop = timeCountNumbertop - 1
//        sumchange()
//        tillArriveLabel.text = changedsum
//    }
    
    @IBAction func start(){
        startTimer()
//        startSumTimer()
    }
    @IBAction func stop(){
        if timer.isValid{//一時停止
            timer.invalidate()
        }else{//タイマーを動かす
            ///何もしない
        }
    }
    
    func timechange(){
        let second = timeCountNumber % 60
        let minute = (timeCountNumber - second) / 60
        changedtime = String(format: "%02d:%02d", minute,second)
    }
    func timechangetop(){
        let second = timeCountNumbertop % 60
        let minute = (timeCountNumbertop - second) / 60
        changedtimetop = String(format: "%02d:%02d", minute,second)
    }
    
//    func sumchange(){
//        let second = sum % 60
//        let minute = (sum - second) / 60
//        changedsum = String(format: "%02d:%02d", minute,second)
//    }
    
    func nexttimer(){
        if arrayInNumber < timerSetDataArray.count{
            //まず表示
            arrayInNumber = arrayInNumber + 1
            readyContentLabel.text = timerSetDataArray[arrayInNumber].order
            todoLabel.text = timerSetDataArray[arrayInNumber].todo
            timeCountNumbertop = timerSetDataArray[arrayInNumber].time
            timechangetop()
            tillEndLabel.text = changedtimetop
            table.reloadData()  //cellの個数がarrayInNumberで変化するからここで更新すれば変わる
            print(arrayInNumber)
            print(timerSetDataArray.count)
            //したら配列から消しちゃう
//            timerSetDataArray[0].delete
        } else {
            print("超えた")
            let alert: UIAlertController = UIAlertController(title: "", message: "準備完了です。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        //アラートが消えるのと画面遷移が重ならないように0.5秒後に画面遷移するようにしてる
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // 0.5秒後に実行したい処理
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                )
            )
            present(alert, animated: true, completion: nil)
        }

    }

    //ローカル通知まだいじりちゅう
    func localnotification() {
            // ローカル通知の内容
            let content = UNMutableNotificationContent()
            content.sound = UNNotificationSound.default
            content.title = "お知らせ"
//            content.subtitle = "タイマー通知"
            content.body = "次の準備に移ってください"

            // タイマーの時間（秒）をセット
            let timer = 10
            // ローカル通知リクエストを作成
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timer), repeats: false)
            let identifier = NSUUID().uuidString
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request){ (error : Error?) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }

}
