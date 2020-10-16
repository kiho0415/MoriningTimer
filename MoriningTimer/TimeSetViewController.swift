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
    var timeArray = [Int]()  //時間形式に変更したのじゃないのを保存するためにint型にしてみた
    
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

        //cell.contenttextfield.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        table.rowHeight = 55 //Cellの高さを調節
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell", for: indexPath) as! TimeSetCell
        readynumber = indexPath.row
        todocontent = cell.contentTextField.text!
        cell.contentTextField.placeholder = "準備内容";
        if indexPath.row != timeArray.count{//最後以外のcell
            
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
        self.table.reloadData()
        print("resetおすと\(orderArray),\(todoArray),\(timeArray)")
    }
    
    @IBAction func next(){
        if timer.isValid {//計測中に次へ
            orderArray.append("準備\(readynumber)")
//            todoArray.append(todocontent)
            timeArray.append(timeCountNumber)
            timeCountNumber =  0
        } else {//タイマー止まってるときに次へ
            if timeArray == [] {//スタートの前にリセットを押す
                ///何もしない
            } else {
                orderArray.append("準備\(readynumber)")
//                todoArray.append(todocontent)
                timeArray.append(timeCountNumber)
                timeCountNumber =  0
                startTimer()
            }
        }
        self.table.reloadData()
        print("nextおすと\(orderArray),\(todoArray),\(timeArray)")
    }
    
    
    @IBAction func save(){
        print("saveおすと\(orderArray),\(todoArray),\(timeArray)")

        if todoArray.count != orderArray.count && orderArray.count != 0{
            if timer.isValid{
                timer.invalidate()
            }
            let alert: UIAlertController = UIAlertController(title: "", message: "準備の内容を登録してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
            present(alert, animated: true, completion: nil)
        } else {
            if timer.isValid{
                orderArray.append("準備\(readynumber)")
                todoArray.append(todocontent)
                timeArray.append(timeCountNumber)
                timeCountNumber =  0
                timer.invalidate()
            }else{
                orderArray.append("準備\(readynumber)")
                todoArray.append(todocontent)
                timeArray.append(timeCountNumber)
            }
            //前回までのデータを消す
            try! realm.write(){
                realm.deleteAll()
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
            //アラートを表示
            let alert: UIAlertController = UIAlertController(title: "", message: "保存しました", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
                //アラートが消えるのと画面遷移が重ならないように0.5秒後に画面遷移するようにしてる
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 0.5秒後に実行したい処理
                    self.navigationController?.popViewController(animated: true)
                }
            }))
            //アラートの表示
            present(alert, animated: true, completion: nil)
        }
    }
}

