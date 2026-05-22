
import Foundation
import AppKit

protocol Controller: AnyObject {
    func onDown()
    func onUp()
    func onRotate(_ rotation: Dial.Rotation,_ scrollDirection: Int)
}

// MARK: - ButtonPressHandler
//
// Implements proper single/double-press detection: single fires only after the
// double-press window expires, so the two actions are mutually exclusive.
// If doublePress is .none the handler fires single immediately (no delay).

class ButtonPressHandler {
    private let singleKey:     String
    private let doubleKey:     String
    private let defaultSingle: PressAction
    private let defaultDouble: PressAction
    private let delay:         TimeInterval = 0.35

    private var lastUpTime:  TimeInterval    = 0
    private var pendingWork: DispatchWorkItem?

    init(singleKey: String, defaultSingle: PressAction,
         doubleKey: String, defaultDouble: PressAction) {
        self.singleKey     = singleKey
        self.defaultSingle = defaultSingle
        self.doubleKey     = doubleKey
        self.defaultDouble = defaultDouble
    }

    var singlePress: PressAction {
        PressAction(rawValue: UserDefaults.standard.string(forKey: singleKey) ?? defaultSingle.rawValue) ?? defaultSingle
    }
    var doublePress: PressAction {
        PressAction(rawValue: UserDefaults.standard.string(forKey: doubleKey) ?? defaultDouble.rawValue) ?? defaultDouble
    }

    func onDown() {
        // If no double action, fire mouseDown immediately so hold-to-drag works.
        if doublePress == .none {
            singlePress.executeDown()
        }
    }

    func onUp() {
        let now = Date().timeIntervalSince1970

        // Fast path: no double action configured — fire immediately.
        if doublePress == .none {
            singlePress.executeUp()
            lastUpTime = now
            return
        }

        // Check for double press: second up within window while single is pending.
        if now - lastUpTime < delay, pendingWork != nil {
            pendingWork?.cancel()
            pendingWork = nil
            doublePress.executeUp()
        } else {
            // Potential single — delay to leave room for a double.
            let single = singlePress
            let work = DispatchWorkItem { [weak self] in
                single.executeDown()
                single.executeUp()
                self?.pendingWork = nil
            }
            pendingWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }

        lastUpTime = now
    }
}
