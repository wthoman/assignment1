import AVFoundation
import Foundation

/// Every sound the app can make.
enum SoundEffect: String, CaseIterable, Identifiable {
    case complete, undo, reaction, send, unlock, unlockRare, reveal, pageTurn, groupGoal, error

    var id: String { rawValue }

    /// Optional bundled file name (without extension). Add `daybook_<name>.caf`/`.wav`/`.m4a`
    /// to the app target to replace the built-in synthesized sound.
    var fileName: String { "daybook_\(rawValue)" }

    var label: String {
        switch self {
        case .complete: "Complete a habit"
        case .undo: "Undo a completion"
        case .reaction: "Receive a reaction"
        case .send: "Send a reminder or reaction"
        case .unlock: "Unlock a sticker"
        case .unlockRare: "Unlock a rare sticker"
        case .reveal: "Reveal a superlative"
        case .pageTurn: "Advance a recap card"
        case .groupGoal: "Group goal reached"
        case .error: "Something went wrong"
        }
    }

    /// Relative loudness, so celebratory sounds don't overpower everyday ones.
    var gain: Float {
        switch self {
        case .pageTurn: 0.35
        case .undo, .send: 0.5
        case .error: 0.45
        case .complete, .reaction: 0.6
        case .unlock, .groupGoal: 0.7
        case .unlockRare, .reveal: 0.75
        }
    }
}

/// Plays short, soft UI sounds through AVFoundation.
///
/// Uses the `.ambient` audio session category, so sounds respect the Ring/Silent switch and
/// mix with music instead of interrupting it. If a bundled file is missing, a warm
/// marimba-like tone is synthesized in memory, so the app never depends on audio assets.
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let format: AVAudioFormat?
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var filePlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var isConfigured = false
    private var isBroken = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    }

    /// - Parameter volume: 0…1 user volume preference.
    func play(_ effect: SoundEffect, volume: Double) {
        guard volume > 0.01 else { return }
        if let player = filePlayer(for: effect) {
            player.volume = Float(volume) * effect.gain
            player.currentTime = 0
            player.play()
            return
        }
        guard configureIfNeeded(), let buffer = buffer(for: effect), !players.isEmpty else { return }
        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }
        let player = players[nextPlayer % players.count]
        nextPlayer += 1
        player.stop()
        player.volume = Float(volume) * effect.gain
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    /// Stop the engine when the app leaves the foreground; nothing plays in the background.
    func suspend() {
        players.forEach { $0.stop() }
        if engine.isRunning { engine.pause() }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: Setup

    private func configureIfNeeded() -> Bool {
        if isConfigured { return true }
        if isBroken { return false }
        guard let format else {
            isBroken = true
            return false
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // A session failure shouldn't stop playback attempts on simulators.
        }
        for _ in 0..<3 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }
        engine.mainMixerNode.outputVolume = 0.9
        engine.prepare()
        isConfigured = true
        return true
    }

    private func filePlayer(for effect: SoundEffect) -> AVAudioPlayer? {
        if let cached = filePlayers[effect] { return cached }
        for ext in ["caf", "wav", "m4a", "mp3", "aiff"] {
            if let url = Bundle.main.url(forResource: effect.fileName, withExtension: ext),
               let player = try? AVAudioPlayer(contentsOf: url) {
                try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                player.prepareToPlay()
                filePlayers[effect] = player
                return player
            }
        }
        return nil
    }

    private func buffer(for effect: SoundEffect) -> AVAudioPCMBuffer? {
        if let cached = buffers[effect] { return cached }
        guard let format, let buffer = ToneSynth.render(effect, format: format) else { return nil }
        buffers[effect] = buffer
        return buffer
    }
}

/// Tiny additive synthesizer for warm, short UI sounds.
enum ToneSynth {
    struct Note {
        let frequency: Double
        let start: Double
        let duration: Double
        let amplitude: Double
        var glideTo: Double? = nil
    }

