
import AppKit

class AppSwitcher {

    private weak var statusBarController: StatusBarController?
    private var previousMode: Mode = .scrolling
    private var autoSwitched = false

    // Priority: FCP > Zoom > Meetings > Phone. First match wins.
    private func targetMode(for bundleId: String) -> Mode? {
        let fcp      = UserDefaults.standard.stringArray(forKey: "autoSwitch.bundleIds")           ?? ["com.apple.FinalCut"]
        let zoom     = UserDefaults.standard.stringArray(forKey: "zoom.autoSwitch.bundleIds")      ?? ["com.bohemiancoding.sketch3"]
        let meetings = UserDefaults.standard.stringArray(forKey: "meetings.autoSwitch.bundleIds")  ?? []
        let phone    = UserDefaults.standard.stringArray(forKey: "phone.autoSwitch.bundleIds")     ?? []

        if fcp.contains(bundleId)      { return .fcp }
        if zoom.contains(bundleId)     { return .zoom }
        if meetings.contains(bundleId) { return .meetings }
        if phone.contains(bundleId)    { return .phone }
        return nil
    }

    init(statusBarController: StatusBarController) {
        self.statusBarController = statusBarController

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self, let sbc = self.statusBarController else { return }

            if let target = self.targetMode(for: bundleId) {
                if sbc.currentMode != target {
                    // Only record previousMode on the first auto-switch so we always
                    // restore to the original manually-chosen mode.
                    if !self.autoSwitched {
                        self.previousMode = sbc.currentMode
                        self.autoSwitched = true
                    }
                    sbc.switchMode(to: target)
                }
            } else if self.autoSwitched {
                self.autoSwitched = false
                sbc.switchMode(to: self.previousMode)
            }
        }
    }
}
