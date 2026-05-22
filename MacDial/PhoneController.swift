
import Foundation
import AppKit

// Mirrors EarPods remote behavior (PR #32):
//   Rotate         → volume up / down
//   Single press   → answer incoming call / end call / play-pause  (NX_KEYTYPE_PLAY)
//   Double press   → skip forward                                    (NX_KEYTYPE_NEXT)

class PhoneController: Controller {

    private let press = ButtonPressHandler(
        singleKey: "phone.press.single", defaultSingle: .meetingMute,
        doubleKey:  "phone.press.double", defaultDouble: .playPause
    )
    private var accUp:   Double = 0
    private var accDown: Double = 0

    func onDown() { press.onDown() }
    func onUp()   { press.onUp() }

    func onRotate(_ rotation: Dial.Rotation, _ scrollDirection: Int) {
        let sens  = UserDefaults.standard.double(forKey: "phone.sensitivity")
        let scale = (sens > 0 ? sens : 10.0) / 36.0
        let modifiers = [NSEvent.ModifierFlags.shift, NSEvent.ModifierFlags.option]
        switch rotation {
        case .Clockwise(let r):
            accUp += Double(r) * scale
            let steps = Int(accUp); if steps > 0 { accUp -= Double(steps); HIDPostAuxKey(key: NX_KEYTYPE_SOUND_UP,   modifiers: modifiers, _repeat: steps) }
        case .CounterClockwise(let r):
            accDown += Double(r) * scale
            let steps = Int(accDown); if steps > 0 { accDown -= Double(steps); HIDPostAuxKey(key: NX_KEYTYPE_SOUND_DOWN, modifiers: modifiers, _repeat: steps) }
        }
    }
}
