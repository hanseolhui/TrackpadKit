// trackpad-demo — prints what TrackpadKit sees on your trackpad.
//
//   swift run trackpad-demo            # gestures
//   swift run trackpad-demo --touches  # raw touches, palms marked
//
// Try: rest your middle finger and tap with your index (tipTapLeft),
// tap with three fingers, tap a corner, or slide along the right edge.
import Foundation
import TrackpadKit

setvbuf(stdout, nil, _IOLBF, 0)   // print each line right away

guard let trackpads = Multitouch() else {
    print("Couldn't load MultitouchSupport.framework")
    exit(1)
}

if CommandLine.arguments.contains("--touches") {
    let palms = PalmFilter()
    var last = 0.0
    trackpads.onTouches = { frame in
        guard frame.time - last > 0.1 else { return }   // ~10 lines a second
        last = frame.time
        let (fingers, _) = palms.filter(frame)
        let ids = Set(fingers.map(\.id))
        let line = frame.touches.filter(\.isTouching).map { t in
            String(format: "%@ #%d (%.2f, %.2f) major %.1f size %.2f", ids.contains(t.id) ? "☝️" : "🖐", t.id, t.x, t.y, t.majorAxis, t.size)
        }.joined(separator: "   ")
        if !line.isEmpty { print(line) }
    }
} else {
    GestureDetector.sliders = [.left, .right]
    trackpads.onEvent = { event in
        switch event {
        case .gesture(let g):           print("👆", g.rawValue)
        case .slider(let side, let up): print("🎚", side.rawValue, up ? "▲" : "▼")
        }
    }
}
trackpads.restart()
trackpads.watchDevices()
print("Listening on \(trackpads.deviceCount) trackpad(s). Press Ctrl-C to quit.")
RunLoop.main.run()
