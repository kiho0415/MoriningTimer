//
//  TimerCell.swift
//  MoriningTimer
//
//  Created by 森田貴帆 on 2020/10/11.
//

import UIKit

class TimerCell: UITableViewCell {
    @IBOutlet var nextnumberlabel: UILabel!
    @IBOutlet var nexttimelabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
