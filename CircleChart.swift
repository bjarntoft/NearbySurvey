//
//  CircleChart.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-06.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar ett "cirkeldiagram".
class CircleChart: UIView {
    let boldness = 30           // Cirkeldiagrammets "tjocklek".
    var survey: Survey?         // Enkäten.
    
    // MARK: - Drawing -
    
    // Metoden skapar grafik.
    override func drawRect(rect: CGRect) {
        // Ritar ett cirkeldiagram.
        drawCircleChart(rect)
    }
    
    // MARK: - Private Methods -
    
    // Metoden ritar ett cirkeldiagram.
    private func drawCircleChart(rect: CGRect) {
        var sum: Float = 0
        
        // Avläser antalet röster.
        if let s = survey {
            sum = Float(s.numberOfVotes)
        }
        
        // Kontrollerar antal röster.
        if sum == 0.0 {
            // Ritar ut cirkeldiagrammet som ett tomt "skal".
            let path = UIBezierPath(arcCenter: CGPoint(x: rect.width/2, y: rect.height/2), radius: (rect.height/2) - CGFloat((boldness/2)), startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 2), clockwise: true)
            path.lineWidth = CGFloat(boldness)
            Styles.Colors.gray.colorWithAlphaComponent(0.1).setStroke()
            path.stroke()
        } else {
            // Beräknar cirkeldiagrammets startpunkt (radianvärde).
            var lastEnd: Float = Float(M_PI) * Float(1.5)
            
            if let s = survey {
                // Ritar ut cirkeldiagrammet, baserat på de enskilda rösterna.
                for var i = 0; i < s.results.count; i++ {
                    // Beräknar svarsalternativets andel i det totala resultatet (procentsats).
                    let answerPart: Float = Float(s.results[i]) / sum
                    
                    // Omvandlar procentsats till en slutpunkt (radianvärde) i cirkeldiagrammet.
                    let newEnd = lastEnd + (Float(M_PI) * Float(2) * answerPart)
                    
                    // Ritar ut procentsatsen i cirkeldiagrammet.
                    let path = UIBezierPath(arcCenter: CGPoint(x: rect.width/2, y: rect.height/2), radius: (rect.height/2) - CGFloat((boldness/2)), startAngle: CGFloat(lastEnd), endAngle: CGFloat(newEnd), clockwise: true)
                    path.lineWidth = CGFloat(boldness)
                    Styles.chartColors[i].setStroke()
                    path.stroke()
                    
                    // Sparar undan aktuell slutpunkt (radianvärd) i cirekldiagrammet.
                    lastEnd = newEnd
                }
            }
        }
    }
    
}
