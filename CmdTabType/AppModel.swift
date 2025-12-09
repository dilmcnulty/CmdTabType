import Foundation
import AppKit

struct AppModel: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
    
    static func getRunningApps() -> [AppModel] {
        return AppHistory.shared.getOrderedApps()
    }
}
