//
//  AnswerViewController.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-10-29.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// MARK: - Delegating Protocol
protocol QuestionDelegate {
    func questionRecived()
}
// MARK: -

// Klassen representerar en "enkätfråga".
class ResponderViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MCDelegate {
    // Arbetsobjekt:
    var multipeer: Multipeer?       // Anslutning.
    var survey: Survey?             // Enkät.
    
    // Delegat:
    var delegate: QuestionDelegate?
    
    // Anslutningsvariabler:
    var deviceNumber = 0
    var groupID: String?
    
    // Enkätvariabler:
    var responderAnswer = 0
    var answerSent = false
    
    // Tabellvariabler:
    var cellData = [String]()
    
    // Laddningskomponenter:
    let loadingPopup = UIView()
    let loadingActivityIndicator = UIActivityIndicatorView()
    let loadingStatus = UILabel()
    
    // GUI-komponenter:
    @IBOutlet weak var surveyGroupLabel: UILabel!
    @IBOutlet weak var questionTitleLabel: UILabel!
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var answersTitleLabel: UILabel!
    @IBOutlet weak var answersTableView: UITableView!
    @IBOutlet weak var showResultButton: UIButton!
    @IBOutlet weak var sendAnswerButton: UIButton!
    
    // Placering av GUI-komponenter:
    @IBOutlet weak var questionTitleLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var questionTextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var answersTitleLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var answersTableViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var answersTableViewHeightConstraint: NSLayoutConstraint!

    // MARK: - View Lifecycle
    
    
    // Metoden hanterar aktuell vy.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initierar Multipeer Connectivity.
        loadMultipeerConnectivity()
        
        // Initierar navigering.
        loadNavigationControllerGui()
        
        // Initierar tabell.
        loadTableView()
        
