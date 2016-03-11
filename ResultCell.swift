//
//  ResultTableViewCell.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-06.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar en cell/rad i tabellen med enkätens resultat.
class ResultCell: UITableViewCell {
    // GUI-komponenter:
    @IBOutlet weak var chartColorLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initierar GUI-komponenter.
        answerLabel.textColor = Styles.Colors.gray
        percentLabel.textColor = Styles.Colors.gray
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
