
import Foundation
import AppKit
import Combine

// MARK: - PressAction

enum PressAction: String, CaseIterable, Identifiable {
    case none           = "none"
    case leftClick      = "leftClick"
    case playPause      = "playPause"
    case nextTrack      = "nextTrack"
    case prevTrack      = "prevTrack"
    case spaceBar       = "spaceBar"
    case markIn         = "markIn"
    case markOut        = "markOut"
    case bladeAtPlayhead = "bladeAtPlayhead"
    case meetingMute     = "meetingMute"
    case handRaise       = "handRaise"
    case endCall         = "endCall"
    case resetZoom       = "resetZoom"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:            return "None"
        case .leftClick:       return "Left Click"
        case .playPause:       return "Play / Pause"
        case .nextTrack:       return "Next Track"
        case .prevTrack:       return "Previous Track"
        case .spaceBar:        return "Space"
        case .markIn:          return "Mark In  (I)"
        case .markOut:         return "Mark Out  (O)"
        case .bladeAtPlayhead: return "Blade at Playhead  (⌘B)"
        case .meetingMute:     return "Mute / Unmute"
        case .handRaise:       return "Raise / Lower Hand"
        case .endCall:         return "End Call"
        case .resetZoom:       return "Reset Zoom  (⌘0)"
        }
    }

    // Available options per mode
    static let scrollOptions:   [PressAction] = [.none, .leftClick, .spaceBar]
    static let playbackOptions: [PressAction] = [.none, .playPause, .nextTrack, .prevTrack]
    static let fcpOptions:      [PressAction] = [.none, .leftClick, .spaceBar, .markIn, .markOut, .bladeAtPlayhead]
    static let zoomOptions:     [PressAction] = [.none, .resetZoom, .leftClick, .spaceBar]
    static let meetingOptions:  [PressAction] = [.none, .meetingMute, .handRaise, .endCall, .leftClick, .spaceBar]
    static let phoneOptions:    [PressAction] = [.none, .playPause, .meetingMute, .endCall]

    // MARK: Execution

    /// For click-based actions, sends the mouse-down on button press so hold-to-drag works.
    func executeDown() {
        if self == .leftClick { sendMouse(type: .leftMouseDown) }
    }

    /// Completes the action on button release.
    func executeUp() {
        switch self {
        case .none:            break
        case .leftClick:       sendMouse(type: .leftMouseUp)
        case .playPause:       HIDPostAuxKey(key: NX_KEYTYPE_PLAY,       modifiers: [])
        case .nextTrack:       HIDPostAuxKey(key: NX_KEYTYPE_NEXT,       modifiers: [])
        case .prevTrack:       HIDPostAuxKey(key: 18,                    modifiers: []) // NX_KEYTYPE_PREVIOUS
        case .spaceBar:        sendKey(keyCode: 49,  flags: [])
        case .markIn:          sendKey(keyCode: 34,  flags: [])            // I
        case .markOut:         sendKey(keyCode: 31,  flags: [])            // O
        case .bladeAtPlayhead: sendKey(keyCode: 11,  flags: .maskCommand)  // ⌘B
        case .meetingMute:
            // Zoom uses ⌘⇧A; Teams, FaceTime, Webex and others use ⌘⇧M
            let bid = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
            if bid == "us.zoom.xos" || bid == "zoom.us" {
                sendKey(keyCode: 0,  flags: [.maskCommand, .maskShift])  // ⌘⇧A
            } else {
                sendKey(keyCode: 46, flags: [.maskCommand, .maskShift])  // ⌘⇧M
            }
        case .handRaise:
            // Zoom: Option+Y.  Other apps: no universal shortcut.
            let bid = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
            if bid == "us.zoom.xos" || bid == "zoom.us" {
                sendKey(keyCode: 16, flags: .maskAlternate)              // ⌥Y
            }
        case .endCall:
            // Teams uses ⌘⇧H; Zoom and FaceTime both respond to ⌘W
            let bid = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
            if bid == "com.microsoft.teams" || bid == "com.microsoft.teams2" {
                sendKey(keyCode: 4, flags: [.maskCommand, .maskShift])   // ⌘⇧H
            } else {
                sendKey(keyCode: 13, flags: .maskCommand)                // ⌘W
            }
        case .resetZoom:
            sendKey(keyCode: 29, flags: .maskCommand)                    // ⌘0
        }
    }

    private func sendMouse(type: CGEventType) {
        let pos = NSEvent.mouseLocation
        let h   = NSScreen.main?.frame.height ?? 0
        let translated = NSPoint(x: pos.x, y: h - pos.y)
        CGEvent(mouseEventSource: nil, mouseType: type,
                mouseCursorPosition: translated, mouseButton: .left)?
            .post(tap: .cghidEventTap)
    }

    private func sendKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let src = CGEventSource(stateID: .hidSystemState)
        let dn = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        dn?.flags = flags; dn?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        up?.flags = flags; up?.post(tap: .cghidEventTap)
    }
}

