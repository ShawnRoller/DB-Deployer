//
//  WindowController.swift
//  DB Deployer
//
//  Created by Shawn Roller on 4/29/19.
//  Copyright © 2019 Shawn Roller. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    @IBAction func openDocument(_ sender: AnyObject?) {
        
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response.rawValue == 1 else {
                // The user cancelled
                return
            }
            self.contentViewController?.representedObject = openPanel.url
        }
    }
    
    @IBAction func openPreferences(_ sender: AnyObject?) {
        guard let contentVC = self.contentViewController as? MainViewController else { return }
        contentVC.openPreferencesSheet()
    }

}
