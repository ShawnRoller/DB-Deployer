//
//  PreferencesViewController.swift
//  DB Deployer
//
//  Created by Shawn Roller on 4/29/19.
//  Copyright © 2019 Shawn Roller. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet weak var serverTableView: NSTableView!
    @IBOutlet weak var defaultPathTextField: NSTextField!
    @IBOutlet weak var deleteServerButton: NSButton!
    @IBOutlet weak var addServerButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    var preferences = Preferences()
    var tempDBConfigs: [DBConfig] = []
    var tempPath: String = ""
    
    override var representedObject: Any? {
        didSet {
            if let url = representedObject as? URL {
                self.defaultPathTextField.stringValue = "\(url)"
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tableview
        self.serverTableView.delegate = self
        self.serverTableView.dataSource = self
        self.serverTableView.target = self
        
        // setup default prefs
        self.loadTempPrefs(from: self.preferences)
        
        // show the prefs
        self.show(preferences: self.preferences)
    }
    
    func loadTempPrefs(from preferences: Preferences) {
        self.tempDBConfigs = preferences.dbConfigs
        self.tempPath = preferences.defaultPath
    }
    
    func show(preferences: Preferences) {
        self.defaultPathTextField.stringValue = preferences.defaultPath
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        self.preferences.defaultPath = self.defaultPathTextField.stringValue
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.prefsChanged), object: nil)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
    }
    
}

extension PreferencesViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.preferences.dbConfigs.count
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

extension PreferencesViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < self.tempDBConfigs.count, let columnID = tableColumn?.identifier else { return nil }
        
        let id = columnID.rawValue
        var cellTitle = ""
        let config = self.tempDBConfigs[row]
        
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