// MARK: - DialSettings

class DialSettings: ObservableObject {

    private let dial: Dial

    // MARK: Nested types

    enum DirectionOption: String, CaseIterable, Identifiable {
        case standard, natural
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var dialValue: Int { self == .natural ? -1 : 1 }
    }

    enum SensitivityOption: String, CaseIterable, Identifiable {
        case low, medium, high, extreme
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var dialValue: Int {
            switch self {
            case .low:     return 18
            case .medium:  return 36
            case .high:    return 72
            case .extreme: return 360
            }
        }
    }

    // MARK: Scroll Mode

    @Published var scrollDirection: DirectionOption {
        didSet { ud("scroll.direction", scrollDirection.rawValue); dial.scrollDirection = scrollDirection.dialValue }
    }
    @Published var scrollSensitivity: SensitivityOption {
        didSet { ud("scroll.sensitivity", scrollSensitivity.rawValue) }
    }
    @Published var scrollHaptics: Bool {
        didSet { ud("scroll.haptics", scrollHaptics ? "enabled" : "disabled"); dial.haptics = scrollHaptics }
    }
    @Published var scrollSinglePress: PressAction {
        didSet { ud("scroll.press.single", scrollSinglePress.rawValue) }
    }
    @Published var scrollDoublePress: PressAction {
        didSet { ud("scroll.press.double", scrollDoublePress.rawValue) }
    }

    // MARK: Playback Mode

    /// Steps per full revolution (0.2–100). Accumulator in controller scales hardware 36-tick events.
    @Published var playbackSensitivity: Double {
        didSet { UserDefaults.standard.set(playbackSensitivity, forKey: "playback.sensitivity") }
    }
    @Published var playbackHaptics: Bool {
        didSet {
            ud("playback.haptics", playbackHaptics ? "enabled" : "disabled")
            if UserDefaults.standard.string(forKey: "mode") == "playback" { dial.haptics = playbackHaptics }
        }
    }
    @Published var playbackSinglePress: PressAction {
        didSet { ud("playback.press.single", playbackSinglePress.rawValue) }
    }
    @Published var playbackDoublePress: PressAction {
        didSet { ud("playback.press.double", playbackDoublePress.rawValue) }
    }

    // MARK: FCP Mode

    @Published var fcpSensitivity: SensitivityOption {
        didSet { ud("fcp.sensitivity", fcpSensitivity.rawValue) }
    }
    @Published var fcpDirection: DirectionOption {
        didSet { ud("fcp.direction", fcpDirection.rawValue) }
    }
    @Published var fcpHaptics: Bool {
        didSet { ud("fcp.haptics", fcpHaptics ? "enabled" : "disabled") }
    }
    @Published var fcpSinglePress: PressAction {
        didSet { ud("fcp.press.single", fcpSinglePress.rawValue) }
    }
    @Published var fcpDoublePress: PressAction {
        didSet { ud("fcp.press.double", fcpDoublePress.rawValue) }
    }

    // MARK: Zoom Mode

