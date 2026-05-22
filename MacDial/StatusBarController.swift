
import Foundation
import AppKit

enum Mode: String {
    case scrolling = "scrolling"
    case playback  = "playback"
    case fcp       = "fcp"
    case zoom      = "zoom"
    case meetings  = "meetings"
    case phone     = "phone"
}

extension NSMenuItem {
    convenience init(title: String) {
        self.init()
        self.title = title
    }
}

class MenuOptionItem<Type>: NSMenuItem {
    init(title: String, option: Type) {
        super.init(title: title, action: nil, keyEquivalent: "")
        self.representedObject = option
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var selected: Bool {
        get { self.state == .on }
        set(on) { self.state = on ? .on : .off }
    }

    var option: Type { self.representedObject as! Type }
}

class ControllerOptionItem: MenuOptionItem<Mode> {
    let controller: Controller

    init(title: String, mode: Mode, controller: Controller) {
        self.controller = controller
        super.init(title: title, option: mode)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class StatusBarController {
    private let statusBar:  NSStatusBar
    private let statusItem: NSStatusItem
    private let menu:       NSMenu
    private let dial:       Dial
    private let settings:   DialSettings
    private let menuItems = MenuItems()

    struct MenuItems {
        let title            = NSMenuItem(title: "Mac Dial")
        let connectionStatus = NSMenuItem()
        let sep1             = NSMenuItem.separator()
        let scrollMode       = ControllerOptionItem(title: "Scrolling",    mode: .scrolling, controller: ScrollController())
        let playbackMode     = ControllerOptionItem(title: "Playing",      mode: .playback,  controller: PlaybackController())
        let fcpScrubMode     = ControllerOptionItem(title: "Scrubbing",    mode: .fcp,       controller: FCPScrubController())
        let zoomMode         = ControllerOptionItem(title: "Zooming",      mode: .zoom,      controller: ZoomController())
        let meetingsMode     = ControllerOptionItem(title: "Conferencing", mode: .meetings,  controller: MeetingsController())
        let phoneMode        = ControllerOptionItem(title: "Calling",      mode: .phone,     controller: PhoneController())
        let sep2             = NSMenuItem.separator()
        let settingsItem     = NSMenuItem(title: "Settings…")
        let sep3             = NSMenuItem.separator()
        let quit             = NSMenuItem(title: "Quit")
    }

    var currentMode: Mode {
        get {
            switch UserDefaults.standard.string(forKey: "mode") {
            case .some("scroll"):   return .scrolling
            case .some("playback"): return .playback
            case .some("fcp"):      return .fcp
            case .some("zoom"):     return .zoom
            case .some("meetings"): return .meetings
            case .some("phone"):    return .phone
            default:                return .playback
            }
        }
        set {
            switch newValue {
            case .scrolling: UserDefaults.standard.set("scroll",   forKey: "mode")
            case .playback:  UserDefaults.standard.set("playback", forKey: "mode")
            case .fcp:       UserDefaults.standard.set("fcp",      forKey: "mode")
            case .zoom:      UserDefaults.standard.set("zoom",     forKey: "mode")
            case .meetings:  UserDefaults.standard.set("meetings", forKey: "mode")
            case .phone:     UserDefaults.standard.set("phone",    forKey: "mode")
            }
        }
    }

    var currentController: Controller {
        switch currentMode {
        case .scrolling: return menuItems.scrollMode.controller
        case .playback:  return menuItems.playbackMode.controller
        case .fcp:       return menuItems.fcpScrubMode.controller
        case .zoom:      return menuItems.zoomMode.controller
        case .meetings:  return menuItems.meetingsMode.controller
        case .phone:     return menuItems.phoneMode.controller
        }
    }

    init(_ dial: Dial, settings: DialSettings) {
        self.dial     = dial
        self.settings = settings
        self.menu     = NSMenu()

        statusBar  = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        menu.minimumWidth = 220

        let bold: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 0)]
        menuItems.title.attributedTitle = NSAttributedString(string: menuItems.title.title, attributes: bold)
        menuItems.title.target = self
        menuItems.title.action = #selector(openSettings(sender:))

        menuItems.connectionStatus.isEnabled = false

        for item in [menuItems.scrollMode, menuItems.playbackMode, menuItems.fcpScrubMode,
                     menuItems.zoomMode, menuItems.meetingsMode, menuItems.phoneMode] {
            item.target = self
            item.action = #selector(setMode(sender:))
        }
        menuItems.scrollMode.selected    = currentMode == .scrolling
        menuItems.playbackMode.selected  = currentMode == .playback
        menuItems.fcpScrubMode.selected  = currentMode == .fcp
        menuItems.zoomMode.selected      = currentMode == .zoom
        menuItems.meetingsMode.selected  = currentMode == .meetings
        menuItems.phoneMode.selected     = currentMode == .phone

        menuItems.settingsItem.target = self
        menuItems.settingsItem.action = #selector(openSettings(sender:))

        menuItems.quit.target = self
        menuItems.quit.action = #selector(quitApp(sender:))

        for item in [menuItems.title, menuItems.connectionStatus, menuItems.sep1,
                     menuItems.scrollMode, menuItems.playbackMode, menuItems.fcpScrubMode,
                     menuItems.zoomMode, menuItems.meetingsMode, menuItems.phoneMode,
                     menuItems.sep2, menuItems.settingsItem, menuItems.sep3, menuItems.quit] {
            menu.addItem(item)
        }

        statusItem.menu = menu
        updateIcon()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateConnectionStatus()
        }

        dial.onButtonStateChanged = { [unowned self] state in
            switch state {
            case .pressed:  currentController.onDown()
            case .released: currentController.onUp()
            }
        }

        dial.onRotation = { [unowned self] rotation, scrollDirection in
            currentController.onRotate(rotation, scrollDirection)
        }
    }

    // MARK: - Public API

    func switchMode(to mode: Mode) {
        menuItems.scrollMode.state   = mode == .scrolling ? .on : .off
        menuItems.playbackMode.state = mode == .playback  ? .on : .off
        menuItems.fcpScrubMode.state = mode == .fcp       ? .on : .off
        menuItems.zoomMode.state     = mode == .zoom      ? .on : .off
        menuItems.meetingsMode.state = mode == .meetings  ? .on : .off
        menuItems.phoneMode.state    = mode == .phone     ? .on : .off
        currentMode = mode
        settings.applySensitivity(for: mode)
        updateIcon()
    }

    // MARK: - Private

    private func updateConnectionStatus() {
        if dial.device.isConnected {
            menuItems.connectionStatus.title = "Surface Dial '\(dial.device.serialNumber)' connected"
        } else {
            menuItems.connectionStatus.title = "No Surface Dial connected"
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbol: String
        switch currentMode {
        case .scrolling: symbol = "arrow.up.arrow.down"
        case .playback:  symbol = "playpause"
        case .fcp:       symbol = "forward.frame"
        case .zoom:      symbol = "magnifyingglass"
        case .meetings:  symbol = "video.fill"
        case .phone:     symbol = "phone.fill"
        }
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)
        button.image?.size = NSSize(width: 18, height: 18)
        button.imagePosition = .imageLeft
    }

    @objc func setMode(sender: AnyObject) {
        switchMode(to: (sender as! ControllerOptionItem).option)
    }

    @objc func openSettings(sender: AnyObject) {
        SettingsWindowController.shared.show(settings: settings)
    }

    @objc func quitApp(sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }
}
