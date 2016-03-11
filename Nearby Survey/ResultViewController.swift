//
//  ResultViewController.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-10-30.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// Klassen representerar ett "enkätresultat" för frågeställaren.
class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ResultDelegate {
    // Arbetsobjekt:
    var questionViewController: QuestionerViewController?   // Föräldrarvy.
    var survey: Survey?                                     // Enkät.
    
    // GUI-komponenter:
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var chartView: CircleChart!
    @IBOutlet weak var numberOfVotesLabel: UILabel!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var shareResultButton: UIButton!
    
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
        if let qvc = questionViewController {
            qvc.delegate = self
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
        chartView.survey = survey
        
        // Positionerar GUI-komponenter.
        positioningGui()
    }

    // MARK: - User Interaction

    // Händelsemetoden skickar enkätresultatet till anslutna respondenter.
    @IBAction func sendResult(sender: UIButton) {
        // Initierar en popup som uppmärksammar att enkäten kommer att låsas.
        let shareResultPrompt = UIAlertController(title: "Dela resultatet", message: "Om du väljer att dela resultatet med respondenterna kommer frågan att stängas, vilket innebär att inga fler svar kommer att tas emot.", preferredStyle: .ActionSheet)
        
        // Initierar knappar (i popup).
        let cancelButton = UIAlertAction(title: "Avbryt", style: .Cancel) { (action) -> Void in }
        let shareButton = UIAlertAction(title: "Dela", style: .Destructive, handler: { (action) -> Void in
            if let s = self.survey, let qvc = self.questionViewController {
                // Kapslar in enkätresultatet i ett datapaket (NSData).
                let mcObject = NSKeyedArchiver.archivedDataWithRootObject(s.results)
                
                if let m = qvc.multipeer {
                    // Skickar enkätresultatet.
                    if m.sendData(mcObject) {
                        // Låser enkäten för mottagning av fler röster.
                        s.resultClosed = true
                        
                        // Uppdaterar GUI från huvudtråden.
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.shareResultButton.setTitle("Resultat delat", forState: .Normal)
                            self.shareResultButton.enabled = false
                        })
                    }
                }
            }
        })
        
        // Konstruerar popup.
        shareResultPrompt.addAction(cancelButton)
        shareResultPrompt.addAction(shareButton)
        
        // Presenterar popup.
        presentViewController(shareResultPrompt, animated: true, completion: nil)
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

    // Metoden laddar in samtliga gui-komponenter.
    private func loadGui() {
        // Vy:
        self.view.backgroundColor = Styles.Colors.blue
        
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
        
        // Delningsknapp:
        shareResultButton.tintColor = UIColor.whiteColor()
        if let s = survey where s.resultClosed {
            shareResultButton.setTitle("Resultat delat", forState: .Normal)
            shareResultButton.enabled = false
        } else {
            shareResultButton.setTitle("Dela resultat", forState: .Normal)
            shareResultButton.enabled = true
        }
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

    // MARK: - ResultDelegate

    // Metoden påkallas när en ny röst tas emot.
    func addAnswer() {
        // Uppdaterar GUI från huvudtråden.
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            self.chartView.setNeedsDisplay()                                    // Diagram.
            
            if let s = self.survey {
                self.numberOfVotesLabel.text = "\(s.numberOfVotes)"             // Svarsräknare.
            }
            
            self.resultsTableView.reloadData()                                  // Svarsalternativ.
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
                
                // Hämtar svarsalternativet.
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
