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

        // Gate on RMS level — ignore silence.
        // 0.004 is low enough to catch an acoustic or unplugged electric
        // yet still reject true silence / handling noise.
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(n))
        guard rms > 0.004 else { return nil }

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

    @ObservationIgnored private var audioEngine = AVAudioEngine()

    // Stability: note must appear this many consecutive frames before display updates.
    // 2 frames (~180ms at 4096/44100) balances stability with responsiveness for guitar.
    @ObservationIgnored private let confirmationFrames = 2
    @ObservationIgnored private var pendingNote: String = ""
    @ObservationIgnored private var pendingCount: Int = 0

    // Smoothing: exponential moving average on cents (α = 0.35 → slightly faster needle)
    @ObservationIgnored private let centsAlpha: Float = 0.35
    @ObservationIgnored private var smoothedCents: Float = 0

    // Hold: keep the last detected note on screen for a short window after signal drops,
    // so a decaying guitar note doesn't immediately blank out.
    @ObservationIgnored private var holdWorkItem: DispatchWorkItem?

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
                        self.holdWorkItem?.cancel()
                        self.holdWorkItem = nil
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
                    // Don't blank immediately — hold the last note for 0.8s so a
                    // decaying acoustic/electric note doesn't flicker out.
                    self.holdWorkItem?.cancel()
                    let work = DispatchWorkItem {
                        self.detectedNote = "--"
                        self.frequency = 0
                        self.centsOff = 0
                        self.smoothedCents = 0
                    }
                    self.holdWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
                }
            }
        }

        do {
            try audioEngine.start()
            isListening = true
        } catch {}
    }

    func stop() {
        guard isListening else { return }
        holdWorkItem?.cancel()
        holdWorkItem = nil
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
    @State private var selectedTuning: GuitarTuning = .standard

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")

    var body: some View {
        // GeometryReader as body root — same pattern as ScalesView.
        // This is the only reliable way to get true screen dimensions inside fullScreenCover.
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let topInset = geo.safeAreaInsets.top
            let compactLandscape = isLandscape && geo.size.height < 430
            ZStack {
                bg.ignoresSafeArea()
                if isLandscape {
                    landscapeBody(topInset: topInset, compact: compactLandscape)
                } else {
                    portraitBody(topInset: topInset)
                }
            }
        }
        .onDisappear { engine.stop() }
        .preferredColorScheme(.dark)
    }

    // MARK: - Portrait body

    private func portraitBody(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            navBar(topInset: topInset)
            Divider().background(Color.white.opacity(0.08))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    startStopButton.padding(.top, 8)
                    noteDisplay(fontSize: 72)
                    centsMeterCard.padding(.horizontal, 20)
                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 20)
                    stringReferenceRow.padding(.horizontal, 20)
                    tuningPicker.padding(.horizontal, 20).padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Landscape body

    private func landscapeBody(topInset: CGFloat, compact: Bool) -> some View {
        VStack(spacing: 0) {
            navBar(topInset: topInset)
            Divider().background(Color.white.opacity(0.08))
            HStack(spacing: 0) {
                // Left: tuning context
                VStack(spacing: 10) {
                    stringReferenceRow
                    tuningPicker
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider().background(Color.white.opacity(0.08))

                // Right: primary controls
                Group {
                    if compact {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 10) {
                                startStopButton
                                noteDisplay(fontSize: 58)
                                centsMeterCard
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 12) {
                            startStopButton.padding(.top, 4)
                            Spacer(minLength: 8)
                            noteDisplay(fontSize: 72)
                            Spacer(minLength: 8)
                            centsMeterCard.padding(.bottom, 8)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Nav bar

    private func navBar(topInset: CGFloat) -> some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accent)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Chromatic Tuner")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, topInset)
        .padding(.vertical, 12)
        .background(cardBg)
    }

    // MARK: - Tuning Picker

    private var tuningPicker: some View {
        VStack(spacing: 2) {
            Text("TUNING")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Tuning", selection: $selectedTuning) {
                ForEach(GuitarTuning.all) { tuning in
                    Text(tuning.name)
                        .font(.system(size: 15, weight: .medium))
                        .tag(tuning)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 90)
            .clipped()
        }
    }

    // MARK: - String Reference Row

    private var stringReferenceRow: some View {
        HStack(spacing: 3) {
            ForEach(0..<6) { idx in
                let stringNum  = 6 - idx
                let target     = selectedTuning.strings[idx]
                let stdNote    = GuitarTuning.standard.strings[idx]
                let targetName = target.displayName(useFlats: selectedTuning.useFlats)
                let stdName    = stdNote.sharpName
                let active     = isActiveString(idx)
                let changed    = target != stdNote

                VStack(spacing: 2) {
                    Text("\(stringNum)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    Text(targetName)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(active ? noteColor : .white)
                    Text(changed ? "(\(stdName))" : " ")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(active ? Color.white.opacity(0.08) : Color.clear))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardBg))
    }

    // MARK: - Note Display

    private func noteDisplay(fontSize: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(engine.detectedNote)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundColor(engine.isListening && engine.detectedNote != "--" ? noteColor : .white.opacity(0.5))
                .animation(.easeInOut(duration: 0.1), value: engine.detectedNote)

            Text(engine.frequency > 0 ? String(format: "%.1f Hz", engine.frequency) : "–")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    // MARK: - Cents Meter Card

    private var centsMeterCard: some View {
        VStack(spacing: 8) {
            CentsMeterView(cents: engine.centsOff, active: engine.isListening && engine.detectedNote != "--")
                .frame(height: 36)
                .padding(.horizontal, 4)

            Text(centsLabel)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(engine.isListening && engine.detectedNote != "--" ? noteColor : .white.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardBg))
    }

    // MARK: - Start/Stop Button

    private var startStopButton: some View {
        Button(action: toggleListening) {
            HStack(spacing: 8) {
                Image(systemName: engine.isListening ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 14))
                Text(engine.isListening ? "Stop" : "Start Tuner")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 36)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(engine.isListening ? Color.gray.opacity(0.35) : accent))
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func isActiveString(_ idx: Int) -> Bool {
        guard engine.isListening, engine.detectedNote != "--" else { return false }
        return selectedTuning.strings[idx].sharpName == engine.detectedNote
    }

    private var noteColor: Color {
        let a = abs(engine.centsOff)
        if a < 5  { return .green }
        if a < 20 { return .yellow }
        return accent
    }

    private var centsLabel: String {
        guard engine.isListening && engine.detectedNote != "--" else { return "Tap Start to listen" }
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
