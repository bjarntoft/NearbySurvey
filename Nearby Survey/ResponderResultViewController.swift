//
//  ResponderResultViewController.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-12-02.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar ett "enkätresultat" för respondenten.
class ResponderResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, QuestionDelegate {
    // Arbetsobjekt.
    var responderViewController: ResponderViewController?   // Föräldrarvy.
    var survey: Survey?                                     // Enkät.
    
    // GUI-komponenter:
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var chartView: CircleChart!
    @IBOutlet weak var numberOfVotesLabel: UILabel!
    @IBOutlet weak var resultsTableView: UITableView!
    
    // Placering av GUI-komponenter:
    @IBOutlet weak var questionTextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var questionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var chartViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var resultsTableViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var resultsTableViewHeightConstraint: NSLayoutConstraint!

    // MARK: - View Lifecycle

    // Metoden hanterar aktuell vy.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegerar hanteringen av resultatet till sig själv.
        if let rvc = responderViewController {
            rvc.delegate = self
        }
        
        // Initierar tabell.
        loadTableView()
        
        // Initierar GUI.
        loadGui()
        
        // Laddar in enkätfråga.
        if let s = survey {
            questionTextView.text = s.question
        }
        
        // Överför enkät till diagramet.
        chartView.survey = self.survey
        
        // Positionerar GUI-komponenter.
        positioningGui()
    }

    // MARK: - Private Methods

    // Metoden initierar en tabell med svarsalternativ (resultat).
    private func loadTableView() {
        // Laddar in mall för celler/rader i tabellen.
        let cellNib = UINib(nibName: "ResultCell", bundle: NSBundle.mainBundle())
        resultsTableView.registerNib(cellNib, forCellReuseIdentifier: "cell")
        
        // Delegerar hantering av tabellen till sig själv.
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
    }

    // Metoden laddar in samtliga gui-komponenter och dess design/format.
    private func loadGui() {
        // Vy:
        self.view.backgroundColor = Styles.Colors.green
        
        // Enkätfråga:
        questionTextView.textColor = Styles.Colors.gray
        questionTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // Diagram:
        numberOfVotesLabel.textColor = Styles.Colors.gray.colorWithAlphaComponent(0.5)
        
        if let s = survey {
            numberOfVotesLabel.text = "\(s.numberOfVotes)"
        }
        
        // Svarsalternativ:
        resultsTableView.tableFooterView = UIView()
        resultsTableView.layer.cornerRadius = 5
    }

    // Metoden positionerar GUI-komponenterna.
    private func positioningGui() {
        // Enkätfrågans utrymme (y-led):
        let size = questionTextView.sizeThatFits(CGSizeMake(self.questionTextView.frame.size.width, CGFloat(MAXFLOAT)))
        if size.height <= CGFloat(65) {
            self.questionTextViewHeightConstraint.constant = size.height
        } else {
            self.questionTextViewHeightConstraint.constant = 65
        }
        
        // Enkätfrågans utrymme (x-led):
        questionTextViewWidthConstraint.constant = Styles.maxComponentWidth
        
        // Diagrammets utrymme:
        let screenHeight = UIScreen.mainScreen().bounds.height
        chartViewHeightConstraint.constant = screenHeight * 0.25
        
        // Resultatets utrymme:
        resultsTableViewWidthConstraint.constant = Styles.maxComponentWidth
    }

    // MARK: - QuestionDelegate

    // Metoden påkallas när respondenten tar emot en enkät.
    func questionRecived() {
        // Kontrollerar om vyn är aktiv.
        if self.view.isDescendantOfView(UIApplication.sharedApplication().keyWindow!) {
            // Uppdaterar GUI från huvudtråden.
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                // Initierar en popup för att uppmärksamma respondenten på att en ny enkätfråga har mottagits.
                let shareResultPrompt = UIAlertController(title: "Ny fråga", message: "En ny fråga har tagits emot. Gå tillbaka till \"Svara\" för att besvara denna.", preferredStyle: .ActionSheet)
                
                // Initierar knappar (i popup).
                let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
                
                // Konstruerar popup.
                shareResultPrompt.addAction(okButton)
                
                // Presenterar popup.
                self.presentViewController(shareResultPrompt, animated: true, completion: nil)
            }
        }
    }

    // MARK: - UITableViewDataSource

    // Metoden justerar tabellens höjd och returnerar antal celler/rader i tabellen.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Beräknar antalet rader.
        var numberOfRows = 0
        if let s = survey {
            numberOfRows = s.answers.count
        }
        
        // Uppdaterar tabellens höjd.
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            let cellHeight = cell.bounds.height
            resultsTableViewHeightConstraint.constant = CGFloat(numberOfRows) * cellHeight
        }
        
        return numberOfRows
    }

    // Metoden konstruerar och returnerar en cell/rad i tabellen.
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Kontrollerar mall för cellen/raden.
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as? ResultCell {
            // Uppdaterar svarsalternativets färg.
            cell.chartColorLabel.backgroundColor = Styles.chartColors[indexPath.row]
            
            if let s = survey {
                // Beräknar svarsalternativets procentsats.
                let votes = s.numberOfVotes
                if votes > 0 {
                    cell.percentLabel.text = String(format: "%.0f", arguments: [Double(s.results[indexPath.row]) / Double(votes) * 100]) + "%"
                } else {
                    cell.percentLabel.text = "0%"
                }
                
                // Hämtar svarsalternativ.
                cell.answerLabel.text = s.answers[indexPath.row]
            }
            
            return cell
        } else {
            // Skapar en standardcell/-rad.
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
            
            // Uppdaterar cellen/raden.
            if let c = cell.textLabel, let s = survey {
                c.text = s.answers[indexPath.row]
                c.tintColor = Styles.chartColors[indexPath.row]
            }
            
            return cell
        }
    }
 
}
