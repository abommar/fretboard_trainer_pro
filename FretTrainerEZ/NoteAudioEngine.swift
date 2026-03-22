import AVFoundation

/// Synthesizes plucked guitar note tones using the Karplus-Strong algorithm.
/// All audio is generated in code — no audio asset files.
final class NoteAudioEngine {
    private let engine     = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format:    AVAudioFormat
    private let sampleRate: Double = 44100

    /// Open-string MIDI notes: index 0 = low E (E2=40) … index 5 = high E (E4=64)
    private let openStringMidi = [40, 45, 50, 55, 59, 64]

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        setupEngine()
    }

    /// Play the note at the given string/fret position.
    func play(string: Int, fret: Int) {
        guard string >= 0 && string < openStringMidi.count else { return }
        let midi      = openStringMidi[string] + fret
        let frequency = Float(440.0 * pow(2.0, Double(midi - 69) / 12.0))
        guard let buffer = makeKSBuffer(frequency: frequency) else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !playerNode.isPlaying { playerNode.play() }
    }

    // MARK: - Setup

    private func setupEngine() {
        // Mix with background audio (don't silence music player)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.7
        try? engine.start()
    }

    // MARK: - Karplus-Strong synthesis

    private func makeKSBuffer(frequency: Float) -> AVAudioPCMBuffer? {
        let sr         = Float(sampleRate)
        let ksLen      = max(2, Int(sr / frequency))   // delay line length
        let totalFrames = Int(sr * 1.5)                 // 1.5 s max sustain

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(totalFrames))
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(totalFrames)
        let out = buffer.floatChannelData![0]

        // Seed the delay line with white noise
        var ks = [Float](repeating: 0, count: ksLen)
        for i in 0..<ksLen { ks[i] = Float.random(in: -0.5...0.5) }

        // Average filter + gentle decay  (0.998 ≈ natural string damping)
        for i in 0..<totalFrames {
            let idx     =  i      % ksLen
            let nextIdx = (i + 1) % ksLen
            let v       = 0.5 * (ks[idx] + ks[nextIdx]) * 0.998
            ks[idx]     = v
            out[i]      = v
        }

        // Fade out last 10 % to eliminate end-of-buffer click
        let fadeStart = Int(Float(totalFrames) * 0.9)
        for i in fadeStart..<totalFrames {
            let t = Float(i - fadeStart) / Float(totalFrames - fadeStart)
            out[i] *= 1.0 - t
        }

        return buffer
    }
}
