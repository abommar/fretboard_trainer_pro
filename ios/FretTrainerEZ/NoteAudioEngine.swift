import AVFoundation

/// Synthesizes plucked guitar note tones using extended Karplus-Strong synthesis.
/// All audio is generated in code — no audio asset files.
final class NoteAudioEngine {
    private let engine:      AVAudioEngine
    private let stringNodes: [AVAudioPlayerNode]   // one node per string → strum rings out naturally
    private let format:      AVAudioFormat
    private let sampleRate:  Double = 44100

    /// Open-string MIDI notes: index 0 = low E (E2=40) … index 5 = high E (E4=64)
    private let openStringMidi = [40, 45, 50, 55, 59, 64]

    init() {
        engine      = AVAudioEngine()
        format      = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        stringNodes = (0..<6).map { _ in AVAudioPlayerNode() }
        setupEngine()
    }

    /// Play the note at the given string/fret position.
    func play(string: Int, fret: Int) {
        guard string >= 0 && string < openStringMidi.count else { return }
        ensureRunning()
        let midi      = openStringMidi[string] + fret
        let frequency = Float(440.0 * pow(2.0, Double(midi - 69) / 12.0))
        guard let buffer = makeKSBuffer(frequency: frequency, string: string) else { return }
        let node = stringNodes[string]
        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !node.isPlaying { node.play() }
    }

    // MARK: - Setup

    private func setupEngine() {
        for node in stringNodes {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.7
    }

    /// True if the engine failed to start — callers can check this to show a UI warning.
    private(set) var audioUnavailable: Bool = false

    private func ensureRunning() {
        if engine.isRunning { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            audioUnavailable = false
        } catch {
            audioUnavailable = true
        }
    }

    // MARK: - Extended Karplus-Strong synthesis

    private func makeKSBuffer(frequency: Float, string: Int) -> AVAudioPCMBuffer? {
        let sr    = Float(sampleRate)
        let ksLen = max(2, Int(sr / frequency))   // delay line length = one period

        // Lower strings sustain longer than higher strings
        let sustainSecs = 1.8 - Double(string) * 0.12   // 1.80 s (low E) → 1.08 s (high E)
        let totalFrames = Int(sr * Float(sustainSecs))

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(totalFrames))
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(totalFrames)
        let out = buffer.floatChannelData![0]

        // Per-string timbre parameters
        // t = 0 → low E (warm, slow decay)   t = 1 → high E (bright, faster decay)
        let t: Float  = Float(string) / 5.0
        let blend     = 0.500 - t * 0.055    // filter coefficient: 0.500 (dark) → 0.445 (bright)
        let decay     = 0.9992 - t * 0.0025  // loop gain:  0.9992 (low E) → 0.9967 (high E)
        let bodyMix   = 0.28   - t * 0.12    // body warmth: more on bass strings

        // --- Seed delay line with pick-position-filtered noise ---
        // Picking 1/8 of the way along the string zeros harmonics 8, 16, 24 …
        // This creates the characteristic nasal "plucked" brightness notch.
        let pickPos = max(1, ksLen / 8)
        var raw = [Float](repeating: 0, count: ksLen)
        for i in 0..<ksLen { raw[i] = Float.random(in: -1.0...1.0) }

        var ks = [Float](repeating: 0, count: ksLen)
        for i in 0..<ksLen {
            let j  = (i + ksLen - pickPos) % ksLen
            ks[i]  = raw[i] - raw[j]
        }

        // Normalise seed to ±0.5
        if let peak = ks.map({ abs($0) }).max(), peak > 0 {
            for i in 0..<ksLen { ks[i] = ks[i] / peak * 0.5 }
        }

        // --- Short pick-click transient (≈ 2 ms shaped noise) ---
        let attackLen = max(1, Int(sr * 0.002))
        for i in 0..<attackLen {
            let env  = 1.0 - Float(i) / Float(attackLen)
            out[i]   = Float.random(in: -1.0...1.0) * env * env * 0.25
        }

        // --- Karplus-Strong loop ---
        var bodyState: Float = 0.0
        for i in 0..<totalFrames {
            let idx     = i      % ksLen
            let nextIdx = (i + 1) % ksLen
            let v       = (blend * ks[idx] + (1.0 - blend) * ks[nextIdx]) * decay
            ks[idx]     = v

            // One-pole body-warmth filter (subtle low-shelf resonance)
            bodyState = bodyState * 0.96 + v * 0.04
            let sample = v + bodyState * bodyMix

            if i < attackLen {
                out[i] += sample * 0.85   // blend KS tone into the attack click
            } else {
                out[i]  = sample
            }
        }

        // --- Peak-normalise to 0.75 ---
        var maxSample: Float = 0.0
        for i in 0..<totalFrames { if abs(out[i]) > maxSample { maxSample = abs(out[i]) } }
        if maxSample > 0 {
            let scale = min(0.75 / maxSample, 2.0)
            for i in 0..<totalFrames { out[i] *= scale }
        }

        // --- Fade out last 10 % to eliminate end-of-buffer click ---
        let fadeStart = Int(Float(totalFrames) * 0.9)
        for i in fadeStart..<totalFrames {
            let fade = Float(i - fadeStart) / Float(totalFrames - fadeStart)
            out[i]  *= 1.0 - fade
        }

        return buffer
    }
}
