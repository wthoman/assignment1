import CoreHaptics
import UIKit

/// Named haptic moments. Haptics are meaningful, not attached to every tap.
enum HapticEvent {
    case selection
    case cardPress
    case success
    case undo
    case reactionReceived
    case warning
    case error
    case unlock(Rarity)
    case awardReveal
    case groupCelebration
}

/// Centralized haptics. Uses UIKit feedback generators for everyday moments and Core Haptics
/// for richer celebration patterns when the hardware supports it. Every path degrades to a
/// no-op on the simulator or unsupported devices.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var engine: CHHapticEngine?
    private let supportsCoreHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() {}

    /// - Parameters:
    ///   - reduced: scale intensity down (Settings → Haptics → Reduced intensity).
    ///   - celebrations: allow the richer Core Haptics patterns.
    func play(_ event: HapticEvent, reduced: Bool, celebrations: Bool) {
        let scale: CGFloat = reduced ? 0.55 : 1
        switch event {
        case .selection:
            selectionGenerator.selectionChanged()
        case .cardPress:
            softImpact.impactOccurred(intensity: 0.6 * scale)
        case .success:
            if reduced { mediumImpact.impactOccurred(intensity: 0.6) } else { notificationGenerator.notificationOccurred(.success) }
        case .undo:
            lightImpact.impactOccurred(intensity: 0.5 * scale)
        case .reactionReceived:
            if reduced { lightImpact.impactOccurred(intensity: 0.5) } else { notificationGenerator.notificationOccurred(.success) }
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .unlock(let rarity):
            if rarity >= .rare, celebrations, playPattern(Self.celebrationPattern(rarity: rarity), scale: Float(scale)) { return }
            notificationGenerator.notificationOccurred(.success)
        case .awardReveal:
            if celebrations, playPattern(Self.awardShowPattern, scale: Float(scale)) { return }
            mediumImpact.impactOccurred(intensity: scale)
        case .groupCelebration:
            if celebrations, playPattern(Self.groupPattern, scale: Float(scale)) { return }
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Warm up generators before an expected interaction (e.g. when a habit card appears).
    func prepare() {
        selectionGenerator.prepare()
        softImpact.prepare()
        notificationGenerator.prepare()
    }

    // MARK: Core Haptics

    private func ensureEngine() -> CHHapticEngine? {
        guard supportsCoreHaptics else { return nil }
        if let engine { return engine }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak engine] in
                try? engine?.start()
            }
            try engine.start()
            self.engine = engine
            return engine
        } catch {
            return nil
        }
    }

    /// Returns false if the pattern could not be played (caller falls back to UIKit feedback).
    private func playPattern(_ events: [CHHapticEvent], scale: Float) -> Bool {
        guard let engine = ensureEngine() else { return false }
        do {
            let scaled = events.map { event -> CHHapticEvent in
                let params = event.eventParameters.map { param in
                    param.parameterID == .hapticIntensity
                        ? CHHapticEventParameter(parameterID: .hapticIntensity, value: param.value * scale)
                        : param
                }
                return CHHapticEvent(eventType: event.type, parameters: params, relativeTime: event.relativeTime, duration: event.duration)
            }
            let pattern = try CHHapticPattern(events: scaled, parameters: [])
            try engine.start()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            return false
        }
    }

    private static func tap(_ time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time)
    }

    private static func swell(_ time: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time, duration: duration)
    }

    /// Rising taps ending in a warm swell. Legendary adds a final sparkle.
    static func celebrationPattern(rarity: Rarity) -> [CHHapticEvent] {
        var events = [
            tap(0, intensity: 0.45, sharpness: 0.4),
            tap(0.08, intensity: 0.6, sharpness: 0.5),
            tap(0.16, intensity: 0.8, sharpness: 0.6),
            swell(0.24, duration: 0.3, intensity: 0.55, sharpness: 0.2),
            tap(0.26, intensity: 1, sharpness: 0.7),
        ]
        if rarity == .legendary {
            events += [tap(0.62, intensity: 0.5, sharpness: 0.9), tap(0.7, intensity: 0.4, sharpness: 0.95), tap(0.78, intensity: 0.3, sharpness: 1)]
        }
        return events
    }

    /// Drumroll, pause, big hit: the award-show reveal.
    static let awardShowPattern: [CHHapticEvent] = {
        var events: [CHHapticEvent] = []
        for i in 0..<9 {
            events.append(tap(Double(i) * 0.055, intensity: 0.3 + Float(i) * 0.05, sharpness: 0.3))
        }
        events.append(tap(0.62, intensity: 1, sharpness: 0.6))
        events.append(swell(0.62, duration: 0.35, intensity: 0.6, sharpness: 0.15))
        return events
    }()

    /// Three gentle double-taps, like friends high-fiving down a line.
    static let groupPattern: [CHHapticEvent] = [
        tap(0, intensity: 0.5, sharpness: 0.35), tap(0.07, intensity: 0.7, sharpness: 0.45),
        tap(0.3, intensity: 0.55, sharpness: 0.35), tap(0.37, intensity: 0.75, sharpness: 0.45),
        tap(0.6, intensity: 0.6, sharpness: 0.35), tap(0.67, intensity: 0.9, sharpness: 0.5),
        swell(0.67, duration: 0.4, intensity: 0.45, sharpness: 0.15),
    ]
}
