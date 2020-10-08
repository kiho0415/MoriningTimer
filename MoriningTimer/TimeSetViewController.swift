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
    var readynumber = Int()
    var todocontent = String()
    
    var orderarray = [String]()
    var todoarray = [String]()
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
        return orderarray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell", for: indexPath) as! TimeSetCell
        readynumber = indexPath.row + 1
        todocontent = cell.contentTextField.text!
        if indexPath.row != orderarray.count{//最後以外のcell
            cell.orderLabel.text = orderarray[indexPath.row]
        }else{//最後のcell
            cell.orderLabel.text = "準備\(readynumber)"
            cell.timeLabel.text = changedtime
        }
        

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
//        print(changedtime)
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
        if timer.isValid {//計測中
                timer.invalidate()
                timeCountNumber =  0
                ///ここでタイマーの数字変わるようにしたい
        } else {//タイマー止まってるとき
            if orderarray == [] {//スタートの前にリセットを押す
                ///何もしない
            } else {//2番目以降のセル：この時は動いているセルのデータが配列に保存されていないので配列の最後を削除しなくて良い
                timeCountNumber = 0
            }
        }
        self.table.reloadData()
        print("resetおすと\(orderarray),\(todoarray),\(timearray)")
    }
    
    @IBAction func next(){
        if timer.isValid {//計測中に次へ
            orderarray.append("準備\(readynumber)")
//          todoarray.append(todocontent)
            timearray.append(changedtime)
            timeCountNumber =  0
        } else {//タイマー止まってるときに次へ
            if orderarray == [] {//スタートの前にリセットを押す
                ///何もしない
            } else {
                orderarray.append("準備\(readynumber)")
//              todoarray.append(todocontent)
                timearray.append(changedtime)
                timeCountNumber =  0
                startTimer()
            }
        }
        self.table.reloadData()
        print("nextおすと\(orderarray),\(todoarray),\(timearray)")
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
