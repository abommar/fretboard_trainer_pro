import SwiftUI
import AVFoundation

// MARK: - Pure pitch detection (testable, no AVFoundation dependency)

struct PitchDetector {
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    struct NoteInfo {
        let note: String
        let cents: Float
    }

    /// Detects the fundamental frequency from a buffer of audio samples using autocorrelation.
    /// Returns nil if the signal is too quiet or no clear pitch is found.
    static func detectPitch(samples: [Float], sampleRate: Float) -> Float? {
        let n = samples.count

        // Gate on RMS level — ignore silence
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(n))
        guard rms > 0.02 else { return nil }

        // Apply Hann window
        var windowed = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let w = 0.5 * (1 - cos(2 * Float.pi * Float(i) / Float(n - 1)))
            windowed[i] = samples[i] * w
        }

        // Lag range: 50 Hz – 2000 Hz
        let minLag = Int(sampleRate / 2000)
        let maxLag = min(Int(sampleRate / 50), n - 1)
        guard minLag < maxLag else { return nil }

        // Compute normalized ACF for every candidate lag up front.
        // Normalizing by (n - lag) removes the length bias that would otherwise
        // make small lags dominate over low-frequency fundamentals.
        var nacf = [Float](repeating: 0, count: maxLag + 2)
        for lag in max(0, minLag - 1)...(maxLag + 1) {
            var sum: Float = 0
            for i in 0..<(n - lag) { sum += windowed[i] * windowed[i + lag] }
            nacf[lag] = sum / Float(n - lag)
        }

        // McLeod "first significant peak": pick the first local maximum whose
        // value exceeds 85 % of the global maximum. This avoids locking onto
        // a sub-harmonic (2× period) when the fundamental and its octave score
        // nearly the same raw correlation.
        let globalMax = nacf[minLag...maxLag].max() ?? 1
        guard globalMax > 0 else { return nil }
        let threshold = globalMax * 0.85

        var bestLag = -1
        var bestVal: Float = -.infinity
        for lag in (minLag + 1)..<maxLag {
            if nacf[lag] > nacf[lag - 1] && nacf[lag] >= nacf[lag + 1] && nacf[lag] >= threshold {
                bestLag = lag
                bestVal = nacf[lag]
                break
            }
        }
        // Fall back to global maximum if no clear peak found
        if bestLag == -1 {
            bestLag = (minLag...maxLag).max(by: { nacf[$0] < nacf[$1] }) ?? minLag
            bestVal = nacf[bestLag]
        }

        guard bestVal > 0 else { return nil }

        // Parabolic interpolation for sub-sample accuracy
        let y1 = nacf[max(0, bestLag - 1)]
        let y2 = bestVal
        let y3 = nacf[min(maxLag + 1, bestLag + 1)]
        let denom = 2 * (2 * y2 - y1 - y3)
        let refined = denom != 0 ? Float(bestLag) + (y1 - y3) / denom : Float(bestLag)

        guard refined > 0 else { return nil }
        return sampleRate / refined
    }

    /// Maps a frequency to its nearest note name and cents deviation.
    /// Returns nil for invalid (non-positive, non-finite) input.
    static func noteInfo(frequency: Float) -> NoteInfo? {
        guard frequency > 0 else { return nil }
        let midiFloat = 69 + 12 * log2(frequency / 440)
        guard midiFloat.isFinite else { return nil }
        let midiRounded = Int(midiFloat.rounded())
        let cents = (midiFloat - Float(midiRounded)) * 100
        let note = noteNames[((midiRounded % 12) + 12) % 12]
        return NoteInfo(note: note, cents: cents)
    }

    // kept for parabolic interpolation in legacy call sites
    private static func acf(_ samples: [Float], lag: Int, n: Int) -> Float {
        guard lag >= 0, lag < n else { return 0 }
        var sum: Float = 0
        for i in 0..<(n - lag) { sum += samples[i] * samples[i + lag] }
        return sum
    }
}

// MARK: - Tuner Engine

@Observable
final class TunerEngine {
    var detectedNote: String = "--"
    var centsOff: Float = 0
    var frequency: Float = 0
    var isListening: Bool = false

    private var audioEngine = AVAudioEngine()

    // Stability: note must appear this many consecutive frames before display updates
    private let confirmationFrames = 3
    private var pendingNote: String = ""
    private var pendingCount: Int = 0

    // Smoothing: exponential moving average on cents (α = 0.25 → slow/stable needle)
    private let centsAlpha: Float = 0.25
    private var smoothedCents: Float = 0

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .mixWithOthers)
            try session.setActive(true)
        } catch { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let sampleRate = Float(format.sampleRate)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData, count: count))

            if let freq = PitchDetector.detectPitch(samples: samples, sampleRate: sampleRate),
               let info = PitchDetector.noteInfo(frequency: freq) {
                DispatchQueue.main.async {
                    // Note confirmation: only commit to a new note after it appears
                    // in several consecutive frames, preventing single-frame blips.
                    if info.note == self.pendingNote {
                        self.pendingCount += 1
                    } else {
                        self.pendingNote = info.note
                        self.pendingCount = 1
                    }

                    if self.pendingCount >= self.confirmationFrames {
                        self.detectedNote = info.note
                        self.frequency = freq
                    }

                    // Smooth the cents needle with an exponential moving average.
                    // Reset smoothing when the confirmed note changes so the needle
                    // jumps immediately to the new position rather than crawling.
                    if self.detectedNote != info.note {
                        self.smoothedCents = info.cents
                    } else {
                        self.smoothedCents = self.centsAlpha * info.cents
                                           + (1 - self.centsAlpha) * self.smoothedCents
                    }
                    self.centsOff = self.smoothedCents
                }
            } else {
                DispatchQueue.main.async {
                    self.pendingNote = ""
                    self.pendingCount = 0
                    self.detectedNote = "--"
                    self.frequency = 0
                    self.centsOff = 0
                    self.smoothedCents = 0
                }
            }
        }

        do {
            try audioEngine.start()
            isListening = true
        } catch {}
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isListening = false
        detectedNote = "--"
        centsOff = 0
        frequency = 0
        pendingNote = ""
        pendingCount = 0
        smoothedCents = 0
    }
}

