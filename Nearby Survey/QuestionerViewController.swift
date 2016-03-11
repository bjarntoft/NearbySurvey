//
//  QuestionViewController.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-10-29.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit

// MARK: Delegating Protocol
protocol ResultDelegate {
    func addAnswer()
}
// MARK: -

// Klassen representerar ett "enkätverktyg".
class QuestionerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, MCDelegate {
    // Arbetsobjekt:
    var multipeer: Multipeer?       // Anslutning.
    var survey: Survey?             // Enkät.
    
    // Delegat:
    var delegate: ResultDelegate?
    
    // Anslutningsvariabler:
    var deviceNumber = 0
    var groupID: String?
    
    // Enkätvariabler:
    var responders = Set<String>()
    var questionExists = false
    var surveySent = false
    
    // Tabellvariabler:
    var cellData = [String]()
    
    // GUI-komponenter:
    @IBOutlet weak var surveyGroupLabel: UILabel!
    @IBOutlet weak var numberOfRespondersLabel: UILabel!
    @IBOutlet weak var questionTitleLabel: UILabel!
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var answersTitleLabel: UILabel!
    @IBOutlet weak var answersTableView: UITableView!
    @IBOutlet weak var addAnswerButton: UIButton!
    @IBOutlet weak var sendSurveyButton: UIButton!
    @IBOutlet weak var newQuestionButton: UIButton!
    
    // Placering av GUI-komponenter:
    @IBOutlet weak var questionTitleLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var questionTextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var answerTitleLabelCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var answersTableViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var answerTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addAnswerButtonCenterConstraint: NSLayoutConstraint!
    
    // MARK: - View Lifecycle
    
    // Metoden hanterar aktuell vy.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initierar Multipeer Connectivity.
        loadMultipeerConnectivity()
        
        // Initierar navigering.
        loadNavigation()
        
        // Initierar tabell.
        loadTableView()
        
        // Initierar GUI.
        loadGui()
        
