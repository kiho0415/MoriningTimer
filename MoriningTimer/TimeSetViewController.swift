//
//  TimeSetViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/02.
//

import UIKit
import RealmSwift

class TimeSetViewController: UIViewController,UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet var table: UITableView!
    @IBOutlet var startButton: UIButton!
    
    //タイマーの秒数を表示する
    var timeCountNumber: Int = 0
    var timer: Timer = Timer()
    var changedtime = String()
    
    var orderarray = [String]()
    var contentarray = [String]()
    var timearray = [String]()
    //    let realm = try! Realm()
    
    override func viewDidLoad() {
        table.register(UINib(nibName: "TimeSetCell", bundle: nil), forCellReuseIdentifier: "TimeSetCell")
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        
        //startButton.setTitle("開始", for: .normal)
        //cell.contenttextfield.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell", for: indexPath) as! TimeSetCell
        let readynumber = indexPath.row + 1
        cell.orderLabel.text = "準備\(readynumber)"
        cell.timeLabel.text = changedtime
        
        //        orderarray.append((cell?.orderLabel?.text)!)
        //        contentarray.append((cell?.contentTextField?.text)!)
        
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
        timeCountNumber = timeCountNumber + 1
        let second = timeCountNumber % 60
        let minute = (timeCountNumber - second) / 60
        changedtime = String(format: "%02d:%02d", minute,second)
        self.table.reloadData()
        print(changedtime)
    }
    
    @IBAction func start(){
        if timer.isValid{//一時停止
            timer.invalidate()
            startButton.setTitle("スタート", for: .highlighted)
        }else{//タイマーを動かす
            startTimer()
            startButton.setTitle("ストップ", for: .highlighted)///ボタンが切り替わらない
        }
    }
    
    @IBAction func reset(){
        timer.invalidate()
        timeCountNumber =  0
    }
    
    @IBAction func next(){
        //このボタンを押すごとに要素を配列に追加してそれをtableviewで表示
        //next押したら配列に追加してlabelには配列のindexpath.rowばん目を表示させる。一つ前のせるのlabelはもうそれで固定する= 最新のセルだけ更新するとか？
        timearray.append(changedtime)
        
    }
    
    @IBAction func save(){
        //        let updatetimersetdata = TimerSetData()
        //        updatetimersetdata.readtnumber =
        //            updatetimersetdata.content = //"ここでtextfieldに入力した内容を取得する"
        //            updatetimersetdata.time = timeCountNumber
        
        //        if timeCountNumber != 0{
        //            try! realm.write(){
        //                realm.add(updatetimersetdata)
        //                // let timerData = try! Realm().objects(TimerSetData.self)
        //            }
        //        }
    }
}
