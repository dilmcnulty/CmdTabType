import AppKit
import Combine

final class AppHistory {
    static let shared = AppHistory()
    
    private var recentBundleIds: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let excludedBundleId = Bundle.main.bundleIdentifier ?? ""
    
    private init() {
        initializeFromRunningApps()
        startListening()
    }
    
    private func initializeFromRunningApps() {
        let runningApps = regularApps
        
        if let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            recentBundleIds = [frontmostId] + runningApps
                .compactMap { $0.bundleIdentifier }
                .filter { $0 != frontmostId }
        } else {
            recentBundleIds = runningApps.compactMap { $0.bundleIdentifier }
        }
    }
    
    private func startListening() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { [excludedBundleId] notification -> String? in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      app.activationPolicy == .regular,
                      let bundleId = app.bundleIdentifier,
                      bundleId != excludedBundleId else { return nil }
                return bundleId
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.recordActivation($0) }
            .store(in: &cancellables)
    }
    
    private func recordActivation(_ bundleId: String) {
        recentBundleIds.removeAll { $0 == bundleId }
        recentBundleIds.insert(bundleId, at: 0)
        if recentBundleIds.count > 50 {
            recentBundleIds.removeLast(recentBundleIds.count - 50)
        }
    }
    
    private var regularApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.bundleIdentifier != excludedBundleId
        }
    }
    
    func getOrderedApps() -> [AppModel] {
        let running = regularApps
        let runningIds = Set(running.compactMap { $0.bundleIdentifier })
        
        var ordered: [String] = []
        var seen = Set<String>()
        
        // Add from history (if still running)
        for id in recentBundleIds where runningIds.contains(id) && !seen.contains(id) {
            ordered.append(id)
            seen.insert(id)
        }
        
        // Add any new apps not in history
        for app in running {
            if let id = app.bundleIdentifier, !seen.contains(id) {
                ordered.append(id)
                seen.insert(id)
            }
        }
        
        return ordered.compactMap { bundleId in
            guard let app = running.first(where: { $0.bundleIdentifier == bundleId }),
                  let name = app.localizedName,
                  let icon = app.icon else { return nil }
            return AppModel(id: bundleId, name: name, icon: icon)
        }
    }
}