        // Delegerar hantering av textfällt till sig själv.
        questionTextView.delegate = self
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // Initierar Multipeer Connectivity.
        //loadMultipeerConnectivity()
    }
    
    // MARK: - User Interaction
    
    // Metoden anropas vid tryck på skärmen, i det här fallet göms eventuellt tangentbordet.
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Händelsemetoden lägger till ett svarsalternativ via en popup.
    @IBAction func addAnswer(sender: UIButton) {
        // Initierar en popup.
        let addAnswerPrompt = UIAlertController(title: "Lägg till", message: "Ett svarsalternativ till frågan", preferredStyle: .Alert)
        
        // Initierar ett textfält (i popup).
        var inputTextField = UITextField()
        inputTextField.autocapitalizationType = .Sentences
        
        // Initierar knappar (i popup).
        let cancelButton = UIAlertAction(title: "Avbryt", style: .Cancel) { (action) -> Void in }
        let saveButton = UIAlertAction(title: "Spara", style: .Default, handler: { (action) -> Void in
            // Adderar svarsalternativ till listan över samtliga svarsalternativ.
            if let t = inputTextField.text {
                self.cellData.append(t)
            }
            
            // Uppdaterar GUI från huvudtråden.
            dispatch_async(dispatch_get_main_queue(), { [unowned self] in
                // Uppdaterar tabellen.
                self.answersTableView.reloadData()
                
                // Kontrollerar möjligheten att lägga till fler svarsalternativ (begränsas av antalet tillgängliga färger).
                if self.cellData.count >= Styles.chartColors.count {
                    self.addAnswerButton.enabled = false
                }
                
                // Döljer tangentbordet.
                self.view.endEditing(true)
                })
        })
        
        // Konstruerar popup.
        addAnswerPrompt.addTextFieldWithConfigurationHandler { (textField) -> Void in
            inputTextField = textField
        }
        addAnswerPrompt.addAction(cancelButton)
        addAnswerPrompt.addAction(saveButton)
        
        // Presenterar popup.
        presentViewController(addAnswerPrompt, animated: true, completion: nil)
    }
    
    // Händelsemetoden skickar enkäten till anslutna respondenter.
    @IBAction func sendSurvey(sender: UIButton) {
        // Skapar enkäten.
        survey = Survey(question: questionTextView.text, answers: cellData)
        
        if let s = survey, let m = multipeer, let ms = m.mcSession {
            // Kapslar in enkäten i ett datapaket (NSData).
            let mcObject = NSKeyedArchiver.archivedDataWithRootObject(s)
            
            // Skickar enkäten.
            if m.sendData(mcObject) {
                // Registrerar vilka respondenter som enkäten skickats till.
                for devices in ms.connectedPeers {
                    responders.insert(devices.displayName)
                }
                
                // Låser enkäten för editering.
                closeSurvey(true)
                
                // Förflyttar användaren till vyn för enkätresultat.
                performSegueWithIdentifier("toResult", sender: sender)
            }
        }
    }
    
    // Händelsefunktionen raderar befintlig enkät och skapar ett tomt enkätformulär.
    @IBAction func newQuestion(sender: UIButton) {
        // Initierar en popup för att uppmärksamma  användaren på att befintlig enkät kommer att raderas.
        let addQuestionPrompt = UIAlertController(title: "Skapa en ny fråga", message: "Om du väljer att skapa en ny fråga kommer den befintliga frågan och dess resultat att raderas!", preferredStyle: .ActionSheet)
        
        // Initierar knappar (i popup).
        let cancelButton = UIAlertAction(title: "Avbryt", style: .Cancel) { (action) -> Void in }
        let okButton = UIAlertAction(title: "OK", style: .Destructive, handler: { (action) -> Void in
            // Nollställer listan med svarsalternativ.
            self.cellData.removeAll()
            
            // Nollställer lista över respondenter som mottagit enkäten.
            self.responders.removeAll()
            
            // Låser upp enkätformuläret.
            self.closeSurvey(false)
            
            // Låser upp mottagning av svar.
            if let s = self.survey {
                s.resultClosed = false
            }
            
            // Uppdaterar GUI från huvudtråden.
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Nollställer frågan.
                self.questionTextView.text = ""
                
                // Uppdaterar tabellen.
                self.answersTableView.reloadData()
            })
        })
        
        // Konstruerar popup.
        addQuestionPrompt.addAction(cancelButton)
        addQuestionPrompt.addAction(okButton)
        
        // Presenterar popup.
        presentViewController(addQuestionPrompt, animated: true, completion: nil)
    }
    
    // Händelsemetoden avslutar Multipeer Connectivity och återvänder till "startsidan".
    @IBAction func exit() {
        // Raderar befintlig enkät.
        survey = nil
        
        // Stänger ner anslutningen.
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
        if segue.identifier == "toResult" {
            // Skapar en "brygga" till destinationsvyn.
            if let vc = segue.destinationViewController as? ResultViewController {
                // Överför variabler.
                vc.questionViewController = self
                
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
        if let gid = groupID {
            // Upprättar en anslutning.
            multipeer = Multipeer(role: DeviceRole.host, peerName: deviceNumber, group: gid)
        }
        
        // Delegerar hanteringen av anslutningen till sig själv.
        if let m = multipeer {
            m.delegate = self
        }
    }
    
    // Metoden initierar navigering mellan vyer.
    private func loadNavigation() {
        if let nc = navigationController {
            nc.navigationBar.barTintColor = UIColor.whiteColor()
            nc.navigationBar.translucent = false
            nc.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
            nc.navigationBar.shadowImage = UIImage()
            nc.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: Styles.Colors.gray]
            nc.navigationBar.tintColor = Styles.Colors.blue
        }
        
        // Inaktiverar navigationsknapp till enkätresultat.
        if let rbb = navigationItem.rightBarButtonItem {
            rbb.enabled = false
        }
    }
    
    // Metoden initierar tabell med svarsalternativ.
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
        self.view.backgroundColor = Styles.Colors.blue
        
        // Anslutning:
        surveyGroupLabel.textColor = Styles.Colors.gray
        surveyGroupLabel.text = "Skapar undersökningsgrupp..."
        
        numberOfRespondersLabel.textColor = Styles.Colors.gray
        numberOfRespondersLabel.text = ""
        
        // Enkät:
        questionTitleLabel.textColor = Styles.Colors.gray
        
        questionTextView.textColor = Styles.Colors.gray
        questionTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        questionTextView.layer.cornerRadius = 5
        
        answersTitleLabel.textColor = Styles.Colors.gray
        
        answersTableView.tableFooterView = UIView()
        answersTableView.layer.cornerRadius = 5
        
        addAnswerButton.tintColor = UIColor.whiteColor()
        
        sendSurveyButton.layer.cornerRadius = 5
        sendSurveyButton.tintColor = Styles.Colors.blue
        
        newQuestionButton.layer.backgroundColor = UIColor.whiteColor().CGColor
        newQuestionButton.layer.cornerRadius = 5
        newQuestionButton.tintColor = Styles.Colors.blue
        newQuestionButton.hidden = true
        
        // Placering:
        questionTitleLabelWidthConstraint.constant = Styles.maxComponentWidth
        
        questionTextViewWidthConstraint.constant = Styles.maxComponentWidth
        
        answerTitleLabelCenterConstraint.constant = -(Styles.maxComponentWidth/2) + answersTitleLabel.bounds.width/2
        
        answersTableViewWidthConstraint.constant = Styles.maxComponentWidth
        
        addAnswerButtonCenterConstraint.constant = Styles.maxComponentWidth/2 - addAnswerButton.bounds.width/2
    }
    
    // Metoden uppdaterar formatet på den knapp som möjliggör att enkäten kan skickas.
    private func updateSendSurveyButton() {
        if let m = multipeer {
            // Kontrollerar textfält för enkätfråga, antal svarsalternativ, antal anslutna enheter samt enkätens status.
            if questionExists && cellData.count >= 2 && m.numberOfPeers >= 1 && !surveySent {
                sendSurveyButton.enabled = true
                sendSurveyButton.setTitle("Skicka fråga", forState: .Normal)
                sendSurveyButton.layer.backgroundColor = UIColor.whiteColor().CGColor
                sendSurveyButton.tintColor = Styles.Colors.blue
            } else if surveySent {
                sendSurveyButton.enabled = false
                sendSurveyButton.setTitle("Fråga skickad", forState: .Normal)
                sendSurveyButton.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor
                sendSurveyButton.tintColor = UIColor.whiteColor()
            } else {
                sendSurveyButton.enabled = false
                sendSurveyButton.setTitle("Skicka fråga", forState: .Normal)
                sendSurveyButton.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor
                sendSurveyButton.tintColor = UIColor.whiteColor()
            }
        }
    }
    
    // Metoden öppnar upp eller låser enkäten för ändringar.
    private func closeSurvey(closed: Bool) {
        // Justerar möjligheterna att ändra enkätens fråga och svarsalternativ.
        questionTextView.editable = !closed
        addAnswerButton.enabled = !closed
        
        // Justerar formatet på den knapp som möjliggör navigering till enkätens resultat.
        if let rbb = navigationItem.rightBarButtonItem {
            rbb.enabled = closed
        }
        
        // Justerar enkätens status.
        surveySent = closed
        newQuestionButton.hidden = !closed
        
        // Uppdaterar GUI-komponenter.
        updateSendSurveyButton()
    }
    
    // MARK: - MCDelegate
    
    // Metoden ingår i delegeringen, men används ej.
    func connecting(device: String) {}
    
    // Metoden anropas när en anslutning sker via Multipeer Connectivity.
    func connected(device: String) {
        // Uppdaterar GUI från huvudtråden.
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if let m = self.multipeer {
                self.numberOfRespondersLabel.text = "Anslutna respondenter: \(m.numberOfPeers) st"
            }
            
            self.updateSendSurveyButton()
            })
        
        if let s = survey {
            // Kontrollerar om enkäten redan är skickad till respondenten samt att enkäten inte är låst för nya röster.
            if surveySent && !s.resultClosed && !responders.contains(device) {
                // Kapslar in enkäten i ett datapaket (NSData).
                let mcObject = NSKeyedArchiver.archivedDataWithRootObject(s)
                
                if let m = multipeer {
                    // Skickar enkäten till respondenten.
                    if m.sendData(mcObject) {
                        // Registrerar att enkäten skickats till respondenten.
                        responders.insert(device)
                    }
                }
            }
        }
    }
    
    // Metoden anropas när en anslutning bryts via Multipeer Connectivity.
    func notConnected(device: String) {
        // Uppdaterar GUI från huvudtråden.
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if let m = self.multipeer {
                self.numberOfRespondersLabel.text = "Anslutna respondenter: \(m.numberOfPeers) st"
            }
            
            self.updateSendSurveyButton()
            })
    }
    
    // Metoden anropas när data mottas via Multipeer Connectivity.
    func recivedData(data: NSData) {
        // Kontrollerar om enkäten är öppen för svar.
        if let s = survey where !s.resultClosed {
            // Sparar mottagen data.
            var answer = 0;
            data.getBytes(&answer, length: sizeof(Int))
            
            if let s = survey, let d = delegate {
                // Registrerar respondentens röst.
                s.addVote(answer)
                
                // Anropar delegat.
                d.addAnswer()
            }
        }
    }
    
    // Metoden anropas när undersökningsgruppen inte är möjlig att skapa (pga. att en undersökningsgrupp med samma namn redan finns).
    func errorHost() {
        // Uppdaterar GUI från huvudtråden.
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            // Initierar en popup som uppmärksammar att undersökningsgruppen redan finns.
            let hostErrorPrompt = UIAlertController(title: "Misslyckat försök att skapa undersökningsgrupp", message: "Vald unsersökningsgrupp används redan. Var god välj ett annat namn på undersökningsgruppen.", preferredStyle: .ActionSheet)
            
            // Initierar knappar (i popup).
            let okButton = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                // Återvänder till "startstidan".
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            
            // Konstruerar popup.
            hostErrorPrompt.addAction(okButton)
            
            // Presenterar popup.
            self.presentViewController(hostErrorPrompt, animated: true, completion: nil)
        }
    }
    
    func hostCreated(created: Bool) {
        if created {
            // Uppdaterar GUI från huvudtråden.
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                if let gid = self.groupID, let m = self.multipeer {
                    self.surveyGroupLabel.text = "Undersökningsgrupp: " + gid.substringFromIndex(gid.startIndex.advancedBy(mcTag.characters.count))
                    self.numberOfRespondersLabel.text = "Anslutna respondenter: \(m.numberOfPeers) st"
                }
            }
        } else {
            // Uppdaterar GUI från huvudtråden.
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                // Initierar en popup som uppmärksammar att undersökningsgruppen redan finns.
                let hostErrorPrompt = UIAlertController(title: "Misslyckat försök att skapa undersökningsgrupp", message: "Undersökningsgruppen finns redan. Var god välj ett annat namn på undersökningsgruppen.", preferredStyle: .ActionSheet)
                
                // Initierar knappar (i popup).
                let okButton = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    // Återvänder till "startstidan".
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
                
                // Konstruerar popup.
                hostErrorPrompt.addAction(okButton)
                
                // Presenterar popup.
                self.presentViewController(hostErrorPrompt, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UITextViewDelegate
    
    // Metoden hanterar egenskaper i ett textfällt, i det här fallet kontrollerar dess innehåll.
    func textViewDidChange(textView: UITextView) {
        // Kontrollerar vilket textfällt som är aktivt.
        if textView == questionTextView {
            // Kontrollerar om textfältet för enkätfrågan innehåller någon text.
            if textView.text.characters.count != 0 {
                questionExists = true
            } else {
                questionExists = false
            }
            
            // Uppdaterar GUI-komponenter.
            updateSendSurveyButton()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    // Metoden justerar tabellens höjd och returnerar antal celler/rader i tabellen.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Beräknar antalet celler/rader i tabellen.
        let numberOfRows = cellData.count
        
        // Identifierar vilken cell/rad som används.
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            let cellHeight = cell.bounds.height
            
            // Kontrollerar antalet svarsalternativ och anpassar tabellens höjd utifrån detta.
            if numberOfRows >= 2 {
                answerTableViewHeightConstraint.constant = CGFloat(numberOfRows) * cellHeight
            } else {
                answerTableViewHeightConstraint.constant = cellHeight
            }
        }
        
        // Uppdaterar övriga GUI-komponenter.
        updateSendSurveyButton()
        
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
    
    // Metoden bestämmer om en cell/rad i tabellen är ändringsbar, i det här fallet möjlig att radera.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return !surveySent
    }
    
    // Metoden hanterar en cells/rads egenskaper, i det här fallet möjliggör borttagning av en cell/rad i tabellen.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Kontrollerar aktuell egenskap.
        if editingStyle == .Delete {
            // Tar bort svarsalternativet från listan.
            cellData.removeAtIndex(indexPath.row)
            
            // Tar bort celler/raden från tabellen.
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            // Laddar om tabellen (för att uppdatera radnummer).
            tableView.reloadData()
            
            // Kontrollerar möjligheten att lägga till fler svarsalternativ (begränsas av antalet tillgängliga färger).
            if cellData.count < Styles.chartColors.count {
                addAnswerButton.enabled = true
            }
        }
    }
    
}
