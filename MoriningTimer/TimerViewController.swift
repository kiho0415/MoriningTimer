//
//  TimerViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/02.
//

import UIKit
import RealmSwift

class TimerViewController: UIViewController,UITableViewDataSource {
    
    @IBOutlet var table: UITableView!
    @IBOutlet var readyContentLabel: UILabel!
    @IBOutlet var tillEndMinuteLabel: UILabel!
    @IBOutlet var tillEndSecondLabel: UILabel!
    @IBOutlet var tillArriveMinuteLabel: UILabel!
    @IBOutlet var tillArriveSecondLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        table.dataSource = self
        // print(Realm.Configuration.defaultConfiguration.fileURL)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimerCell") as? TimerCell
        return cell!
    }
    
    @IBAction func stop(){
        
    }
    
}
