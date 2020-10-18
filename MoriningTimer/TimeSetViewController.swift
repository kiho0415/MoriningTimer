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
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    //タイマーの秒数を表示する
    var timeCountNumber: Int = 0
    var timer: Timer = Timer()
    var changedtime = String()
    var readynumber = Int()
    var todocontent = String()
    
    var orderArray: [String] = []
    var todoArray: [String] = []
    var timeArray = [Int]() 
    
    let realm = try! Realm()
    let newTimerSetData = TimerSetData()
    
    override func viewDidLoad() {
        table.register(UINib(nibName: "TimeSetCell", bundle: nil), forCellReuseIdentifier: "TimeSetCell")
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        startButton.layer.cornerRadius = 20
        stopButton.layer.cornerRadius = 20
        resetButton.layer.cornerRadius = 20
        nextButton.layer.cornerRadius = 20
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        table.rowHeight = 50 //Cellの高さを調節
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell", for: indexPath) as! TimeSetCell
        readynumber = indexPath.row + 1
        cell.contentTextField.placeholder = "準備内容を入力"
        if indexPath.row != timeArray.count{//最後以外のcell
            
        }else{//最後のcell
            cell.orderLabel.text = "準備\(readynumber)"
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
        let cell = table.cellForRow(at: IndexPath(row: readynumber - 1, section: 0)) as! TimeSetCell
        cell.timeLabel.text = String(changedtime)
    }
    
    @IBAction func start(){
        if timer.isValid{
            
        }else{
            startTimer()
        }
    }
    
    @IBAction func stop(){
        if timer.isValid{
            timer.invalidate()
        }
    }
    
    @IBAction func reset(){
        if timer.isValid {//計測中
            timer.invalidate()
            timeCountNumber =  0
        } else {//タイマー止まってるとき
            if timeArray == [] {//スタートの前にリセットを押す
                ///何もしない
            } else {//2番目以降のセル：この時は動いているセルのデータが配列に保存されていないので配列の最後を削除しなくて良い
                timeCountNumber = 0
            }
        }
        let cell = table.cellForRow(at: IndexPath(row: timeArray.count, section: 0)) as! TimeSetCell
        cell.timeLabel.text = "00:00"
        print("resetおすと\(orderArray),\(todoArray),\(timeArray)")
    }
    
    @IBAction func next(){
        if timer.isValid {//計測中に次へ
            appendarray()
            //            appendtodoarray()
            timeCountNumber =  0
        } else {//タイマー止まってるときに次へ
            if timeArray == [] {//スタートの前にリセットを押す
                ///何もしない
            } else {
                appendarray()
                //                appendtodoarray()
                timeCountNumber =  0
                startTimer()
            }
        }
        self.table.reloadData()
        print("nextおすと\(orderArray),\(todoArray),\(timeArray)")
    }
    
    
    @IBAction func save(){
        if timer.isValid{
            appendarray()
            appendtodoarray()
            timeCountNumber =  0
            timer.invalidate()
        }else{
            appendarray()
            appendtodoarray()
        }
        try! realm.write(){
            realm.deleteAll() //前回までのデータを消す
        }
        for i in 0...timeArray.count - 1 {
            let newTimerSetData = TimerSetData()
            newTimerSetData.order = orderArray[i]
            newTimerSetData.todo = todoArray[i]
            newTimerSetData.time = timeArray[i]
            try! realm.write(){
                realm.add(newTimerSetData)
            }
        }
        let alert: UIAlertController = UIAlertController(title: "", message: "保存しました", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {//アラートが消えるのと画面遷移が重ならないように0.5秒後に画面遷移
                self.navigationController?.popViewController(animated: true)
            }
        }))
        present(alert, animated: true, completion: nil)
        print("saveおすと\(orderArray),\(todoArray),\(timeArray)")
    }
    
    func appendarray(){
            orderArray.append("準備\(readynumber)")
            timeArray.append(timeCountNumber)
      
    }
    func appendtodoarray(){
        for i in 0...readynumber - 1{
            let cell = table.cellForRow(at: IndexPath(row: i, section: 0)) as! TimeSetCell
            let text = cell.contentTextField.text
            let todocontent = text
            todoArray.insert(todocontent!, at: i)
        }
    }
 
}

