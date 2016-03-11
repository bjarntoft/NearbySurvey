//
//  StartViewController.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-10-29.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import UIKit
import CoreBluetooth

// Klassen representerar en "startsida".
class StartViewController: UIViewController, UITextFieldDelegate, CBPeripheralManagerDelegate {
    let deviceNumber = Int(arc4random_uniform(10000)+1)                                     // Slumptal för delvis identifikation av enhet.
    let maxCharacters = 15                                                                  // Maximal längd på undersäkningsgruppens namn.
    let validCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"  // Godkända tecken i undersökningsgruppens namn.
    
    // Bluetoothvariabler:
    var bluetoothPeripheralManager: CBPeripheralManager?
    
    // Arbetsvariabler:
    var viewMoveDistance: CGFloat = 0
    
    // GUI-komponenter:
    @IBOutlet weak var btStatusLabel: UILabel!
    @IBOutlet weak var surveyGroupLabel: UILabel!
    @IBOutlet weak var surveyGroupTextField: UITextField!
    @IBOutlet weak var questionerButton: UIButton!
    @IBOutlet weak var responderButton: UIButton!
    
    // MARK: - View Lifecycle
    
    // Metoden hanterar aktuell vy.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initierar GUI.
        loadGui()
        
        // Delegerar hantering av textfällt till sig själv.
        surveyGroupTextField.delegate = self
        
