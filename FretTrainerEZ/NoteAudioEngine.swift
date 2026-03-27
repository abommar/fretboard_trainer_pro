import AVFoundation

/// Plucked-string audio synthesis using the Karplus-Strong algorithm.
/// Call play(string:fret:) to synthesize and schedule a note.
/// The audio session uses .ambient so it mixes with background music.
final class NoteAudioEngine {

    private let engine   = AVAudioEngine()
    private let player   = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    // MIDI note numbers for open strings: low E → high E
    private let openStringMIDI = [40, 45, 50, 55, 59, 64]

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? engine.start()
    }

    /// Synthesize and play the note at (string, fret).
    func play(string: Int, fret: Int) {
        guard string >= 0, string < openStringMIDI.count else { return }
        let midi = openStringMIDI[string] + fret
        synthesize(midi: midi)
    }

    /// Synthesize and play a note by MIDI note number directly.
    func playMIDI(_ midi: Int) {
        synthesize(midi: midi)
    }

    // MARK: - Karplus-Strong Synthesis

    private func synthesize(midi: Int) {
        let frequency  = midiToFrequency(midi)
        let bufferSize = AVAudioFrameCount(sampleRate * 1.5) // 1.5s of audio
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }

        buffer.frameLength = bufferSize
        let samples = buffer.floatChannelData![0]
        let period  = Int(sampleRate / frequency)

        // Seed the delay line with white noise
        var delayLine = (0..<period).map { _ in Float.random(in: -1.0...1.0) }

        // Fill the buffer using the Karplus-Strong update rule
        let fadeStart = Int(Double(bufferSize) * 0.9)
        for i in 0..<Int(bufferSize) {
            let idx = i % period
            let next = (idx + 1) % period
            let sample = 0.996 * 0.5 * (delayLine[idx] + delayLine[next])
            delayLine[idx] = sample

            // Fade out the last 10% to avoid click at buffer end
            let fade: Float = i < fadeStart ? 1.0 :
                Float(Int(bufferSize) - i) / Float(Int(bufferSize) - fadeStart)
            samples[i] = sample * fade
        }

        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    private func midiToFrequency(_ midi: Int) -> Double {
        440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }
}
