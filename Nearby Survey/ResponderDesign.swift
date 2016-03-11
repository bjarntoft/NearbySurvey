//
//  ResponderDesign.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-11.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar ett designobjekt i "frågeformulärtet".
class ResponderDesign: UIView {
    private let x = 25
    private let y = 25

    // MARK: - Drawing -
    
    // Metoden skapar grafik.
    override func drawRect(rect: CGRect) {
        // Ritar en cirkel (som delvis döljs).
        let circle = UIBezierPath(ovalInRect: CGRectMake(CGFloat(-x), rect.height - CGFloat(y), rect.width + CGFloat(2*x), CGFloat(2*y)))
        Styles.Colors.green.setFill()
        circle.fill()
    }
    
}