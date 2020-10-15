//
//  ViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/01.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    @IBOutlet var pretimelabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        pretimelabel.text = "前回のタイマー設定では、準備にかかる合計時間は＿分です。"
    }

    @IBAction func timerstart(){
        let alert: UIAlertController = UIAlertController(title: "", message: "前回の計測を元に準備タイマーを開始します。", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default,
                handler: { action in
                }
                )
            )
        alert.addAction(
                    UIAlertAction(
                    title: "キャンセル",
                    style: .cancel,
                    handler: { action in
                    self.navigationController?.popViewController(animated: true)
                    }
                    )
                    )
                    present(alert, animated: true, completion: nil)
                }

    @IBAction func timeset(){
        let alert: UIAlertController = UIAlertController(title: "", message: "測定を始めます。次の準備に移るときに「次の準備へ」を押してください。", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default,
                handler: { action in
                    self.dismiss(animated: true, completion: nil)
                }
            )
        )
        present(alert, animated: true, completion: nil)

    }

}

