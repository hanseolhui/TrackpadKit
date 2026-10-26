import Foundation
import CMultitouch

/// One contact on the trackpad, as reported by MultitouchSupport.
public struct Touch: Sendable, Hashable {
    /// Stays the same from the moment the finger lands until it lifts.
    public let id: Int32
    /// Normalized position, 0…1 on both axes, origin at the bottom-left of the trackpad.
    public let x: Float, y: Float
    /// Normalized velocity.
    public let velocityX: Float, velocityY: Float
    /// Roughly contact area / pressure. Fingertip taps are ~0.8–1.5, a palm that only grazes the pad ~0.1–0.6.
    public let size: Float
    /// Contact ellipse. A fingertip is ~9–12.7 on the long axis, a palm or the base of the thumb ~15–27.
    public let majorAxis: Float, minorAxis: Float
    /// Ellipse angle in radians.
    public let angle: Float
    /// Raw state: 3 touch began, 4 touching, 5 and above lifting.
    public let state: Int32

    /// The finger is actually on the surface (state 3 or 4).
    public var isTouching: Bool { state == 3 || state == 4 }

    init(_ t: MTTouch) {
        id = Int32(t.identifier)
        x = t.normalized.position.x; y = t.normalized.position.y
        velocityX = t.normalized.velocity.x; velocityY = t.normalized.velocity.y
        size = t.size; majorAxis = t.majorAxis; minorAxis = t.minorAxis; angle = t.angle
        state = Int32(t.state)
    }
}

/// All touches on one trackpad at one moment.
public struct TouchFrame: @unchecked Sendable {
    /// Identifies the trackpad (built-in and Magic Trackpad report separately).
    public let device: UnsafeMutableRawPointer?
    public let touches: [Touch]
    /// Seconds, from the framework's monotonic clock.
    public let time: Double

    init(device: UnsafeMutableRawPointer?, touches: UnsafeMutablePointer<MTTouch>?, count: Int, time: Double) {
        self.device = device
        self.touches = touches.map { p in (0..<count).map { Touch(p[$0]) } } ?? []
        self.time = time
    }

    private static let lock = NSLock()
    private static var _handler: ((TouchFrame) -> Void)?
    static var handler: ((TouchFrame) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _handler }
        set { lock.lock(); _handler = newValue; lock.unlock() }
    }
}
