//
//  Multipeer.swift
//  Nearby Survey
//
//  Created by Andreas Bjärntoft on 2015-11-19.
//  Copyright © 2015 Bjarntoft Production. All rights reserved.
//

import MultipeerConnectivity

// MARK: Delegating Protocol
protocol MCDelegate {
    func connecting(device: String)
    func connected(device: String)
    func notConnected(device: String)
    func recivedData(data: NSData)
    func hostCreated(created: Bool)
}
// MARK: -

// MARK: Global Multipeer Connectivity Variables
let mcTag = "NS-"           // Identifikation för anslutning.
enum DeviceRole {           // Fastställda roller vid anslutning.
    case host
    case client
}
// MARK: -

// Klassen representerar en anslutning via Multipeer Connectivity.
class Multipeer: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    // Delegat:
    var delegate: MCDelegate?
    
    // Anslutningsvariabler:
    private var mcRole: DeviceRole
    private var mcPeerID: MCPeerID?
    private var mcID: String
    private var hostPeer: MCPeerID?
    private(set) var mcSession: MCSession?
    private var mcServiceAdvertiser: MCNearbyServiceAdvertiser?
    private var mcBrowser: MCNearbyServiceBrowser?
    
    // Antal anslutna enheter beräknas vid förfrågan.
    var numberOfPeers: Int {
        if let s = mcSession {
            return s.connectedPeers.count
        } else {
            return 0
        }
    }
    
    // Arbetsvariabler:
    private var counter = 0
    private var timer: NSTimer?
    private var hostExcist = false
    
    // MARK: - Constructors -
    
    // Initierar Multipeer Connectivity som "host" eller "client".
    init(role: DeviceRole, peerName: Int, group: String) {
        // Sparar grundläggande variabler.
        mcRole = role
        mcID = group
        
        // Initierar superklass (för att kunna använda "self" i konstruktorn).
        super.init()
        
        // Kontrollerar enhetens roll.
        switch mcRole {
        case .host:
            // Tilldelar enheten nytt namn (samma som gruppnamnet för att möjliggöra automatisk anslutning).
            mcPeerID = MCPeerID(displayName: mcID)
            
            if let pid = mcPeerID {
                // Söker efter anslutning/grupp (för kontroll).
                mcBrowser = MCNearbyServiceBrowser(peer: pid, serviceType: mcID)
                if let b = mcBrowser {
                    b.delegate = self
                    b.startBrowsingForPeers()
                }
            }
            
            // Startar timer för kontroll om angiven undersökningsgrupp redan existerar.
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("tryToMakeHost"), userInfo: nil, repeats: true)
        case .client:
            // Tilldelar enheten nytt namn, baserat på ett slumptal samt enhetens grundnamn.
            mcPeerID = MCPeerID(displayName: String(peerName) + UIDevice.currentDevice().name)
            
            if let pid = mcPeerID {
                // Söker efter anslutning/grupp.
                mcBrowser = MCNearbyServiceBrowser(peer: pid, serviceType: mcID)
                if let b = mcBrowser {
                    b.delegate = self
                    b.startBrowsingForPeers()
                }
                
                // Initierar en session.
                mcSession = MCSession(peer: pid)
                if let s = mcSession {
                    s.delegate = self
                }
            }
        }
    }
    
    // MARK: - MCSessionDelegate -
    
    // Metoden hanterar mottagning av data.
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        // Utskrift för utvecklingsarbete i Xcode.
        print("Recived data from: \(peerID.displayName)")
        
        // Anropar delegat med mottagen data.
        if let d = delegate {
            d.recivedData(data)
        }
    }
    
    // Metoden hanterar anslutningsförändringar.
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case MCSessionState.Connected:
            // Utskrift för utvecklingsarbete i Xcode.
            print("Connected: \(peerID.displayName)")
            
            // Sparar anknytningspunkt till "host" (för riktad sändning av data).
            if mcRole == .client && peerID.displayName == mcID {
                hostPeer = peerID
            }
            
            // Anropar delegat med namn på ansluten enhet.
            if let d = delegate {
                d.connected(peerID.displayName)
            }
        case MCSessionState.Connecting:
            // Utskrift för utvecklingsarbete i Xcode.
            print("Connecting: \(peerID.displayName)")
            
            // Anropar delegat med namn på anslutande enhet.
            if let d = delegate {
                d.connecting(peerID.displayName)
            }
        case MCSessionState.NotConnected:
            // Utskrift för utvecklingsarbete i Xcode.
            print("Not Connected: \(peerID.displayName)")
            
            // Anropar delegat med namn på frånkopplad enhet.
            if let d = delegate {
                d.notConnected(peerID.displayName)
            }
        }
    }
    
    // Metoden ingår i delegeringen, men används ej.
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    // Metoden ingår i delegeringen, men används ej.
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {}
    
    // Metoden ingår i delegeringen, men används ej.
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {}
    
    // MARK: - MCNearbyServiceAdvertiserDelegate (host only) -
    
    // Metoden gör enheten upptäckbar för anslutningar (skapar grupp).
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        // Utskrift för utvecklingsarbete i Xcode.
        print("Inventation recived from: \(peerID.displayName)")
        
        if let s = mcSession {
            // Accepterar automatiskt alla anslutningsförsök.
            invitationHandler(true, s)
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate (client only) -
    
    // Metoden ingår i delegeringen, men används ej.
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {}
    
    // Metoden anropas när anslutning hittas.
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Utskrift för utvecklingsarbete i Xcode.
        print("Found: \(peerID.displayName)")
        
        // Kontrollerar om funnen anslutning matchar vald grupp.
        if peerID.displayName == mcID {
            // Kontrollerar enhetens roll.
            if mcRole == .client {
                if let s = mcSession {
                    // Begär att få ansluta.
                    browser.invitePeer(peerID, toSession: s, withContext: nil, timeout: 10)
                }
                
                // Slutar söka efter anslutningar.
                browser.stopBrowsingForPeers()
            } else {
                // Utskrift för utvecklingsarbete i Xcode.
                print("Host already exists")
                
                // Markerar att vald undersökningsgrupp redan existerar.
                hostExcist = true
                
                // Slutar söka efter anslutningar.
                browser.stopBrowsingForPeers()
                
                // Anropar delegat.
                if let d = delegate {
                    d.hostCreated(false)
                }
            }
        }
    }
    
    // Metoden ingår i delegeringen, men används ej.
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    // MARK: - Work Methods -
    
    // Metoden sänder data via Multipeer Connectivity.
    func sendData(data: NSData) -> Bool {
        // Kontrollerar antalet anslutna enheter.
        if numberOfPeers > 0 {
            // Skickar datapaketet.
            do {
                if let s = mcSession {
                    try s.sendData(data, toPeers: s.connectedPeers, withMode: .Reliable)
                    return true
                }
            } catch let error as NSError {
                print("Error sending data: \(error.localizedDescription)")
            }
        }
        
        return false
    }
    
    // Metoden sänder data till "host" via Multipeer Connectivity.
    func sendDataToHost(data: NSData) -> Bool {
        if let hp = hostPeer, let s = mcSession {
            // Kontrollerar om "host" finns tillgänglig.
            if s.connectedPeers.contains(hp) {
                // Skickar datapaketet.
                do {
                    try s.sendData(data, toPeers: [hp], withMode: .Reliable)
                    return true
                } catch let error as NSError {
                    print("Error sending data: \(error.localizedDescription)")
                }
            }
        }
        
        return false
    }
    
    // Metoden öppnar upp för återanslutning av klient.
    func reconnectClient() {
        print("Trying to reconnect device")
        if let b = mcBrowser {
            b.startBrowsingForPeers()
        }
    }
    
    // Metoden
    func tryToMakeHost() {
        // Kontrollerar förfuten tid samt om angiven undersökningsgrupp redan existerar.
        if counter > 5 && !hostExcist {
            if let t = timer {
                // Stoppar timer för kontroll av angiven undersökningsgrupp.
                t.invalidate()
            }
            
            // Slutar söka efter anslutningar.
            if let b = mcBrowser {
                b.stopBrowsingForPeers()
            }
            
            if let pid = mcPeerID {
                // Öppnar upp för ansutningar ("skapar en grupp").
                mcServiceAdvertiser = MCNearbyServiceAdvertiser(peer: pid, discoveryInfo: nil, serviceType: mcID)
                if let sa = mcServiceAdvertiser {
                    sa.delegate = self
                    sa.startAdvertisingPeer()
                }
                
                // Initierar en session.
                mcSession = MCSession(peer: pid)
                if let s = mcSession {
                    s.delegate = self
                }
                
                // Anropar delegat.
                if let d = delegate {
                    d.hostCreated(true)
                }
            }
        } else if hostExcist {
            // Stoppar timer för kontroll av angiven undersökningsgrupp.
            if let t = timer {
                t.invalidate()
            }
            
            // Slutar söka efter anslutningar.
            if let b = mcBrowser {
                b.stopBrowsingForPeers()
            }
        }
        
        counter++
    }
    
    // Metoden avslutar Multipeer Connectivity.
    func quit() {
        // Kontrollerar enhetens roll.
        switch mcRole {
        case .host:
            if let sa = mcServiceAdvertiser {
                // Avslutar möjligheten att ansluta.
                sa.stopAdvertisingPeer()
            }
        case .client:
            if let b = mcBrowser {
                // Avslutar sökning efter anslutning (grupp).
                b.stopBrowsingForPeers()
            }
        }
        
        if let s = mcSession {
            // Avslutar sessionen.
            s.disconnect()
        }
    }
    
}