        // Initierar GUI.
        loadGui()
    }

    // Metoden hanterar händelser när aktuell vy synliggjorts.
    override func viewDidAppear(animated: Bool) {
        // Kontrollerar om enkät mottagits sedan tidigare.
        guard (survey != nil) else {
            // Visar indikator för anslutning och mottagning av fråga.
            showLoadingPopup()
            return
        }
    }

    // MARK: - User Interaction

    // Händelsefunktionen skickar respondentens enkätsvar.
    @IBAction func sendAnswer(sender: UIButton) {
        // Lägger svaret i ett datapaket.
        let data = NSData(bytes: &responderAnswer, length: sizeofValue(responderAnswer))
        
        if let m = multipeer {
            // Skickar svaret.
            if m.sendDataToHost(data) {
                answerSent = true
                
                // Uppdaterar GUI.
                answersTableView.allowsSelection = false
                updateSendAnswerButton()
            }
        }
    }

    // Händelsemetoden avslutar Multipeer Connectivity och återvänder till "startsidan".
    @IBAction func exit() {
        // Raderar befintlig enkät.
        survey = nil
        
        // Stänger ner anslutningen
        if let m = multipeer {
            m.quit()
        }
        
        // Raderar anslutningen.
        multipeer = nil
        
        // Återvänder till "startstidan".
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Segues

    // Metoden hanterar förflyttning till andra vyer.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Kontrollerar förflyttningen.
        if segue.identifier == "toResponderResult" {
            // Skapar en "brygga" till destinationsvyn.
            if let vc = segue.destinationViewController as? ResponderResultViewController {
                // Överför variabler.
                vc.responderViewController = self
                
                // Överför enkät.
                if let s = self.survey {
                    vc.survey = s
                }
            }
        }
    }

    // MARK: - Private Methods

    // Metoden upprättar anslutning via Multipeer Connectivity.
    private func loadMultipeerConnectivity() {
        // Skapar en anslutning.
        if let gid = groupID {
            multipeer = Multipeer(role: DeviceRole.client, peerName: deviceNumber, group: gid)
        }
        
        // Delegerar hanteringen av anslutningen till sig själv.
        if let m = multipeer {
            m.delegate = self
        }
    }

    // Metoden initierar navigering mellan vyer.
    private func loadNavigationControllerGui() {
        if let nc = navigationController {
            nc.navigationBar.barTintColor = UIColor.whiteColor()
            nc.navigationBar.translucent = false
            nc.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
            nc.navigationBar.shadowImage = UIImage()
            nc.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: Styles.Colors.gray]
            nc.navigationBar.tintColor = Styles.Colors.green
        }
    }

    // Metoden initierar en tabell med svarsalternativ.
    private func loadTableView() {
        // Laddar in mall för celler/rader i tabellen.
        let cellNib = UINib(nibName: "AnswerCell", bundle: NSBundle.mainBundle())
        answersTableView.registerNib(cellNib, forCellReuseIdentifier: "cell")
        
        // Delegerar hantering av tabellen till sig själv.
        answersTableView.delegate = self
        answersTableView.dataSource = self
    }

    // Metoden laddar in samtliga gui-komponenter och dess design/format.
    private func loadGui() {
        // Vy:
        self.view.backgroundColor = Styles.Colors.green
        
        // Anslutning:
        surveyGroupLabel.textColor = Styles.Colors.gray
        
        // Enkät:
        questionTitleLabel.textColor = Styles.Colors.gray
        questionTitleLabel.hidden = true
        
        questionTextView.textColor = Styles.Colors.gray
        questionTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        questionTextView.layer.cornerRadius = 5
        questionTextView.hidden = true
        
        answersTitleLabel.textColor  = Styles.Colors.gray
        answersTitleLabel.hidden = true
        
        answersTableView.tableFooterView = UIView()
        answersTableView.layer.cornerRadius = 5
        answersTableView.hidden = true
        
        showResultButton.layer.backgroundColor = UIColor.whiteColor().CGColor
        showResultButton.layer.cornerRadius = 5
        showResultButton.tintColor = Styles.Colors.green
        showResultButton.hidden = true
        
        sendAnswerButton.layer.cornerRadius = 5
        sendAnswerButton.hidden = true
        
        // Placering:
        questionTitleLabelWidthConstraint.constant = Styles.maxComponentWidth
        
        questionTextViewWidthConstraint.constant = Styles.maxComponentWidth
        
        answersTitleLabelWidthConstraint.constant = Styles.maxComponentWidth
        
        answersTableViewWidthConstraint.constant = Styles.maxComponentWidth
    }

    // Metoden visar en laddningsindikator.
    private func showLoadingPopup() {
        // Skapar en behållare för en laddningsindikator.
        if let nc = navigationController {
            loadingPopup.frame = nc.view.bounds
            loadingPopup.center = CGPointMake(nc.view.bounds.width / 2, (nc.view.bounds.height / 2) - (nc.navigationBar.bounds.height / 2))
        }
        
        // Skapar laddningsindikatorn.
        let loadingView: UIView = UIView()
        loadingView.frame = CGRectMake(0, 0, 200, 110)
        loadingView.center = loadingPopup.center
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        // Skapar grafisk indikator.
        loadingActivityIndicator.center = CGPointMake(loadingView.frame.size.width / 2, 40);
        loadingActivityIndicator.activityIndicatorViewStyle = .WhiteLarge
        loadingActivityIndicator.startAnimating()
        
        // Skapar indikatorstatus.
        loadingStatus.frame = CGRectMake(0, 0, loadingView.frame.size.width, 21)
        loadingStatus.center = CGPointMake(loadingView.frame.size.width / 2, 80)
        loadingStatus.textAlignment = NSTextAlignment.Center
        loadingStatus.textColor = UIColor.whiteColor()
        loadingStatus.font = UIFont(name: loadingStatus.font.fontName, size: 12)
        loadingStatus.text = "Ansluter till undersökningsgrupp..."
        
        // Laddar in komponenter.
        loadingView.addSubview(loadingActivityIndicator)
        loadingView.addSubview(loadingStatus)
        
        // Visar laddningsindikator.
        loadingPopup.addSubview(loadingView)
        self.view.addSubview(loadingPopup)
        
        // Animerar fram laddningsindikator.
        loadingPopup.alpha = 0
        UIView.animateWithDuration(0.3, animations: {
            self.loadingPopup.alpha = 1
        })
    }

    // Metoden uppdaterar formatet på den knapp som möjliggör att ett svar kan skickas.
    private func updateSendAnswerButton() {
        if let m = multipeer {
            // Kontrollerar textfält för enkätfråga, antal svarsalternativ, antal anslutna enheter samt enkätens status.
            if m.numberOfPeers > 0 && responderAnswer > 0 && !answerSent {
                sendAnswerButton.enabled = true
                sendAnswerButton.setTitle("Skicka svar", forState: .Normal)
                sendAnswerButton.layer.backgroundColor = UIColor.whiteColor().CGColor
                sendAnswerButton.tintColor = Styles.Colors.green
            } else if answerSent {
                sendAnswerButton.enabled = false
                sendAnswerButton.setTitle("Svar skickat", forState: .Normal)
                sendAnswerButton.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor
                sendAnswerButton.tintColor = UIColor.whiteColor()
            } else {
                sendAnswerButton.enabled = false
                sendAnswerButton.setTitle("Skicka svar", forState: .Normal)
                sendAnswerButton.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor
                sendAnswerButton.tintColor = UIColor.whiteColor()
            }
        }
    }

    // MARK: - MCDelegate

    // Metoden ingår i delegeringen, men används ej.
    func connecting(device: String) {}
    
    
    // Metoden påkallas när anslutning sker via Multipeer Connectivity.
    func connected(device: String) {
        // Uppdaterar GUI från huvudtråden.
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            self.loadingStatus.text = "Inväntar fråga..."
            
            if let gid = self.groupID {
                self.surveyGroupLabel.text = "Undersökningsgrupp: " + gid.substringFromIndex(gid.startIndex.advancedBy(mcTag.characters.count))
            }
            })
    }

    // Metoden anropas när en anslutning bryts via Multipeer Connectivity.
    func notConnected(device: String) {
        // Uppdaterar GUI från huvudtråden.
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            self.loadingStatus.text = "Anslutning misslyckades"
            self.loadingActivityIndicator.stopAnimating()
            self.surveyGroupLabel.text = "Undersökningsgrupp: -"
            })
        
        // Öppnar upp för återanslutning.
        if let m = multipeer {
            m.reconnectClient()
        }
    }

    // Metoden anropas när data mottas via Multipeer Connectivity.
    func recivedData(data: NSData) {
        // Säkerställer inkommet dataobjekt.
        if let recivedSurvey = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Survey {
            // Kontrollerar om en befintlig enkät saknas.
            guard let s = survey else {
                // Laddar in enkät.
                survey = recivedSurvey
                cellData = recivedSurvey.answers
                
                // Uppdaterar GUI från huvudtråden.
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    UIView.animateWithDuration(0.3, animations: {self.loadingPopup.alpha = 0}, completion: { finished in self.loadingPopup.removeFromSuperview()})
                    
                    self.questionTitleLabel.hidden = false
                    self.questionTextView.hidden = false
                    self.answersTitleLabel.hidden = false
                    self.answersTableView.hidden = false
                    self.sendAnswerButton.hidden = false
                    
                    if let ss = self.survey {
                        self.questionTextView.text = ss.question
                    }
                    self.answersTableView.reloadData()
                    self.answersTableView.allowsSelection = true
                    
                    self.showResultButton.hidden = true
                    
                    self.updateSendAnswerButton()
                }
                
                return
            }
            
            // Jämför befintlig enkät med mottagen enkät.
            if s.ID != recivedSurvey.ID {
                // Laddar in enkät.
                survey = recivedSurvey
                cellData = recivedSurvey.answers
                responderAnswer = 0
                answerSent = false
                
                // Uppdaterar GUI från huvudtråden.
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.questionTextView.text = recivedSurvey.question
                    self.answersTableView.reloadData()

                    self.updateSendAnswerButton()
                    
                    self.answersTableView.allowsSelection = true
                    
                    self.showResultButton.hidden = true
                }
            }
            
            // Markerar att svar inte är sänt.
            answerSent = false
            
            // Meddelar delegat att en enkät har mottagits.
            if let d = delegate {
                d.questionRecived()
            }
        } else if let recivedResult = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Int] {
            // Kontrollerar om respondenten själv besvarat frågan.
            if answerSent {
                // Laddar in enkätresultat.
                if let s = survey {
                    s.results = recivedResult
                    
                    // Uppdaterar GUI från huvudtråden.
                    dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                        self.showResultButton.hidden = false
                        
                        self.updateSendAnswerButton()
                    }
                }
            } else {
                // Uppdaterar GUI från huvudtråden.
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.sendAnswerButton.enabled = false
                    self.sendAnswerButton.setTitle("Fråga stängd", forState: .Normal)
                    
                    self.answersTableView.allowsSelection = false
                }
            }
        }
    }
    
    // Metoden ingår i delegeringen, men används ej.
    func hostCreated(created: Bool) {}
    
    // MARK: - UITableViewDataSource

    // Metoden justerar tabellens höjd och returnerar antal celler/rader i tabellen.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Beräknar antalet celler/rader i tabellen.
        let numberOfRows = cellData.count
        
        // Identifierar vilken cell/rad som används.
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            let cellHeight = cell.bounds.height
            
            // Beräknar och uppdaterar tabellens höjd baserat på antal celler.
            answersTableViewHeightConstraint.constant = CGFloat(numberOfRows) * cellHeight
        }
        
        return numberOfRows
    }

    // Metoden konstruerar och returnerar en cell/rad i tabellen.
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Kontrollerar mall för cellen/raden.
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as? AnswerCell {
            // Uppdaterar cellens/radens innehåll.
            cell.rowNumberLabel.text = "\(indexPath.row + 1)."
            cell.answerLabel.text = cellData[indexPath.row]
            
            return cell
        } else {
            // Skapar en standardcell/-rad.
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
            
            // Uppdaterar cellen/raden.
            if let c = cell.textLabel {
                c.text = "\(indexPath.row + 1). " + cellData[indexPath.row]
            }
            
            return cell
        }
    }

    // MARK: - UITableViewDelegate

    // Metoden hanterar när en cell/rad markeras.
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        responderAnswer = indexPath.row + 1
        
        // Färgmarkerar cellen.
        if let c = tableView.cellForRowAtIndexPath(indexPath) {
            c.contentView.backgroundColor = Styles.LightColors.green
        }
        
        // Uppdaterar GUI-komponenter.
        updateSendAnswerButton()
    }

    // Metoden hanterar när en cell/rad inte längre är markerad.
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        // Färgmarkerar cellen.
        if let c = tableView.cellForRowAtIndexPath(indexPath) {
            c.contentView.backgroundColor = UIColor.clearColor()
        }
    }

}
