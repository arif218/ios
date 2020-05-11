//
//  ConfigManager.swift
//  safesafe
//
//  Created by Lukasz szyszkowski on 24/04/2020.
//  Copyright © 2020 Lukasz szyszkowski. All rights reserved.
//

import Foundation

final class ConfigManager {
    
    #if DEV
    static private let configPlistName = "Config-dev"
    #elseif STAGE
    static private let configPlistName = "Config-stage"
    #elseif LIVE
    static private let configPlistName = "Config-live"
    #endif
    
    static let `default` = ConfigManager(plistName: configPlistName)
    
    private enum Key {
        // PWA Settings
        static let pwa = "PWA" // Dictionary
        static let host = "HOST" // String
        static let scheme = "SCHEME" // String
     }
    
    private let settings: [String: Any]
    
    init(plistName: String) {
        guard
            let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            fatalError("Can't find \(plistName).plist")
        }
        
        settings = plist
    }
    
    private func value<T>(for key: String, dictionary: [String: Any]) -> T {
        guard let dictValue = dictionary[key] as? T else {
            fatalError("Can't read value [\(T.self)] for \(key)")
        }
        
        return dictValue
    }
    
}

// PWA
extension ConfigManager {
    private var pwaSettings: [String: Any] {
        guard let dictionary = settings[Key.pwa] as? [String: Any] else {
            fatalError("Can't read \(Key.pwa) from plist")
        }
        
        return dictionary
    }
    
    var pwaHost: String {
        return value(for: Key.host, dictionary: pwaSettings)
    }
    
    var pwaScheme: String {
        return value(for: Key.scheme, dictionary: pwaSettings)
    }
}
