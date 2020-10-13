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

    override func viewDidLoad() {
        table.register(UINib(nibName: "TimerCell", bundle: nil), forCellReuseIdentifier: "TimerCell")
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        
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
