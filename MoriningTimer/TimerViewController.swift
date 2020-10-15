//
//  TimerViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/02.
//

import UIKit
import RealmSwift

class TimerViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
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


//    let orderList = List<String>() //List型
//    var orderarray = Array<Any>() // Array型
//    let orderarray.append(contentsOf: Array(orderList)) // Array()でListを変換
//    let orderarray = Array<Any>()

    override func viewDidLoad() {
        table.register(UINib(nibName: "TimerCell", bundle: nil), forCellReuseIdentifier: "TimerCell")
        
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        
        //必要な情報の表示
        readyContentLabel.text = timerSetDataArray[0].order
        todoLabel.text = timerSetDataArray[0].todo
        timeCountNumbertop = timerSetDataArray[0].time
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
            timer.invalidate()
            timeCountNumbertop =  0
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
}
