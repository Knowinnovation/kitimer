//
//  InterfaceController.swift
//  BlueTime Watch Extension
//
//  Created by Drew Dunne on 6/8/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var startStopButton: WKInterfaceButton!
    @IBOutlet weak var cancelButton: WKInterfaceButton!
    @IBOutlet weak var timerLabel: WKInterfaceTimer!
    
    var displayTime: Double = 0
    var startTime: NSTimeInterval = -1
    var duration: Double = 300
    var elapsedTime: NSTimeInterval = 0
    var timer: NSTimer?
    var timerIsRunning: Bool = false
    var timerFinished: Bool = false
    var timerCancelled: Bool = true
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }
    
    override func didAppear() {
        super.didAppear()
        timerIsRunning = false
        timerCancelled = true
        timerFinished = false
        updateButtons()
        
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session!.sendMessage(["action":"initialData"], replyHandler: { (response) -> Void in
                
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
        }
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func startStopPressed() {
        if timerIsRunning {
//            duration -= NSDate.timeIntervalSinceReferenceDate() - startTime
            startStop()
            session!.sendMessage(["action":"pause", "duration":duration], replyHandler: { (response) -> Void in
                
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
        } else {
            startTime = NSDate.timeIntervalSinceReferenceDate()
            startStop()
            session!.sendMessage(["action":"start", "duration":duration, "startTime":startTime], replyHandler: { (response) -> Void in
                
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
        }
    }
    
    @IBAction func cancelPressed() {
        cancel()
        
        session!.sendMessage(["action":"cancel"], replyHandler: { (response) -> Void in
            
            }, errorHandler: { (error) -> Void in
                print(error)
        })
    }
    
    func startStop() {
        if timerIsRunning {
            timerLabel.stop()
            timer!.invalidate()
            elapsedTime += NSDate.timeIntervalSinceReferenceDate() - startTime
            let date = NSDate(timeIntervalSinceNow: duration - elapsedTime)
            timerLabel.setDate(date)
            timerIsRunning = false
            startStopButton.setTitle("Start")
        } else {
            timer = NSTimer.scheduledTimerWithTimeInterval(duration - elapsedTime, target: self, selector: #selector(InterfaceController.timeDone), userInfo: nil, repeats: false)
            let date = NSDate(timeIntervalSinceNow: duration - elapsedTime)
            timerLabel.setDate(date)
            timerLabel.start()
            timerIsRunning = true
            startStopButton.setTitle("Pause")
        }
        updateButtons()
    }
    
    func cancel() {
        timerFinished = false
        timerIsRunning = false
        timerCancelled = true
        
        timerLabel.stop()
        let date = NSDate(timeIntervalSinceReferenceDate: NSDate.timeIntervalSinceReferenceDate()+duration)
        timerLabel.setDate(date)
        
        elapsedTime = 0
        
        updateButtons()
    }
    
    func timeDone() {
        
    }
    
    
    // Upon timer completion, this runs
    func finishTimer() {
        timerFinished = true
        timerIsRunning = false
        timerCancelled = false
        
        updateButtons()
    }
    
    func updateButtons() {
        if timerIsRunning && !timerCancelled && !timerFinished {
            cancelButton.setEnabled(false)
            startStopButton.setEnabled(true)
            startStopButton.setTitle("Pause")
        } else if timerCancelled && !timerIsRunning && !timerFinished {
            cancelButton.setEnabled(false)
            startStopButton.setEnabled(true)
            startStopButton.setTitle("Start")
        } else if timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.setEnabled(true)
            startStopButton.setEnabled(false)
            startStopButton.setTitle("Start")
        } else if !timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.setEnabled(true)
            startStopButton.setEnabled(true)
            startStopButton.setTitle("Start")
        }
    }

}

extension InterfaceController: WCSessionDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        switch message["action"] as! String {
        case "start":
            self.startTime = message["startTime"] as! NSTimeInterval
            self.duration = message["duration"] as! Double
            self.startStop()
        case "pause":
            self.duration = message["duration"] as! Double
            self.startStop()
        case "cancel":
            self.cancel()
        case "selectDuration":
            if timerCancelled {
                duration = message["duration"] as! Double
            }
        case "dataDump":
            self.startTime = message["startTime"] as! NSTimeInterval
            self.duration = message["duration"] as! Double
            self.displayTime = message["displayTime"] as! Double
            self.timerCancelled = message["timerCancelled"] as! Bool
            self.timerFinished = message["timerFinished"] as! Bool
            self.timerIsRunning = false
            
            let running = message["timerIsRunning"] as! Bool
            if running {
                self.startStop()
            }
            
            self.updateButtons()
        default:
            break
        }
    }
}
