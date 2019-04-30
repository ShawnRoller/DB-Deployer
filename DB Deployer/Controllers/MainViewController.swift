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
    @IBOutlet weak var pathTextField: NSTextField!
    @IBOutlet weak var pathButton: NSButton!
    @IBOutlet weak var serverTableView: NSTableView!
    @IBOutlet weak var dialogLabel: NSTextField!
    @IBOutlet weak var deployButton: NSButton!
    
    var preferences = Preferences()
    override var representedObject: Any? {
        didSet {
            if let url = representedObject as? URL {
                self.pathTextField.stringValue = "\(url)"
                self.updateDialog()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tableview
        self.serverTableView.delegate = self
        self.serverTableView.dataSource = self
        self.serverTableView.target = self
        
        // set delegate so we know when the text changes
        self.pathTextField.delegate = self
        
        // set defaults
        self.deployButton.isEnabled = false
        self.dialogLabel.stringValue = self.defaultDialogText

        self.show(preferences: self.preferences)
    }
    
    func show(preferences: Preferences) {
        self.pathTextField.stringValue = preferences.defaultPath
    }
    
    func updateDialog() {
        let selectedRow = self.serverTableView.selectedRow
        let text = self.pathTextField.stringValue
        
        guard selectedRow >= 0 && selectedRow < self.preferences.dbConfigs.count && text.count > 0 else {
            self.deployButton.isEnabled = false
            self.dialogLabel.stringValue = self.defaultDialogText
            return
        }
        
        self.deployButton.isEnabled = true
        let name = self.preferences.dbConfigs[selectedRow].name
        
        self.dialogLabel.stringValue = "I will deploy all the .sql scripts from \n\(text) \n\nto the database server \n\(name)\n\nShould I proceed?"
    }

    @IBAction func pathButtonClicked(_ sender: Any) {
        
    }
    
    @IBAction func deployButtonClicked(_ sender: Any) {
        
    }
    
    @IBAction func deployMenuButtonClicked(_ sender: Any) {
        self.deployButtonClicked(sender)
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

