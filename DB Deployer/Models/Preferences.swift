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
                return "/Users"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.defaultPathKey)
        }
    }
    
    var sqlPath: String {
        get {
            if let path = UserDefaults.standard.object(forKey: Constants.sqlPathKey) as? String {
                return path
            } else {
                return "/Users"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.sqlPathKey)
        }
    }
    
    var dbConfigs: [DBConfig] {
        get {
            guard let data = UserDefaults.standard.array(forKey: Constants.configListKey) as? [Data] else {
                print("could not load default configs")
                return []
            }
            
            do {
                return try data.map { try JSONDecoder().decode(DBConfig.self, from: $0) }
            } catch {
                print("could not load default configs")
                return []
            }
        }
        set {
            let data = newValue.map { try? JSONEncoder().encode($0) }
            UserDefaults.standard.set(data, forKey: Constants.configListKey)
        }
    }
    
}
