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
    @IBOutlet weak var defaultPathControl: NSPathControl!
    @IBOutlet weak var sqlPathControl: NSPathControl!
    @IBOutlet weak var deleteServerButton: NSButton!
    @IBOutlet weak var addServerButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    var preferences = Preferences()
    var tempDBConfigs: [DBConfig] = []
    var tempPath: String = ""
    var editingConfigIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton.isHidden = true
        
        // setup tableview
        self.serverTableView.delegate = self
        self.serverTableView.dataSource = self
        self.serverTableView.target = self
        self.serverTableView.doubleAction = #selector(doubleClickedServer(_:))
        
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
        self.defaultPathControl.url = URL(fileURLWithPath: preferences.defaultPath)
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        self.preferences.defaultPath = self.defaultPathControl.url?.path ?? "/"
        self.preferences.sqlPath = self.sqlPathControl.url?.path ?? "/"
        self.preferences.dbConfigs = self.tempDBConfigs
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.prefsChanged), object: nil)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard let window = self.view.window else { return }
        window.close()
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
        openServerSheet(with: nil)
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        guard self.serverTableView.selectedRow >= 0, self.serverTableView.selectedRow < self.tempDBConfigs.count else { return }
        self.tempDBConfigs.remove(at: self.serverTableView.selectedRow)
        self.serverTableView.reloadData()
    }
    
    func openServerSheet(with config: DBConfig?) {
        guard let sb = self.storyboard, let vc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(stringLiteral: "NewServerViewController")) as? NewServerViewController else { return }
        vc.delegate = self
        vc.dbConfig = config
        self.presentAsSheet(vc)
    }
    
    func closeSheet() {
        guard let window = self.view.window, let sheet = window.attachedSheet else { return }
        window.endSheet(sheet)
    }
}

extension PreferencesViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.tempDBConfigs.count
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
    
    @objc func doubleClickedServer(_ sender: Any) {
        guard self.serverTableView.selectedRow >= 0 else { return }
        let config = self.tempDBConfigs[self.serverTableView.selectedRow]
        self.editingConfigIndex = self.serverTableView.selectedRow
        self.openServerSheet(with: config)
    }
    
}

extension PreferencesViewController: NewServerDelegate {
    
    func saveConfig(_ dbConfig: DBConfig) {
        if self.editingConfigIndex >= 0 {
            // a config was edited
            self.tempDBConfigs[self.editingConfigIndex] = dbConfig
            self.editingConfigIndex = -1
        } else {
            // a new config was saved
            self.tempDBConfigs.append(dbConfig)
        }
        self.closeSheet()
        self.serverTableView.reloadData()
    }
    
    func dismissNewServerModal() {
        self.editingConfigIndex = -1
        self.closeSheet()
    }
    
}


