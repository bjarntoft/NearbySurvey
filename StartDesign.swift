//
//  Start.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-09.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar ett designobjekt på "startsidan".
class StartDesign: UIView {
    private let x = 75
    private let y = 100
    
    // MARK: - Drawing -
    
    // Metoden skapar grafik.
    override func drawRect(rect: CGRect) {
        // Ritar en cirkel (som delvis döljs).
        let circle = UIBezierPath(ovalInRect: CGRectMake(CGFloat(-x), rect.height - CGFloat(y/2), rect.width + CGFloat(x*2), CGFloat(y*2)))
        Styles.Colors.yellow.setFill()
        circle.fill()
    }
    
}