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
    @IBOutlet var tillEndLabel: UILabel!
    @IBOutlet var tillArriveLabel: UILabel!
    
    let realm = try! Realm()

    var timer:Timer = Timer()
    var timeCountNumber: Int = 0
//    var orderarray: [String] = []
    var todoarray: [String] = []
    var timearray = [Int]()  //時間ように変更したのじゃないのを保存するためにint型にしてみた
    
    let timerSetDataArray = realm.objects(TimerSetData.self)
    let orderList = List<String>() //List型
    var orderarray = Array<Any>() // Array型
//    let orderarray.append(contentsOf: Array(orderList)) // Array()でListを変換
    let orderarray = Array<Any>()

    override func viewDidLoad() {
        table.register(UINib(nibName: "TimerCell", bundle: nil), forCellReuseIdentifier: "TimerCell")
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        timersetdata = realm.objects(TimerSetData.self)
        
        // print(Realm.Configuration.defaultConfiguration.fileURL)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimerCell") as? TimerCell
        return cell!
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
    
    @objc func count(){ ///これはコピペしただけだから変える
        timeCountNumber = timeCountNumber + 1
        let second = timeCountNumber % 60
        let minute = (timeCountNumber - second) / 60
//        changedtime = String(format: "%02d:%02d", minute,second)
        self.table.reloadData()
    }
    
    @IBAction func stop(){
        
    }
    
}
