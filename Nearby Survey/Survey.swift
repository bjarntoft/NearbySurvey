//
//  Survey.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-05.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import Foundation

// Klassen representerar en enkät.
class Survey: NSObject, NSCoding {
    // Enkätvariabler:
    var ID: Int
    var question: String
    var answers: [String]
    var results: [Int]
    var resultClosed = false
    
    // Antal registrerade röster beräknas vid förfrågan.
    var numberOfVotes: Int {
        return results.reduce(0, combine: +)
    }
    
    // MARK: - Constructors
    
    // Konstruktorn initierar en enkät.
    init(question: String, answers: [String]) {
        self.ID = 0
        self.question = question
        self.answers = answers
        results = [Int](count: answers.count, repeatedValue: 0)
        
        // Initierar superklass (för att kunna använda "self" i konstruktorn).
        super.init()
        
        // Bestämmer ett specifikt ID (för identifiering).
        self.ID = idStamp()
    }
    
    // MARK: - Private Methods
    
    // Metoden genererar ett id-nummer.
    private func idStamp() -> Int {
        // Skapar en tidsstämpling.
        let timeStamp = NSDate()
        let timeComponents = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second, .Nanosecond], fromDate: timeStamp)
        let timeStampString = "\(timeComponents.hour)\(timeComponents.minute)\(timeComponents.second)\(timeComponents.nanosecond)"
        
        // Kontrollerar tidsstämpel och returnerar ett id.
        if let intValue = Int(timeStampString) {
            return intValue                                 // Id i form av en tidsstämpel (hhmmssns).
        } else {
            return Int(arc4random_uniform(1000000)+1)       // Id i form av ett slumptal (bör inte inträffa).
        }
    }
    
    // MARK: - Work Methods
    
    // Metoden lägger till en röst i resultatet.
    func addVote(vote: Int) {
        // Kontrollerar röstens giltighet.
        if vote <= results.count {
            results[vote-1] = results[vote-1] + 1
        }
    }
    
    // MARK: - NSCoding
    
    // Metoden "packar upp" från ett NSData-objekt, för att möjliggöra mottagande via Multipeer Connectivity.
    required init(coder aDecoder: NSCoder) {
        self.ID = aDecoder.decodeObjectForKey("ID") as! Int
        self.question = aDecoder.decodeObjectForKey("question") as! String
        self.answers = aDecoder.decodeObjectForKey("answers") as! [String]
        self.results = aDecoder.decodeObjectForKey("results") as! [Int]
    }
    
    // Metoden "packar ihop" till ett NSData-objekt, för att möjliggöra skickande via Multipeer Connectivity.
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(ID, forKey: "ID")
        aCoder.encodeObject(question, forKey: "question")
        aCoder.encodeObject(answers, forKey: "answers")
        aCoder.encodeObject(results, forKey: "results")
    }
    
}