import Foundation

/// Tells palms from fingers using the contact ellipse and size.
///
/// Thresholds come from measurements on MacBook built-in trackpads:
///
/// | Contact                         | majorAxis | size     |
/// |---------------------------------|-----------|----------|
/// | Fingertip tap                   | 11–12     | 1.3–1.5  |
/// | Finger moving the pointer       | 9–10      | 0.8–1.1  |
/// | Finger sliding along the edge   | ~14       | ~1.1     |
/// | Palm / base of the thumb        | 15–27     | any      |
/// | Palm that only grazes the pad   | 13–15     | 0.1–0.6  |
///
/// A touch is a palm if `majorAxis >= major`, or if `majorAxis >= grazeMajor` and `size < grazeMaxSize`.
/// Once a touch ID is classified as a palm it stays a palm until it lifts (palms often land on their
/// edge and look finger-sized for the first frame or two).
public final class PalmFilter {
    public struct Thresholds: Sendable, Equatable {
        public var major: Float
        public var grazeMajor: Float
        public var grazeMaxSize: Float
        public init(major: Float, grazeMajor: Float, grazeMaxSize: Float = 0.7) {
            self.major = major; self.grazeMajor = grazeMajor; self.grazeMaxSize = grazeMaxSize
        }
        /// Fewer false palms — for large hands or fingertips that get rejected.
        public static let gentle = Thresholds(major: 17, grazeMajor: 14.5)
        public static let normal = Thresholds(major: 15, grazeMajor: 13)
        /// More aggressive — for people whose palms touch the pad a lot while typing.
        public static let strong = Thresholds(major: 13.5, grazeMajor: 12)

        /// Calibrate from one person's hand: the largest fingertip majorAxis and the smallest palm majorAxis you measured.
        public static func fitted(fingerMax: Float, palmMin: Float) -> Thresholds {
            let mid = (fingerMax + palmMin) / 2
            return Thresholds(major: max(mid, fingerMax + 0.8), grazeMajor: max(fingerMax + 0.3, mid - 1.5))
        }
    }

    public var thresholds: Thresholds
    private var palms: Set<Int32> = []

    public init(_ thresholds: Thresholds = .normal) { self.thresholds = thresholds }

    /// Is this single contact palm-shaped (ignoring history)?
    public func looksLikePalm(_ t: Touch) -> Bool {
        t.majorAxis >= thresholds.major || (t.majorAxis >= thresholds.grazeMajor && t.size < thresholds.grazeMaxSize)
    }

    /// Feed every frame in order. Returns only the fingers, and whether a touch became a palm in this frame
    /// (if so, you probably want to cancel whatever gesture those fingers were part of).
    public func filter(_ frame: TouchFrame) -> (fingers: [Touch], newPalm: Bool) {
        let alive = Set(frame.touches.filter(\.isTouching).map(\.id))
        palms.formIntersection(alive)
        var newPalm = false
        var fingers: [Touch] = []
        for t in frame.touches where t.isTouching {
            if !palms.contains(t.id), looksLikePalm(t) { palms.insert(t.id); newPalm = true }
            if !palms.contains(t.id) { fingers.append(t) }
        }
        return (fingers, newPalm)
    }

    public func reset() { palms = [] }
}