        // Ansluter händelseobserverare för när tangentbordet visas.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        // Initierar bluetooth-avkänning.
        bluetoothPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)

        
    }
    
    // MARK: - User Interaction
    
    // Metoden anropas vid tryck på skärmen, i det här fallet göms eventuellt tangentbordet.
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Metoden anropas när tangentbordet visas.
    func keyboardWillShow(notification: NSNotification) {
        // Säkerställer tangentbordets storlek.
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            // Kontrollerar vilket textfält som är aktivt.
            if surveyGroupTextField.isFirstResponder() {
                // Flyttar hela vyn uppåt.
                moveViewUp(surveyGroupTextField, keyboardHeight: keyboardSize.height)
            }
        }
    }
    
    // Metoden anropas när tangentbordet döljs.
    func keyboardWillHide(notification: NSNotification) {
        // Flyttar tillbaka vyn till sitt ursprungsläge.
        moveViewDown()
    }

    // MARK: - Segues

    // Metoden hanterar förflyttning till andra vyer.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var group: String
        
        // Avkodar ifyllt värde för "undersökningsgrupp".
        if let text = surveyGroupTextField.text where text != "" {
            group = mcTag + text.lowercaseString
        } else {
            group = mcTag + "generell"
        }
        
        // Kontrollerar förflyttning.
        if segue.identifier == "beQuestioner" {
            // Säkerställer förflyttning till Navigation Controller.
            if let nc = segue.destinationViewController as? UINavigationController {
                // Skapar en "brygga" till destinationsvyn.
                if let vc = nc.viewControllers.first as? QuestionerViewController {
                    // Överför variabler.
                    vc.deviceNumber = self.deviceNumber
                    vc.groupID = group
                }
            }
        } else if segue.identifier == "beResponder" {
            // Säkerställer förflyttning till Navigation Controller.
            if let nc = segue.destinationViewController as? UINavigationController {
                // Skapar en "brygga" till destinationsvyn.
                if let vc = nc.viewControllers.first as? ResponderViewController {
                    // Överför variabler.
                    vc.deviceNumber = self.deviceNumber
                    vc.groupID = group
                }
            }
        }
    }

    // MARK: - Private Methods

    // Metoden laddar in samtliga gui-komponenter och dess design/format.
    private func loadGui() {
        // Vy:
        self.view.backgroundColor = Styles.Colors.yellow
        
        // Bluetooth:
        btStatusLabel.textColor = Styles.LightColors.gray
        
        // Undersökningsgrupp:
        surveyGroupLabel.textColor = Styles.Colors.gray
        surveyGroupTextField.backgroundColor = UIColor.whiteColor()
        surveyGroupTextField.layer.borderColor = Styles.LightColors.yellow.CGColor
        surveyGroupTextField.layer.borderWidth = 1
        surveyGroupTextField.layer.cornerRadius = 5
        surveyGroupTextField.textColor = Styles.Colors.gray
        
        // "Fråga"-knapp:
        questionerButton.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        questionerButton.layer.cornerRadius = 5
        questionerButton.tintColor = Styles.LightColors.gray
        
        // "Svara"-knapp:
        responderButton.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        responderButton.layer.cornerRadius = 5
        responderButton.tintColor = Styles.LightColors.gray
    }

    // Metoden förflyttar vyn uppåt för att undvika att textfältet skyms av tangentbordet.
    private func moveViewUp(textField: UITextField, keyboardHeight: CGFloat) {
        // Beräknar vyns storlek.
        let viewRect = self.view.convertRect(self.view.bounds, fromView: self.view)
        
        // Beräknar textfältets nederkant (y-position).
        let textFieldButtom = textField.frame.origin.y + textField.frame.size.height
        
        // Beräknar tangentbordets överkant (y-position) inkl. marginal.
        let keyboardTop = viewRect.size.height - keyboardHeight - 20
        
        // Kontrollerar om textfältet döljs av tangentbordet.
        if (textFieldButtom >= keyboardTop) {
            // Beräknar hur långt vyn behöver förflyttas (inkl. marginal).
            viewMoveDistance = textFieldButtom - keyboardTop
            
            // Beräknar vyns nya position.
            var viewFrame = self.view.frame
            viewFrame.origin.y -= viewMoveDistance
            
            // Animerar vyns förflyttning.
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.setAnimationDuration(NSTimeInterval(0.3))
            self.view.frame = viewFrame
            UIView.commitAnimations()
        } else {
            viewMoveDistance = 0
        }
    }

    // Metoden förflyttar vyn tillbaka till sitt ursprungsläge.
    private func moveViewDown() {
        // Kontrollerar om vyn har föflyttats från sitt ursprungsläge.
        if viewMoveDistance != 0 {
            // Beräknar vyns ursprungliga position.
            var viewFrame: CGRect = self.view.frame
            viewFrame.origin.y += viewMoveDistance
            
            // Animerar vyns förflyttning.
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.setAnimationDuration(NSTimeInterval(0.3))
            self.view.frame = viewFrame
            UIView.commitAnimations()
        }
    }

    // MARK: - UITextFieldDelegate

    // Metoden hanterar egenskaper i ett textfällt, i det här fallet vilka tecken som skrivs in samt hur lång inskriven text är.
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Kontrollerar vilket textfällt som är aktivt.
        if textField == surveyGroupTextField {
            // Definierar godkända tecken.
            let charSet = NSCharacterSet(charactersInString: validCharacters).invertedSet
            
            // Kontrollerar inmatat tecken.
            if string.rangeOfCharacterFromSet(charSet) != nil {
                return false
            }
            
            // Säkerställer om textfältet innehåller någon text.
            guard let text = textField.text else {
                return true
            }
            
            // Beräknar textens längd.
            let length = text.characters.count + mcTag.characters.count - range.length
            
            return length < maxCharacters
        } else {
            return true
        }
    }

    // Metoden anropas vid tryck på "return" på tangentbordet, i det här fallet göms tangentbordet.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    // Metoden identifierar status för enhetens bluetooth.
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        // Kontrollerar status på bluetooth (av/på).
        switch peripheral.state {
        case .PoweredOff:
            // Uppdaterar GUI.
            btStatusLabel.text = "Bluetooth är inte aktiverat på din enhet, vilket krävs för att Nearby Survey ska fungera optimalt."
            
            responderButton.enabled = false
            questionerButton.enabled = false
        case .PoweredOn:
            // Uppdaterar GUI.
            btStatusLabel.text = ""
            
            responderButton.enabled = true
            questionerButton.enabled = true
        default:
            break
        }
    }

}
