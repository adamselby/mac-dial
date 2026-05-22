
import Foundation
import AppKit

// https://stackoverflow.com/a/55854051
func HIDPostAuxKey(key: Int32, modifiers: [NSEvent.ModifierFlags], _repeat: Int = 1) {
    func doKey(down: Bool) {
        var rawFlags: UInt = (down ? 0xa00 : 0xb00)
        for modifier in modifiers { rawFlags |= modifier.rawValue }
        let flags = NSEvent.ModifierFlags(rawValue: rawFlags)
        let data1 = Int((key<<16) | (down ? 0xa00 : 0xb00))
        let ev = NSEvent.otherEvent(with: NSEvent.EventType.systemDefined,
                                    location: NSPoint(x:0,y:0),
                                    modifierFlags: flags,
                                    timestamp: 0,
                                    windowNumber: 0,
                                    context: nil,
                                    subtype: 8,
                                    data1: data1,
                                    data2: -1)
        let cev = ev?.cgEvent
        cev?.post(tap: CGEventTapLocation.cghidEventTap)
    }
    for _ in 0..<_repeat { doKey(down: true); doKey(down: false) }
}

class PlaybackController: Controller {

    private let press = ButtonPressHandler(
        singleKey: "playback.press.single", defaultSingle: .playPause,
        doubleKey:  "playback.press.double", defaultDouble: .nextTrack
    )
    private var accUp:   Double = 0
    private var accDown: Double = 0

    func onDown() { press.onDown() }
    func onUp()   { press.onUp() }

    func onRotate(_ rotation: Dial.Rotation, _ scrollDirection: Int) {
        let sens  = UserDefaults.standard.double(forKey: "playback.sensitivity")
        let scale = (sens >= 10 ? sens : 10.0) / 36.0
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
