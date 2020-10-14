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
    
    var orderArray: [String] = []
    var todoArray: [String] = []
    var timeArray = [Int]()  //時間形式に変更したのじゃないのを保存するためにint型にしてみた
    
    let realm = try! Realm()
    
    override func viewDidLoad() {
        table.register(UINib(nibName: "TimeSetCell", bundle: nil), forCellReuseIdentifier: "TimeSetCell")
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        //startButton.setTitle("開始", for: .normal)
        //cell.contenttextfield.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell", for: indexPath) as! TimeSetCell
        readynumber = indexPath.row + 1
        todocontent = cell.contentTextField.text!
        if indexPath.row != timeArray.count{//最後以外のcell
            //            cell.orderLabel.text = timedictionary.keys[indexPath.row]
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
            //            startButton.setTitle("スタート", for: .highlighted)
        }else{//タイマーを動かす
            startTimer()
            //            sender.setTitle("ストップ", for: .normal)///ボタンが切り替わらない
        }
    }
    
    @IBAction func reset(){
        if timer.isValid {//計測中
            timer.invalidate()
            timeCountNumber =  0
            ///ここでタイマーの数字変わるようにしたい
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
            todoArray.append(todocontent)
            timeArray.append(timeCountNumber)
            timeCountNumber =  0
        } else {//タイマー止まってるときに次へ
            if timeArray == [] {//スタートの前にリセットを押す
                ///何もしない
            } else {
                orderArray.append("準備\(readynumber)")
                todoArray.append(todocontent)
                timeArray.append(timeCountNumber)
                timeCountNumber =  0
                startTimer()
            }
        }
        self.table.reloadData()
        print("nextおすと\(orderArray),\(todoArray),\(timeArray)")
    }
    
    
    @IBAction func save(){
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
        print("saveおすと\(orderArray),\(todoArray),\(timeArray)")
        
        ///リストを使うことになったらここを復活させる
        //        let updatetimersetdata = TimerSetData()
        
        ///今からこれをfor文を使って繰り返し処理に変えていきます
        
        //        newTimerSetData.order = orderArray[0]
        //        newTimerSetData.todo = todoArray[0]
        //        newTimerSetData.time = timeArray[0]
       
        
        if todoArray.count != orderArray.count && orderArray.count != 0{
            let alert: UIAlertController = UIAlertController(title: "", message: "準備の内容を登録してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in})
            )
            present(alert, animated: true, completion: nil)
        } else {
            for i in 0...timeArray.count - 1 {
                let newTimerSetData = TimerSetData()
                newTimerSetData.order = orderArray[i]
                newTimerSetData.todo = todoArray[i]
                newTimerSetData.time = timeArray[i]
                try! realm.write(){
                    realm.add(newTimerSetData)
                }
            }
            ///リストを使うことになったらここを復活させる
            //                updatetimersetdata.order.removeAll() //TimeSetDataのtag=List<Tag>を全部消す
            //                updatetimersetdata.todo.removeAll()
            //                updatetimersetdata.time.removeAll()
            //                updatetimersetdata.order.append(objectsIn: orderarray)
            //                updatetimersetdata.time.append(objectsIn: timearray)
            //                updatetimersetdata.todo.append(objectsIn: todoarray)
            //                realm.add(updatetimersetdata)
            //                print(updatetimersetdata)
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

