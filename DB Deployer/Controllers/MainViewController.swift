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
    let maxTFCharacters = 10000
    
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var serverTableView: NSTableView!
    @IBOutlet var dialogLabel: NSTextView!
    @IBOutlet weak var deployButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var preferences = Preferences()
    var deployTask = Process()
    var isRunning = false {
        didSet {
            if self.isRunning {
                self.progressIndicator.startAnimation(nil)
                self.progressIndicator.isHidden = false
            } else {
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
            }
        }
    }
    var outputObserver: Any? = nil
    var prefsObserver: Any? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tableview
        self.serverTableView.delegate = self
        self.serverTableView.dataSource = self
        self.serverTableView.target = self
        
        // set defaults
        self.updateDialog()
        self.deployButton.title = self.deployTitle
        self.progressIndicator.stopAnimation(nil)
        self.isRunning = false
        
        // configure folder selection
        self.pathControl.pathStyle = .popUp
        self.pathControl.allowedTypes = ["public.folder"]
        
        // setup listener in case the prefs change
        self.prefsObserver = NotificationCenter.default.addObserver(self, selector: #selector(updatePrefs(_:)), name: NSNotification.Name(rawValue: Constants.prefsChanged), object: nil)

        self.show(preferences: self.preferences)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        if let observer = self.prefsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        
        // Update default path
        self.updateDefaultPath(newPath: text)
        
        guard selectedRow >= 0 && selectedRow < self.preferences.dbConfigs.count && text.count > 0 else {
            self.deployButton.isEnabled = false
            self.dialogLabel.string = self.defaultDialogText
            return
        }
        
        self.deployButton.isEnabled = true
        let name = self.preferences.dbConfigs[selectedRow].name
        
        self.dialogLabel.string = "I will deploy all the .sql scripts from \n\(text) \n\nto the database server \n\(name)\n\nDo you want to deploy?"
    }
    
    func updateDefaultPath(newPath: String) {
        self.preferences.defaultPath = newPath
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.prefsChanged), object: nil)
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
        var isDebug = false
        
        #if DEBUG
            isDebug = true
        #endif
        
        let arguments = ["--login", config.name, folder, config.server, config.database, sqlcmdPath, "\(isDebug)"]
        self.runScript(arguments: arguments)
    }
    
    func runScript(arguments: [String]) {
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
        taskQueue.async {
            guard let path = Bundle.main.path(forResource: "DeployScript", ofType: "sh") else {
                print("can't find build script")
                return
            }
            
            self.deployTask = Process.init()
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
            DispatchQueue.global().async {
                self.deployTask.waitUntilExit()
            }
        }
    }
    
    func captureStdOut(_ task: Process) {
        // setup output
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        // remove any existing observers before adding a new one
        if let observer = self.outputObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        self.outputObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil, using: { (notification) in
            let output = outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            DispatchQueue.main.async(execute: {
                self.addOutput(outputString)
            })
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        })
    }
    
    func addOutput(_ outputString: String) {
        guard let textStorage = self.dialogLabel.textStorage else { return }
        if textStorage.length > self.maxTFCharacters {
            self.truncateOutput()
        }
        let outputWithReturn = "\n\(outputString)"
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: NSRange(location: textStorage.length, length: 0), with: outputWithReturn)
        textStorage.endEditing()
        let range = NSRange(location: textStorage.length, length: 0)
        self.dialogLabel.scrollRangeToVisible(range)
    }
    
    func truncateOutput() {
        guard let textStorage = self.dialogLabel.textStorage, textStorage.length > self.maxTFCharacters else { return }
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: NSRange(location: 0, length: self.maxTFCharacters), with: "")
        textStorage.endEditing()
        let range = NSRange(location: textStorage.length, length: 0)
        self.dialogLabel.scrollRangeToVisible(range)
    }
    
}

extension MainViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        guard let object = obj.object as? NSTextField else { return }
        if object.stringValue.count > self.maxTFCharacters {
            // limit the text output characters so we don't lock up the app
            self.truncateOutput()
        }
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
        case "Server":
            cellTitle = config.server
        case "Database":
            cellTitle = config.database
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
