//
//  ViewController.swift
//  AminChat
//
//  Created by Amin Benarieb on 03/05/16.
//  Copyright © 2016 Amin Benarieb. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSStreamDelegate, UITableViewDelegate, UITableViewDataSource {

    let cellIdentifier = "ChatCellIdentifier"
    
    @IBOutlet var joinView: UIView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var button: UIButton!
    var connectedToServer = false
    
    @IBOutlet var chatView: UIView!
    @IBOutlet var chatTextField: UITextField!
    @IBOutlet var chatTableView: UITableView!
    var messages = [String()]
    
    var inputStream : NSInputStream?
    var outputStream : NSOutputStream?
    
    //MARK: View events
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        for textfield in [textField, chatTextField]
        {
            textfield.leftView = UIView(frame: CGRectMake(0,0,20,1))
            textfield.leftViewMode = .Always
        }
        
        chatTableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentifier)
        chatTableView.allowsSelection = false
        
        let tap = UITapGestureRecognizer(target: self, action: "hideKeyboard:")
        self.view.addGestureRecognizer(tap)

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        toggleButton(connectedToServer)
    }
    

    //MARK: Server connection workflow
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        
        if motion == .MotionShake && !connectedToServer {
            establishConnection()
        }
        
    }
    func establishConnection(){
        
        var readStream : Unmanaged<CFReadStream>?
        var writeStream : Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, "localhost" as CFStringRef, 82, &readStream, &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream!.delegate = self
        outputStream!.delegate = self
        
        inputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        inputStream!.open()
        outputStream!.open()
        
    }
    func messageReceived(msg : String){
        messages.append(msg)
        chatTableView.reloadData()
        
        let topIndexPath = NSIndexPath(forRow: messages.count-1, inSection: 0)
        chatTableView.scrollToRowAtIndexPath(topIndexPath, atScrollPosition: .Middle, animated: true)
    }
    
    //MARK: Actions
    
    @IBAction func jointToServer(sender: AnyObject) {
        
        if textField.text != ""
        {
            let response = NSString(format: "iam:%@", textField.text!)
            let data = NSData(data: response.dataUsingEncoding(NSASCIIStringEncoding)!)
            outputStream!.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
            view.bringSubviewToFront(chatView)
        }
        else
        {
            showMessage("Enter your username!")
        }
        
        
        
    }
    @IBAction func sendToServer(sender: AnyObject) {
        
        if (chatTextField.text != "")
        {
            let response = NSString(format: "msg:%@", chatTextField.text!)
            let data = NSData(data: response.dataUsingEncoding(NSASCIIStringEncoding)!)
            outputStream!.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        }
        // error handling
        
        // cleaning up the message field when the message has been sent.
        chatTextField.text = ""
        hideKeyboard(chatTextField)
    }
    @IBAction func hideKeyboard(sender: AnyObject) {
        
        self.view.endEditing(true)
        
    }
    
    //MARK: TableView delegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return messages.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = messages[indexPath.row]
        
        return cell
        
    }
    
    //MARK : Stream delegate
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {

        switch (eventCode) {
            
            case (NSStreamEvent.OpenCompleted):
                print("Stream opened.")
                showMessage("Connected to server");
                toggleButton(true)
                
                
            case (NSStreamEvent.HasBytesAvailable):
                print("Received a message from server.")
                if let stream = aStream as? NSInputStream
                {
                    let bufferSize = 1024
                    var buffer = Array<UInt8>(count: bufferSize, repeatedValue: 0)
                    
                    
                    while (stream.hasBytesAvailable)
                    {
                        let bytesRead = stream.read(&buffer, maxLength: bufferSize)
                        if bytesRead >= 0
                        {
                            if let output = NSString(bytes: &buffer, length: bytesRead, encoding: NSASCIIStringEncoding)
                            {
                                print("message from server: \(output)");
                                messageReceived(output as String)
                            }
                        }
                    }
                }
                
            case (NSStreamEvent.HasBytesAvailable):
                print("Server has bytes available.")
                
                
            case (NSStreamEvent.ErrorOccurred):
                print("Can not connect to the host!")
                showMessage((aStream.streamError?.localizedDescription)!)
                view.bringSubviewToFront(joinView)
                aStream.close()
                aStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
                toggleButton(false)
                
                
            case (NSStreamEvent.EndEncountered):
                print("Server went down.")
                showMessage("Server went down. Sorry");
                view.bringSubviewToFront(joinView)
                aStream.close()
                aStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
                toggleButton(false)
                
            default:
                print(eventCode)
        }
        
    }
    
    //MARK : UIAlerView 
    
    func showMessage(msg : String){
        let alertview = UIAlertView(title: "Message", message: msg, delegate: self, cancelButtonTitle: "OK")
        alertview.show()
        
    }
    

    //MARK : Button enability workflow
    
    func toggleButton(on : Bool)
    {
        connectedToServer = on
        button.userInteractionEnabled = on
        button.backgroundColor = on ? UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1) : .lightGrayColor()
    }
    
    
    
}

