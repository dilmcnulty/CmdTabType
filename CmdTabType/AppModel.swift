//
//  AppModel.swift
//  CmdTabType
//
//  Created by Dillon McNulty on 12/9/25.
//

import Foundation
import AppKit

struct AppModel: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
    
    static func getRunningApps() -> [AppModel] {
        return NSWorkspace.shared.runningApplications.compactMap{ app in
            if (app.activationPolicy != .regular) { return nil }
            
            guard let bundleId = app.bundleIdentifier else { return nil }
            
            guard let name = app.localizedName else { return nil }
            
            guard let icon = app.icon else { return nil }
            
            return AppModel(id: bundleId, name: name, icon: icon)
            
        }
    }
}
