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
    
    var orderdictionary = [String: Any]()
    var tododictionary = [String: Any]()
    var timedictionary = [String: Any]()

    let realm = try! Realm()
    
    
    override func viewDidLoad() {
        table.register(UINib(nibName: "TimeSetCell", bundle: nil), forCellReuseIdentifier: "TimeSetCell")
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        
        //startButton.setTitle("開始", for: .normal)
        //cell.contenttextfield.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderdictionary.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell", for: indexPath) as! TimeSetCell
        readynumber = indexPath.row + 1
        todocontent = cell.contentTextField.text!
        if indexPath.row != orderdictionary.count{//最後以外のcell
            cell.orderLabel.text = orderdictionary[indexPath.row]
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
        print("resetおすと\(orderdictionary),\(tododictionary),\(timedictionary)")
    }
    
    @IBAction func next(){
        if timer.isValid {//計測中に次へ
            orderdictionary.append("準備\(readynumber)")
          todoarray.append(todocontent)
            timearray.append(changedtime)
            timeCountNumber =  0
        } else {//タイマー止まってるときに次へ
            if orderarray == [] {//スタートの前にリセットを押す
                ///何もしない
            } else {
                orderarray.append("準備\(readynumber)")
              todoarray.append(todocontent)
                timearray.append(changedtime)
                timeCountNumber =  0
                startTimer()
            }
        }
        self.table.reloadData()
        print("nextおすと\(orderdictionary),\(tododictionary),\(timedictionary)")
    }

    
    @IBAction func save(){
        
        if timer.isValid{
            timeCountNumber =  0
        }

        let updatetimersetdata = TimerSetData(value: orderdictionary)
        updatetimersetdata.readynumber = orderdictionary
        updatetimersetdata.content = tododictionary
        updatetimersetdata.time = timedictionary
        
        if todoarray.count != orderarray.count && orderarray.count != 0 {
            let alert: UIAlertController = UIAlertController(title: "", message: "準備の内容を登録してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in})
            )
            present(alert, animated: true, completion: nil)
        } else {
            orderarray.append("準備\(readynumber)")
    //          todoarray.append(todocontent)
            timearray.append(changedtime)
            try! realm.write(){
                realm.add(updatetimersetdata)
            }
        }
    }
}
