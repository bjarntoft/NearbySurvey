//
//  Styles.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-09.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar globala stilattribut.
class Styles {
    // Maxbredd på GUI.
    static let maxComponentWidth: CGFloat = 500
    
    // Normalt färgschema.
    struct Colors {
        static let orange = UIColor(red: 241/255, green: 103/255, blue: 69/255, alpha: 1)
        static let yellow = UIColor(red: 255/255, green: 198/255, blue: 93/255, alpha: 1)
        static let green = UIColor(red: 123/255, green: 200/255, blue: 164/255, alpha: 1)
        static let blue = UIColor(red: 76/255, green: 195/255, blue: 217/255, alpha: 1)
        static let purple = UIColor(red: 147/255, green: 100/255, blue: 141/255, alpha: 1)
        static let gray = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
    }
    
    // Ljust färgschema.
    struct LightColors {
        static let orange = UIColor(red: 248/255, green: 179/255, blue: 162/255, alpha: 1)
        static let yellow = UIColor(red: 255/255, green: 227/255, blue: 174/255, alpha: 1)
        static let green = UIColor(red: 198/255, green: 228/255, blue: 210/255, alpha: 1)
        static let blue = UIColor(red: 166/255, green: 225/255, blue: 236/255, alpha: 1)
        static let purple = UIColor(red: 201/255, green: 178/255, blue: 198/255, alpha: 1)
        static let gray = UIColor(red: 160/255, green: 160/255, blue: 160/255, alpha: 1)
    }
    
    // Diagramfärger (10 st).
    static let chartColors = [
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.purple,
        Colors.blue,
        LightColors.orange,
        LightColors.yellow,
        LightColors.green,
        LightColors.purple,
        LightColors.blue
    ]
    
}
