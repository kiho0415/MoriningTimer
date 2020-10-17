//
//  ColorViewController.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/16.
//

import UIKit

class ColorViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        navigationBar.barTintColor = #colorLiteral(red: 0.6929637137, green: 0.8993118159, blue: 1, alpha: 1)  //背景色
        navigationBar.barStyle = .default //時計のとこ
        navigationBar.tintColor = .white //アイテムの色　（戻る　＜　とか　読み込みゲージとか）
        navigationBar.titleTextAttributes = [ //バーのテキスト
            // 文字の色
            .foregroundColor: UIColor.white
        ]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
