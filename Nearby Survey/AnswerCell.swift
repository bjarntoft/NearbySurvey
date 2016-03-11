//
//  QuestionTableViewCell.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-03.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar en cell/rad i tabellen med enkätens svarsalternativ.
class AnswerCell: UITableViewCell {
    // GUI-komponenter:
    @IBOutlet weak var rowNumberLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initierar GUI-komponenter.
        rowNumberLabel.textColor = Styles.Colors.gray.colorWithAlphaComponent(0.5)
        answerLabel.textColor = Styles.Colors.gray
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
