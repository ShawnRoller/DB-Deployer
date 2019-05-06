//
//  ViewController.swift
//  DB Deployer
//
//  Created by Shawn Roller on 4/29/19.
//  Copyright © 2019 Shawn Roller. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    let defaultDialogText = "What do you want to deploy?"
    let deployTitle = "Deploy!"
    let stopTitle = "Cancel"
    
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var serverTableView: NSTableView!
    @IBOutlet weak var dialogLabel: NSTextView!
    @IBOutlet weak var deployButton: NSButton!
    
    var preferences = Preferences()
    var deployTask = Process()
    var isRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tableview
        self.serverTableView.delegate = self
        self.serverTableView.dataSource = self
        self.serverTableView.target = self
        
        // set defaults
        self.updateDialog()
        self.deployButton.title = self.deployTitle
        
        // setup listener in case the prefs change
        NotificationCenter.default.addObserver(self, selector: #selector(updatePrefs(_:)), name: NSNotification.Name(rawValue: Constants.prefsChanged), object: nil)

        self.show(preferences: self.preferences)
    }
    
    @objc func updatePrefs(_ sender: Any) {
        self.preferences = Preferences()
        self.serverTableView.reloadData()
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
        
        self.dialogLabel.string = "I will deploy all the .sql scripts from \n\(text) \n\nto the database server \n\(name)\n\nDo you want to deploy?"
    }
    
    @IBAction func deployButtonClicked(_ sender: Any) {
        if !self.isRunning {
            guard let url = self.pathControl.url else { return }
            
            self.deployButton.title = self.stopTitle
            self.isRunning = true
            
            let path = url.path
            let selectedConfig = self.preferences.dbConfigs[self.serverTableView.selectedRow]
            let sqlcmdPath = self.preferences.sqlPath
            self.buildScript(for: selectedConfig, folder: path, sqlcmdPath: sqlcmdPath)
        } else {
            self.stopButtonClicked(sender)
        }
    }
    
    @IBAction func deployMenuButtonClicked(_ sender: Any) {
        self.deployButtonClicked(sender)
    }
    
    func stopButtonClicked(_ sender: Any) {
        if self.isRunning {
            self.deployTask.terminate()
            self.addOutput("***** DEPLOYMENT CANCELLED *****")
        }
    }
    
    @IBAction func pathSelected(_ sender: Any) {
        self.updateDialog()
    }
    
}

// MARK: - Scripting
extension MainViewController {
    
    func buildScript(for config: DBConfig, folder: String, sqlcmdPath: String) {
        let arguments = ["--login", config.name, folder, config.server, config.database, sqlcmdPath]
        self.runScript(arguments: arguments)
    }
    
    func runScript(arguments: [String]) {
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async {
            guard let path = Bundle.main.path(forResource: "DeployScript", ofType: "sh") else {
                print("can't find build script")
                return
            }
            
            self.deployTask = Process()
            self.deployTask.launchPath = path
            self.deployTask.arguments = arguments
            self.deployTask.terminationHandler = {
                task in
                DispatchQueue.main.async(execute: {
                    self.deployButton.title = self.deployTitle
                    self.isRunning = false
                })
            }
            
            self.captureStdOut(self.deployTask)
            self.deployTask.launch()
            self.deployTask.waitUntilExit()
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
                self.addOutput(outputString)
            })
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        })
    }
    
    func addOutput(_ outputString: String) {
        let previousOutput = self.dialogLabel.string
        let nextOutput = previousOutput + "\n" + outputString
        self.dialogLabel.string = nextOutput
        
        let range = NSRange(location: nextOutput.count, length: 0)
        self.dialogLabel.scrollRangeToVisible(range)
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

extension MainViewController {
    
    func openPreferencesSheet() {
        guard let sb = self.storyboard, let vc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(stringLiteral: "PreferencesViewController")) as? PreferencesViewController else { return }
        self.presentAsSheet(vc)
    }
    
}