// MARK: - Cents Meter

struct CentsMeterView: View {
    let cents: Float   // -50…+50
    let active: Bool

    private let accent = Color(hex: "#E94560")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let midX = w / 2

            ZStack {
                // Track background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 10)
                    .padding(.horizontal, 2)
                    .frame(maxHeight: .infinity, alignment: .center)

                // Colored zone overlays
                Canvas { ctx, size in
                    let trackH: CGFloat = 10
                    let trackY = size.height / 2 - trackH / 2

                    func xForCents(_ c: Float) -> CGFloat {
                        midX + CGFloat(c) / 50 * (w / 2 - 4)
                    }

                    // Green center zone (±5 cents)
                    let greenRect = CGRect(
                        x: xForCents(-5), y: trackY,
                        width: xForCents(5) - xForCents(-5), height: trackH
                    )
                    ctx.fill(Path(roundedRect: greenRect, cornerRadius: 3), with: .color(.green.opacity(0.35)))

                    // Tick marks: -50, -25, 0, +25, +50
                    for c in [-50, -25, 0, 25, 50] {
                        let x = xForCents(Float(c))
                        let tickH: CGFloat = c == 0 ? 20 : 12
                        let tickPath = Path { p in
                            p.move(to: CGPoint(x: x, y: size.height / 2 - tickH / 2))
                            p.addLine(to: CGPoint(x: x, y: size.height / 2 + tickH / 2))
                        }
                        ctx.stroke(tickPath, with: .color(.white.opacity(c == 0 ? 0.5 : 0.2)), lineWidth: 1)
                    }
                }

                // Needle
                if active {
                    let clamped = max(-50, min(50, cents))
                    let fraction = CGFloat(clamped) / 50   // -1…+1
                    let needleX = midX + fraction * (w / 2 - 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(needleColor)
                        .frame(width: 3, height: h * 0.65)
                        .shadow(color: needleColor.opacity(0.6), radius: 4)
                        .position(x: needleX, y: h / 2)
                        .animation(.easeOut(duration: 0.08), value: clamped)
                }
            }
        }
    }

    private var needleColor: Color {
        let a = abs(cents)
        if a < 5  { return .green }
        if a < 20 { return .yellow }
        return accent
    }
}

// MARK: - Main View

struct ChromaticTunerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var engine = TunerEngine()

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { engine.stop(); dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Chromatic Tuner")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 34, height: 34)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 24)

                Spacer()

                // Note name
                Text(engine.detectedNote)
                    .font(.system(size: 100, weight: .heavy, design: .rounded))
                    .foregroundColor(noteColor)
                    .frame(height: 115)
                    .animation(.easeInOut(duration: 0.1), value: engine.detectedNote)

                // Frequency
                Text(engine.frequency > 0 ? String(format: "%.1f Hz", engine.frequency) : " ")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 36)

                // Cents meter card
                VStack(spacing: 12) {
                    CentsMeterView(cents: engine.centsOff, active: engine.isListening && engine.detectedNote != "--")
                        .frame(height: 44)
                        .padding(.horizontal, 4)

                    Text(centsLabel)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(noteColor.opacity(0.85))
                        .frame(height: 16)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
                .padding(.horizontal, 28)

                Spacer()

                // Standard tuning reference
                HStack(spacing: 0) {
                    ForEach(["E2", "A2", "D3", "G3", "B3", "E4"], id: \.self) { name in
                        Text(name)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

                // Start / Stop button
                Button(action: toggleListening) {
                    HStack(spacing: 8) {
                        Image(systemName: engine.isListening ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 14))
                        Text(engine.isListening ? "Stop" : "Start Tuner")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(engine.isListening ? Color.gray.opacity(0.4) : accent)
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 52)
            }
        }
        .onDisappear { engine.stop() }
        .preferredColorScheme(.dark)
    }

    // MARK: Helpers

    private var noteColor: Color {
        guard engine.isListening && engine.detectedNote != "--" else {
            return .white.opacity(0.25)
        }
        let a = abs(engine.centsOff)
        if a < 5  { return .green }
        if a < 20 { return .yellow }
        return accent
    }

    private var centsLabel: String {
        guard engine.isListening && engine.detectedNote != "--" else { return " " }
        let c = engine.centsOff
        if abs(c) < 2 { return "In Tune" }
        return c > 0 ? String(format: "+%.0f cents (sharp)", c) : String(format: "%.0f cents (flat)", c)
    }

    private func toggleListening() {
        if engine.isListening {
            engine.stop()
        } else {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { self.engine.start() }
                }
            }
        }
    }
}
