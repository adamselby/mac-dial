
import Foundation
import AppKit

class ZoomController: Controller {

    private let press = ButtonPressHandler(
        singleKey: "zoom.press.single", defaultSingle: .resetZoom,
        doubleKey:  "zoom.press.double", defaultDouble: .none
    )

    func onDown() { press.onDown() }
    func onUp()   { press.onUp() }

    func onRotate(_ rotation: Dial.Rotation, _ scrollDirection: Int) {
        let src = CGEventSource(stateID: .hidSystemState)
        func zoomKey(keyCode: CGKeyCode, count: Int) {
            for _ in 0..<count {
                let dn = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
                dn?.flags = .maskCommand; dn?.post(tap: .cghidEventTap)
                let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
                up?.flags = .maskCommand; up?.post(tap: .cghidEventTap)
            }
        }
        switch rotation {
        case .Clockwise(let r):        zoomKey(keyCode: 24, count: r)  // ⌘=  zoom in
        case .CounterClockwise(let r): zoomKey(keyCode: 27, count: r)  // ⌘–  zoom out
        }
    }
}
