
import AppKit
import SwiftUI

class SettingsWindowController {

    static let shared = SettingsWindowController()

    private var windowController: NSWindowController?

    private init() {}

    func show(settings: DialSettings) {
        if windowController == nil {
            let hostingView = NSHostingView(rootView: SettingsView(settings: settings))

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 740, height: 520),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Mac Dial Settings"
            window.contentView = hostingView
            window.center()
            window.setFrameAutosaveName("SettingsWindow")
            windowController = NSWindowController(window: window)
        }

        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
}