    @Published var zoomSensitivity: SensitivityOption {
        didSet { ud("zoom.sensitivity", zoomSensitivity.rawValue) }
    }
    @Published var zoomHaptics: Bool {
        didSet {
            ud("zoom.haptics", zoomHaptics ? "enabled" : "disabled")
            if UserDefaults.standard.string(forKey: "mode") == "zoom" { dial.haptics = zoomHaptics }
        }
    }
    @Published var zoomSinglePress: PressAction {
        didSet { ud("zoom.press.single", zoomSinglePress.rawValue) }
    }
    @Published var zoomDoublePress: PressAction {
        didSet { ud("zoom.press.double", zoomDoublePress.rawValue) }
    }
    @Published var zoomAutoSwitchBundleIds: [String] {
        didSet { UserDefaults.standard.set(zoomAutoSwitchBundleIds, forKey: "zoom.autoSwitch.bundleIds") }
    }

    // MARK: Meetings Mode

    @Published var meetingsSensitivity: Double {
        didSet { UserDefaults.standard.set(meetingsSensitivity, forKey: "meetings.sensitivity") }
    }
    @Published var meetingsHaptics: Bool {
        didSet {
            ud("meetings.haptics", meetingsHaptics ? "enabled" : "disabled")
            if UserDefaults.standard.string(forKey: "mode") == "meetings" { dial.haptics = meetingsHaptics }
        }
    }
    @Published var meetingsSinglePress: PressAction {
        didSet { ud("meetings.press.single", meetingsSinglePress.rawValue) }
    }
    @Published var meetingsDoublePress: PressAction {
        didSet { ud("meetings.press.double", meetingsDoublePress.rawValue) }
    }
    @Published var meetingsAutoSwitchBundleIds: [String] {
        didSet { UserDefaults.standard.set(meetingsAutoSwitchBundleIds, forKey: "meetings.autoSwitch.bundleIds") }
    }

    // MARK: Phone Mode

    @Published var phoneSensitivity: Double {
        didSet { UserDefaults.standard.set(phoneSensitivity, forKey: "phone.sensitivity") }
    }
    @Published var phoneHaptics: Bool {
        didSet {
            ud("phone.haptics", phoneHaptics ? "enabled" : "disabled")
            if UserDefaults.standard.string(forKey: "mode") == "phone" { dial.haptics = phoneHaptics }
        }
    }
    @Published var phoneSinglePress: PressAction {
        didSet { ud("phone.press.single", phoneSinglePress.rawValue) }
    }
    @Published var phoneDoublePress: PressAction {
        didSet { ud("phone.press.double", phoneDoublePress.rawValue) }
    }
    @Published var phoneAutoSwitchBundleIds: [String] {
        didSet { UserDefaults.standard.set(phoneAutoSwitchBundleIds, forKey: "phone.autoSwitch.bundleIds") }
    }

    // MARK: Auto-Switch (FCP)

    /// Bundle IDs of apps that trigger auto-switch to FCP Scrub mode.
    /// Empty array = auto-switching disabled.
    @Published var autoSwitchBundleIds: [String] {
        didSet { UserDefaults.standard.set(autoSwitchBundleIds, forKey: "autoSwitch.bundleIds") }
    }

    // MARK: Init

