//
//  ViewController.swift
//  DB Deployer
//
//  Created by Shawn Roller on 4/29/19.
//  Copyright © 2019 Shawn Roller. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    let defaultDialogText = "Whatchu want sucka?!"
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var serverTableView: NSTableView!
    @IBOutlet weak var dialogLabel: NSTextView!
    @IBOutlet weak var deployButton: NSButton!
    
    var preferences = Preferences()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tableview
        self.serverTableView.delegate = self
        self.serverTableView.dataSource = self
        self.serverTableView.target = self
        
        // set defaults
        self.deployButton.isEnabled = false
        self.dialogLabel.string = self.defaultDialogText

        self.show(preferences: self.preferences)
    }
    
    func show(preferences: Preferences) {
        self.pathControl.url = URL(fileURLWithPath: preferences.defaultPath)
    }
    
    func updateDialog() {
        let selectedRow = self.serverTableView.selectedRow
        guard let url = self.pathControl.url else { return }
        let text = url.path
        
        guard selectedRow >= 0 && selectedRow < self.preferences.dbConfigs.count && text.count > 0 else {
            self.deployButton.isEnabled = false
            self.dialogLabel.string = self.defaultDialogText
            return
        }
        
        self.deployButton.isEnabled = true
        let name = self.preferences.dbConfigs[selectedRow].name
        
        self.dialogLabel.string = "I will deploy all the .sql scripts from \n\(text) \n\nto the database server \n\(name)\n\nShould I proceed?"
    }
    
    @IBAction func deployButtonClicked(_ sender: Any) {
        guard let url = self.pathControl.url else { return }
        let path = url.path
        self.deployButton.isEnabled = false
        let selectedConfig = self.preferences.dbConfigs[self.serverTableView.selectedRow]
        self.buildScript(for: selectedConfig, folder: path)
    }
    
    @IBAction func deployMenuButtonClicked(_ sender: Any) {
        self.deployButtonClicked(sender)
    }
    
    @IBAction func stopButtonClicked(_ sender: Any) {
//        if self.isRunning {
//            self.buildTask.terminate()
//        }
    }
    
}

// MARK: - Scripting
extension MainViewController {
    
    func buildScript(for config: DBConfig, folder: String) {
        let arguments = ["--login", config.name, folder, config.server, config.database, config.driver, config.trustedConnection ? "-E" : ""]
        self.runScript(arguments: arguments)
    }
    
    func runScript(arguments: [String]) {
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async {
            guard let path = Bundle.main.path(forResource: "DeployScript", ofType: "sh") else {
                print("can't find build script")
                return
            }
            
            let deployTask = Process()
            deployTask.launchPath = path
            deployTask.arguments = arguments
            deployTask.terminationHandler = {
                task in
                DispatchQueue.main.async(execute: {
                    self.deployButton.isEnabled = true
                })
            }
            
            self.captureStdOut(deployTask)
            deployTask.launch()
            deployTask.waitUntilExit()
        }
    }
    
    func captureStdOut(_ task: Process) {
        // setup output
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil, using: { (notification) in
            let output = outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            DispatchQueue.main.async(execute: {
                let previousOutput = self.dialogLabel.string
                let nextOutput = previousOutput + "\n" + outputString
                self.dialogLabel.string = nextOutput
                
                let range = NSRange(location: nextOutput.count, length: 0)
                self.dialogLabel.scrollRangeToVisible(range)
            })
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        })
    }
    
}

extension MainViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        self.updateDialog()
    }
    
}

extension MainViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.preferences.dbConfigs.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.updateDialog()
    }
    
    //    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    //        guard let sortDescriptor = tableView.sortDescriptors.first else {
    //            return
    //        }
    //
    //        if let order = Directory.FileOrder(rawValue: sortDescriptor.key!) {
    //            sortOrder = order
    //            sortAscending = sortDescriptor.ascending
    //            reloadFileList()
    //        }
    //    }
    
}

extension MainViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < self.preferences.dbConfigs.count, let columnID = tableColumn?.identifier else { return nil }
        
        let id = columnID.rawValue
        var cellTitle = ""
        let config = self.preferences.dbConfigs[row]
        
        switch id {
        case "Name":
            cellTitle = config.name
        case "Driver":
            cellTitle = config.driver
        case "Server":
            cellTitle = config.server
        case "Database":
            cellTitle = config.database
        case "Trusted":
            cellTitle = config.trustedConnection ? "Yes" : "No"
        default:
            break
        }
        
        return cellTitle
    }
    
}

