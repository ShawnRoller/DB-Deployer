//
//  NewServerViewController.swift
//  DB Deployer
//
//  Created by Shawn Roller on 5/2/19.
//  Copyright © 2019 Shawn Roller. All rights reserved.
//

import Cocoa

protocol NewServerDelegate {
    func saveConfig(_ dbConfig: DBConfig)
    func dismissNewServerModal()
}

class NewServerViewController: NSViewController {

    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var serverTextField: NSTextField!
    @IBOutlet weak var databaseTextField: NSTextField!
    @IBOutlet weak var driverTextField: NSTextField!
    @IBOutlet weak var trustedCheckBox: NSButton!
    @IBOutlet weak var addButton: NSButton!
    
    public var delegate: NewServerDelegate!
    public var dbConfig: DBConfig?
    
    convenience init(delegate: NewServerDelegate, dbConfig: DBConfig?) {
        self.init()
        self.delegate = delegate
        self.dbConfig = dbConfig
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let config = self.dbConfig {
            // populate the fields with the config that is being edited
            self.loadDBConfig(config)
            self.addButton.title = "Save"
        }
        
        self.driverTextField.delegate = self
    }
    
    func loadDBConfig(_ dbConfig: DBConfig) {
        self.nameTextField.stringValue = dbConfig.name
        self.serverTextField.stringValue = dbConfig.server
        self.databaseTextField.stringValue = dbConfig.database
        self.driverTextField.stringValue = dbConfig.driver
        self.trustedCheckBox.state = dbConfig.trustedConnection ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
        self.dbConfig = DBConfig(name: self.nameTextField.stringValue, driver: self.driverTextField.stringValue, server: self.serverTextField.stringValue, database: self.databaseTextField.stringValue, trustedConnection: self.trustedCheckBox.state == NSControl.StateValue.on ? true : false)
        
        guard let config = self.dbConfig, config.isValidConfig else { return }
        self.delegate.saveConfig(config)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.delegate.dismissNewServerModal()
    }
    
}

extension NewServerViewController: NSTextFieldDelegate {
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let userInfo = obj.userInfo, let movement = userInfo["NSTextMovement"] as? Int, movement == 16 {
            self.addButtonClicked(obj)
        }
    }
    
}
