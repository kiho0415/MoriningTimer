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
    var timeCountNumbertop: Int = 0
    var timeCountNumber: Int = 0
    var sum: Int = 0
    var changedsum = String()
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
        
        startButton.layer.cornerRadius = 42
        stopButton.layer.cornerRadius = 42
        
        for i in 0...timerSetDataArray.count - 1{
            sum = sum + timerSetDataArray[i].time
        }
        sumchange()
        tillArriveLabel.text = changedsum
        
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
        
        cell.nextnumberlabel?.text = String(timerSetDataArray[indexPath.row + arrayInNumber + 1].order)
        cell.nexttodolabel?.text = String(timerSetDataArray[indexPath.row + arrayInNumber + 1].todo)
        timeCountNumber = timerSetDataArray[indexPath.row + arrayInNumber + 1].time
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
        if sum > 0{
            sum = sum - 1
            sumchange()
            tillArriveLabel.text = changedsum
        }
        if timeCountNumbertop > 1 {
            timeCountNumbertop = timeCountNumbertop - 1
            timechangetop()
            tillEndLabel.text = changedtimetop
        } else if timeCountNumbertop == 1{
            nexttimer()
        }
    }
 
    @IBAction func start(){
        startTimer()
    }
    @IBAction func stop(){
        if timer.isValid{
            timer.invalidate()
        }    }
    
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
    func sumchange(){
        let second = sum % 60
        let minute = (sum - second) / 60
        changedsum = String(format: "%02d:%02d", minute,second)
    }
    
    func nexttimer(){
        arrayInNumber = arrayInNumber + 1
        if arrayInNumber < timerSetDataArray.count{
            localnotification()
            readyContentLabel.text = timerSetDataArray[arrayInNumber].order
            todoLabel.text = timerSetDataArray[arrayInNumber].todo
            timeCountNumbertop = timerSetDataArray[arrayInNumber].time
            timechangetop()
            tillEndLabel.text = changedtimetop
            table.reloadData()  //cellの個数がarrayInNumberで変化するからここで更新すれば変わる
            print(arrayInNumber)
            print(timerSetDataArray.count)
        } else {
            timer.invalidate()
            let alert: UIAlertController = UIAlertController(title: "", message: "準備完了時間です。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { //アラートが消えるのと画面遷移が重ならないように0.5秒後に画面遷移
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                )
            )
            present(alert, animated: true, completion: nil)
        }
    }
    
    func localnotification() {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.title = "お知らせ"
        content.body = "次の\(timerSetDataArray[arrayInNumber].order)は「\(timerSetDataArray[arrayInNumber].todo)」です。"
        let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request){ (error : Error?) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
}
