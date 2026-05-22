
import Foundation
import AppKit

class FCPScrubController: Controller {

    private let press = ButtonPressHandler(
        singleKey: "fcp.press.single", defaultSingle: .leftClick,
        doubleKey:  "fcp.press.double", defaultDouble: .spaceBar
    )
    private var lastRotate: TimeInterval = Date().timeIntervalSince1970

    func onDown() { press.onDown() }
    func onUp()   { press.onUp() }

    func onRotate(_ rotation: Dial.Rotation, _ scrollDirection: Int) {
        let diff = (Date().timeIntervalSince1970 - lastRotate) * 1000
        let fast = diff < 150

        let fcpDir = UserDefaults.standard.string(forKey: "fcp.direction") ?? "standard"
        let invert = (fcpDir == "natural")

        var keyCode: CGKeyCode
        switch rotation {
        case .Clockwise:        keyCode = invert ? 123 : 124   // 123 = ←, 124 = →
        case .CounterClockwise: keyCode = invert ? 124 : 123
        }

        let modifiers: CGEventFlags = fast ? .maskShift : []
        sendArrowKey(keyCode: keyCode, modifiers: modifiers)

        lastRotate = Date().timeIntervalSince1970
    }

    private func sendArrowKey(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let dn = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        dn?.flags = modifiers; dn?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        up?.flags = modifiers; up?.post(tap: .cghidEventTap)
    }
}