    static func notes(for effect: SoundEffect) -> (notes: [Note], noise: (start: Double, duration: Double, amplitude: Double)?) {
        switch effect {
        case .complete:
            return ([Note(frequency: 659.25, start: 0, duration: 0.16, amplitude: 0.5),
                     Note(frequency: 987.77, start: 0.07, duration: 0.26, amplitude: 0.42)], nil)
        case .undo:
            return ([Note(frequency: 783.99, start: 0, duration: 0.12, amplitude: 0.35),
                     Note(frequency: 523.25, start: 0.06, duration: 0.18, amplitude: 0.3)], nil)
        case .reaction:
            return ([Note(frequency: 880, start: 0, duration: 0.3, amplitude: 0.38),
                     Note(frequency: 1318.5, start: 0.05, duration: 0.25, amplitude: 0.18)], nil)
        case .send:
            return ([Note(frequency: 520, start: 0, duration: 0.12, amplitude: 0.4, glideTo: 880)], nil)
        case .unlock:
            return ([Note(frequency: 523.25, start: 0, duration: 0.2, amplitude: 0.35),
                     Note(frequency: 659.25, start: 0.08, duration: 0.2, amplitude: 0.35),
                     Note(frequency: 783.99, start: 0.16, duration: 0.24, amplitude: 0.35),
                     Note(frequency: 1046.5, start: 0.24, duration: 0.4, amplitude: 0.32)], nil)
        case .unlockRare:
            return ([Note(frequency: 523.25, start: 0, duration: 0.2, amplitude: 0.32),
                     Note(frequency: 659.25, start: 0.08, duration: 0.2, amplitude: 0.32),
                     Note(frequency: 783.99, start: 0.16, duration: 0.2, amplitude: 0.32),
                     Note(frequency: 1046.5, start: 0.24, duration: 0.5, amplitude: 0.32),
                     Note(frequency: 1568, start: 0.36, duration: 0.35, amplitude: 0.16),
                     Note(frequency: 2093, start: 0.46, duration: 0.3, amplitude: 0.12)], nil)
        case .reveal:
            return ([Note(frequency: 196, start: 0, duration: 0.5, amplitude: 0.3),
                     Note(frequency: 261.63, start: 0.18, duration: 0.6, amplitude: 0.3),
                     Note(frequency: 329.63, start: 0.18, duration: 0.6, amplitude: 0.26),
                     Note(frequency: 392, start: 0.18, duration: 0.6, amplitude: 0.26),
                     Note(frequency: 523.25, start: 0.32, duration: 0.7, amplitude: 0.3)], nil)
        case .pageTurn:
            return ([], (0, 0.09, 0.35))
        case .groupGoal:
            return ([Note(frequency: 392, start: 0, duration: 0.18, amplitude: 0.32),
                     Note(frequency: 493.88, start: 0.09, duration: 0.18, amplitude: 0.32),
                     Note(frequency: 587.33, start: 0.18, duration: 0.18, amplitude: 0.32),
                     Note(frequency: 783.99, start: 0.27, duration: 0.5, amplitude: 0.34),
                     Note(frequency: 587.33, start: 0.27, duration: 0.5, amplitude: 0.2),
                     Note(frequency: 987.77, start: 0.42, duration: 0.45, amplitude: 0.2)], nil)
        case .error:
            return ([Note(frequency: 392, start: 0, duration: 0.14, amplitude: 0.3),
                     Note(frequency: 293.66, start: 0.1, duration: 0.22, amplitude: 0.3)], nil)
        }
    }

    static func render(_ effect: SoundEffect, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let (notes, noise) = notes(for: effect)
        let sampleRate = format.sampleRate
        let end = max(notes.map { $0.start + $0.duration }.max() ?? 0, noise.map { $0.start + $0.duration } ?? 0) + 0.05
        let frameCount = AVAudioFrameCount(end * sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount
        for i in 0..<Int(frameCount) { channel[i] = 0 }

        for note in notes {
            let startFrame = Int(note.start * sampleRate)
            let length = Int(note.duration * sampleRate)
            var phase = 0.0
            for i in 0..<length where startFrame + i < Int(frameCount) {
                let t = Double(i) / sampleRate
                let progress = Double(i) / Double(max(length, 1))
                let freq = note.glideTo.map { note.frequency + ($0 - note.frequency) * progress } ?? note.frequency
                phase += 2 * Double.pi * freq / sampleRate
                // Soft attack, exponential decay: a mallet on wood.
                let attack = min(1, t / 0.006)
                let decay = exp(-t / (note.duration * 0.32))
                let release = min(1, (note.duration - t) / 0.02)
                let envelope = attack * decay * max(0, release)
                let tone = sin(phase) + 0.28 * sin(2 * phase) * exp(-t * 18) + 0.08 * sin(3 * phase) * exp(-t * 30)
                channel[startFrame + i] += Float(tone * envelope * note.amplitude)
            }
        }

        if let noise {
            var generator = SeededGenerator(seed: 7)
            var last: Double = 0
            let startFrame = Int(noise.start * sampleRate)
            let length = Int(noise.duration * sampleRate)
            for i in 0..<length where startFrame + i < Int(frameCount) {
                let t = Double(i) / sampleRate
                let white = Double.random(in: -1...1, using: &generator)
                last = last * 0.82 + white * 0.18 // low-pass: soft paper flick, not hiss
                let envelope = min(1, t / 0.004) * exp(-t / (noise.duration * 0.35))
                channel[startFrame + i] += Float(last * envelope * noise.amplitude * 2.2)
            }
        }

        // Normalize gently so nothing clips.
        var peak: Float = 0
        for i in 0..<Int(frameCount) { peak = max(peak, abs(channel[i])) }
        if peak > 0.9 {
            let scale = 0.9 / peak
            for i in 0..<Int(frameCount) { channel[i] *= scale }
        }
        return buffer
    }
}
