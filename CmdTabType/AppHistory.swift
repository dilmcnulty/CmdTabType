import AppKit
import Combine

class AppHistory: ObservableObject {
    static let shared = AppHistory()
    
    private var recentBundleIds: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let excludedBundleId = Bundle.main.bundleIdentifier ?? ""
    
    private init() {
        initializeFromRunningApps()
        startListening()
    }
    
    private func initializeFromRunningApps() {
        // Get currently running apps, put frontmost first
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != excludedBundleId }
        
        // Try to put the active app first
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let frontmostId = frontmost.bundleIdentifier {
            recentBundleIds = [frontmostId]
            for app in runningApps {
                if let bundleId = app.bundleIdentifier, bundleId != frontmostId {
                    recentBundleIds.append(bundleId)
                }
            }
        } else {
            recentBundleIds = runningApps.compactMap { $0.bundleIdentifier }
        }
    }
    
    private func startListening() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { notification -> String? in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      app.activationPolicy == .regular,
                      let bundleId = app.bundleIdentifier,
                      bundleId != self.excludedBundleId else {
                    return nil
                }
                return bundleId
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bundleId in
                self?.recordActivation(bundleId)
            }
            .store(in: &cancellables)
    }
    
    private func recordActivation(_ bundleId: String) {
        // Move to front (position 0)
        recentBundleIds.removeAll { $0 == bundleId }
        recentBundleIds.insert(bundleId, at: 0)
        
        // Limit size
        if recentBundleIds.count > 50 {
            recentBundleIds = Array(recentBundleIds.prefix(50))
        }
        
        print("App activated: \(bundleId), order: \(recentBundleIds.prefix(5))")
    }
    
    func getOrderedApps() -> [AppModel] {
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != excludedBundleId }
        
        let runningBundleIds = Set(runningApps.compactMap { $0.bundleIdentifier })
        
        var orderedBundleIds: [String] = []
        var seen = Set<String>()
        
        // Add from history (preserving order, only if still running)
        for bundleId in recentBundleIds {
            if runningBundleIds.contains(bundleId) && !seen.contains(bundleId) {
                orderedBundleIds.append(bundleId)
                seen.insert(bundleId)
            }
        }
        
        // Add any newly launched apps not in history
        for app in runningApps {
            if let bundleId = app.bundleIdentifier, !seen.contains(bundleId) {
                orderedBundleIds.append(bundleId)
                seen.insert(bundleId)
            }
        }
        
        return orderedBundleIds.compactMap { bundleId in
            guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleId }),
                  let name = app.localizedName,
                  let icon = app.icon else {
                return nil
            }
            return AppModel(id: bundleId, name: name, icon: icon)
        }
    }
}
