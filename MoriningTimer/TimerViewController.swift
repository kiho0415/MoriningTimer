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
    
    let realm = try! Realm()

    var timer:Timer = Timer()
    var timeCountNumbertop: Int = 0
    var timeCountNumber: Int = 0
    var orderarray: [String] = []
    var todoarray: [String] = []
    var timearray = [Int]()
    var changedtimetop = String()
    var changedtime = String()
    let timerSetDataArray = try! Realm().objects(TimerSetData.self)
    var arrayInNumber :Int =  0

    override func viewDidLoad() {
        table.register(UINib(nibName: "TimerCell", bundle: nil), forCellReuseIdentifier: "TimerCell")
        
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        
        //必要な情報の表示　arrayInNumberは0
        readyContentLabel.text = timerSetDataArray[arrayInNumber].order
        todoLabel.text = timerSetDataArray[arrayInNumber].todo
        timeCountNumbertop = timerSetDataArray[arrayInNumber].time
        timechangetop()
        tillEndLabel.text = changedtimetop
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timerSetDataArray.count - 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimerCell", for: indexPath) as! TimerCell
        cell.nextnumberlabel?.text = String(timerSetDataArray[indexPath.row + 1].order)
        timeCountNumber = timerSetDataArray[indexPath.row + 1].time
        timechange()
        cell.nexttimelabel?.text =  String(changedtime)
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
    
    @objc func count(){
        if timeCountNumbertop > 0 {
            timeCountNumbertop = timeCountNumbertop - 1
            timechangetop()
            tillEndLabel.text = changedtimetop
        } else if timeCountNumbertop == 0{
//            timer.invalidate()　タイマー止めなくていいんじゃないか
            
            //changetimetopかえる

        }

    }
    
    @IBAction func start(){
            startTimer()
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

    ///ラベルのタイマーが00:00になった時にこのメソッドを呼び出したい
    func nexttimer(){
        if arrayInNumber < timerSetDataArray.count{
            arrayInNumber = arrayInNumber + 1
            readyContentLabel.text = timerSetDataArray[arrayInNumber].order
            todoLabel.text = timerSetDataArray[arrayInNumber].todo
            timeCountNumbertop = timerSetDataArray[arrayInNumber].time
            timechangetop()
            tillEndLabel.text = changedtimetop
        } else {
            ///何もしないorローカル通知
        }
       
    }
}
