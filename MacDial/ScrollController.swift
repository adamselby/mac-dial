
import Foundation
import AppKit

class ScrollController: Controller {

    private let press = ButtonPressHandler(
        singleKey: "scroll.press.single", defaultSingle: .leftClick,
        doubleKey:  "scroll.press.double", defaultDouble: .none
    )
    private var lastRotate: TimeInterval = Date().timeIntervalSince1970

    func onDown() { press.onDown() }
    func onUp()   { press.onUp() }

    func onRotate(_ rotation: Dial.Rotation, _ scrollDirection: Int) {
        var steps = 0
        switch rotation {
        case .Clockwise(let d):        steps =  d
        case .CounterClockwise(let d): steps = -d
        }
        steps *= scrollDirection

        let diff       = (Date().timeIntervalSince1970 - lastRotate) * 1000
        let multiplier = Int(1 + ((150 - min(diff, 150)) / 40))

        let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1,
                            wheel1: Int32(steps * multiplier), wheel2: 0, wheel3: 0)
        event?.post(tap: .cghidEventTap)

        lastRotate = Date().timeIntervalSince1970
    }
}
