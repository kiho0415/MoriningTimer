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
    var timecountnumber: Int = 0
    var timer: Timer = Timer()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeSetCell") as? TimeSetCell
        return cell!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.dataSource = self
        //cell.contenttextfield.delegate = self
    }
    
 
    
    @IBAction func stop(){
        
    }

    @IBAction func reset(){
        
    }
    
    @IBAction func next(){
        
    }
}