    init(dial: Dial) {
        self.dial = dial

        func s(_ key: String, _ def: String) -> String { UserDefaults.standard.string(forKey: key) ?? def }
        func dir(_ key: String, _ def: DirectionOption)    -> DirectionOption    { DirectionOption(rawValue: s(key, def.rawValue)) ?? def }
        func sens(_ key: String, _ def: SensitivityOption) -> SensitivityOption { SensitivityOption(rawValue: s(key, def.rawValue)) ?? def }
        func press(_ key: String, _ def: PressAction)      -> PressAction       { PressAction(rawValue: s(key, def.rawValue)) ?? def }
        func haptics(_ key: String) -> Bool { s(key, "disabled") == "enabled" }

        let savedPlaybackSens = UserDefaults.standard.double(forKey: "playback.sensitivity")

        _scrollDirection    = Published(initialValue: dir("scroll.direction",    .natural))
        _scrollSensitivity  = Published(initialValue: sens("scroll.sensitivity", .medium))
        _scrollHaptics      = Published(initialValue: haptics("scroll.haptics"))
        _scrollSinglePress  = Published(initialValue: press("scroll.press.single", .leftClick))
        _scrollDoublePress  = Published(initialValue: press("scroll.press.double", .none))

        _playbackSensitivity = Published(initialValue: savedPlaybackSens > 0 ? savedPlaybackSens : 10.0)
        _playbackHaptics     = Published(initialValue: haptics("playback.haptics"))
        _playbackSinglePress = Published(initialValue: press("playback.press.single", .playPause))
        _playbackDoublePress = Published(initialValue: press("playback.press.double", .nextTrack))

        _fcpSensitivity  = Published(initialValue: sens("fcp.sensitivity", .medium))
        _fcpDirection    = Published(initialValue: dir("fcp.direction",    .standard))
        _fcpHaptics      = Published(initialValue: haptics("fcp.haptics"))
        _fcpSinglePress  = Published(initialValue: press("fcp.press.single", .leftClick))
        _fcpDoublePress  = Published(initialValue: press("fcp.press.double", .spaceBar))

        _zoomSensitivity          = Published(initialValue: sens("zoom.sensitivity", .low))
        _zoomHaptics              = Published(initialValue: haptics("zoom.haptics"))
        _zoomSinglePress          = Published(initialValue: press("zoom.press.single", .resetZoom))
        _zoomDoublePress          = Published(initialValue: press("zoom.press.double", .none))
        _zoomAutoSwitchBundleIds  = Published(initialValue:
            UserDefaults.standard.stringArray(forKey: "zoom.autoSwitch.bundleIds") ?? ["com.bohemiancoding.sketch3"])

        let savedMeetingsSens = UserDefaults.standard.double(forKey: "meetings.sensitivity")
        let savedPhoneSens    = UserDefaults.standard.double(forKey: "phone.sensitivity")

        _meetingsSensitivity         = Published(initialValue: savedMeetingsSens > 0 ? savedMeetingsSens : 10.0)
        _meetingsHaptics             = Published(initialValue: haptics("meetings.haptics"))
        _meetingsSinglePress         = Published(initialValue: press("meetings.press.single", .meetingMute))
        _meetingsDoublePress         = Published(initialValue: press("meetings.press.double", .handRaise))
        _meetingsAutoSwitchBundleIds = Published(initialValue:
            UserDefaults.standard.stringArray(forKey: "meetings.autoSwitch.bundleIds") ?? [])

        _phoneSensitivity            = Published(initialValue: savedPhoneSens > 0 ? savedPhoneSens : 10.0)
        _phoneHaptics                = Published(initialValue: haptics("phone.haptics"))
        _phoneSinglePress            = Published(initialValue: press("phone.press.single", .meetingMute))
        _phoneDoublePress            = Published(initialValue: press("phone.press.double", .playPause))
        _phoneAutoSwitchBundleIds    = Published(initialValue:
            UserDefaults.standard.stringArray(forKey: "phone.autoSwitch.bundleIds") ?? [])

        _autoSwitchBundleIds = Published(initialValue:
            UserDefaults.standard.stringArray(forKey: "autoSwitch.bundleIds") ?? ["com.apple.FinalCut"])

        // Apply initial values to dial
        dial.scrollDirection  = dir("scroll.direction", .natural).dialValue
        dial.wheelSensitivity = sens("scroll.sensitivity", .medium).dialValue
        dial.haptics          = haptics("scroll.haptics")
    }

    /// Called on every mode switch to apply the right sensitivity and haptics to the dial.
    func applySensitivity(for mode: Mode) {
        switch mode {
        case .scrolling:
            dial.wheelSensitivity = scrollSensitivity.dialValue
            dial.haptics = scrollHaptics
        case .playback:
            dial.wheelSensitivity = 36
            dial.haptics = playbackHaptics
        case .fcp:
            dial.wheelSensitivity = fcpSensitivity.dialValue
            dial.haptics = fcpHaptics
        case .zoom:
            dial.wheelSensitivity = zoomSensitivity.dialValue
            dial.haptics = zoomHaptics
        case .meetings:
            dial.wheelSensitivity = 36
            dial.haptics = meetingsHaptics
        case .phone:
            dial.wheelSensitivity = 36
            dial.haptics = phoneHaptics
        }
    }

    private func ud(_ key: String, _ value: String) { UserDefaults.standard.set(value, forKey: key) }
}
