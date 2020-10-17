//
//  TimeSetCell.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/05.
//

import UIKit

class TimeSetCell: UITableViewCell,UITextFieldDelegate {
    @IBOutlet var orderLabel: UILabel!
    @IBOutlet var contentTextField: UITextField!
    @IBOutlet var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
    }
    
}
