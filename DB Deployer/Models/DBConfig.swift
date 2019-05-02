//
//  DBConfig.swift
//  DB Deployer
//
//  Created by Shawn Roller on 4/29/19.
//  Copyright © 2019 Shawn Roller. All rights reserved.
//

import Foundation

struct DBConfig: Codable {
    
    var name = ""
    var driver = ""
    var server = ""
    var database = ""
    var trustedConnection = false
    var isValidConfig: Bool {
        return driver.count > 0 && server.count > 0 && database.count > 0
    }
}
