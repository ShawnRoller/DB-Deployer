//
//  Preferences.swift
//  DB Deployer
//
//  Created by Shawn Roller on 4/29/19.
//  Copyright © 2019 Shawn Roller. All rights reserved.
//

import Foundation

struct Preferences {
    
    var defaultPath: String {
        get {
            if let path = UserDefaults.standard.object(forKey: Constants.defaultPathKey) as? String {
                return path
            } else {
                return "file:///Users/"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.defaultPathKey)
        }
    }
    
    var dbConfigs: [DBConfig] {
        get {
            if let configs = UserDefaults.standard.object(forKey: Constants.configListKey) as? [DBConfig] {
                return configs
            } else {
                let config = DBConfig(name: "test", driver: "test driver", server: "test server", database: "test db", trustedConnection: true)
                let config1 = DBConfig(name: "abc", driver: "test driver z", server: "z test server", database: "r test db", trustedConnection: false)
                return [config, config1]
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.configListKey)
        }
    }
    
}
