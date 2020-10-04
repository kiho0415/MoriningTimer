//
//  TimeSetViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/02.
//

import UIKit

class TimeSetViewController: UIViewController,UITableViewDataSource{
    
    @IBOutlet var table: UITableView!
    //タイマーの秒数を表示する
    var timeCountNumber: Int = 0
    var timer: Timer = Timer()
   // var startTime = Date()
    var timearray = [String]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timearray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell") as? TimeSetCell
        cell?.numberLabel?.text = "準備\(indexPath.row)"
        return cell!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.dataSource = self
        startTimer()
        //cell.contenttextfield.delegate = self
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
        //とりあえず1秒ずつカウント
        timeCountNumber = timeCountNumber + 1
        print(timeCountNumber)
        let second = timeCountNumber % 60
        let minute = (timeCountNumber - second) / 60
        print(String(format: "%02d:%02d.", minute,second))
    }
    
    @IBAction func stop(){
        if timer.isValid{
            timer.invalidate()
            //これだとうまくできないcell.minuteLabel.text = "00"
        }
    }

    @IBAction func reset(){
        if timer.isValid{
            timer.invalidate()
            timeCountNumber =  0
        }
    }
    
    @IBAction func next(){
        //tableview一つ下に
        //配列に中身を追加
        timearray.append("")
    }
}
