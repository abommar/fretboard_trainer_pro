import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var isDrawerOpen = false
    @State private var activeScreen: AppScreen? = nil

    private let accent = Color(hex: "#E94560")
    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    private var highlightColor: Color {
        switch gameState.answerState {
        case .idle:    return accent
        case .correct: return .green
        case .wrong:   return .red
        }
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 500
            let hPad: CGFloat    = compact ? 4 : 8
            let btnH: CGFloat    = compact ? 34 : 44
            let fbH: CGFloat     = fretboardHeight(geo, compact: compact, btnH: btnH)

            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 16)
                    .padding(.top, hPad)
                    .padding(.bottom, compact ? 4 : 6)

                controlRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, compact ? 4 : 6)

                FretboardView(
                    fretboard: Fretboard(),
                    highlightString: gameState.currentString,
                    highlightFret: gameState.currentFret,
                    highlightColor: highlightColor
                )
                .frame(height: fbH)
                .clipped()

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, compact ? 3 : 5)

                promptText
                    .padding(.bottom, compact ? 3 : 5)

                NoteAnswerButtonsView(gameState: gameState, buttonHeight: btnH)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(bg.ignoresSafeArea())
        .overlay { if gameState.isTimeUp { timeUpOverlay } }
        .overlay {
            DrawerMenuView(isOpen: $isDrawerOpen) { screen in
                activeScreen = screen
            }
        }
        .fullScreenCover(item: $activeScreen) { screen in
            switch screen {
            case .circleOfFifths:  CircleOfFifthsView()
            case .chordCharts:     ChordChartsView()
            case .chromaticTuner:  ChromaticTunerView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func fretboardHeight(_ geo: GeometryProxy, compact: Bool, btnH: CGFloat) -> CGFloat {
        let headerH:  CGFloat = compact ? 38  : 48
        let controlH: CGFloat = compact ? 44  : 54
        let dividerH: CGFloat = compact ? 8   : 12
        let promptH:  CGFloat = compact ? 18  : 24
        let buttonsH: CGFloat = btnH * 2 + 8  // 2 rows + spacing
        let fixed = headerH + controlH + dividerH + promptH + buttonsH
        return min(max(geo.size.height - fixed, 120), 200)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            Button(action: { isDrawerOpen.toggle() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text("FretTrainerEZ")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Name That Note")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(accent)
            }
            Spacer()
            if !gameState.isTimedMode {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(gameState.correctCount)/\(gameState.totalCount)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("\(gameState.scorePercent)%")
                        .font(.system(size: 9))
                        .foregroundColor(scoreColor)
                }
                .padding(.trailing, 4)
            }
            Button("Reset") { gameState.reset() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).stroke(accent, lineWidth: 1.5))
        }
    }

    private var scoreColor: Color {
        let p = gameState.scorePercent
        if p >= 80 { return .green }
        if p >= 60 { return .yellow }
        return accent
    }

    // MARK: - Single Control Row

    private var controlRow: some View {
        HStack(spacing: 10) {
            // Left: Practice / Timed toggle — fixed width
            Picker("", selection: modeBinding) {
                Text("Practice").tag(false)
                Text("Timed").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
            .tint(accent)

            // Right: changes based on mode + timer state
            Group {
                if !gameState.isTimedMode {
                    difficultySlider
                } else if gameState.isTimerActive {
                    timerActiveCompact
                } else {
                    durationCompact
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 10).fill(cardBg))
        .animation(.easeInOut(duration: 0.15), value: gameState.isTimedMode)
        .animation(.easeInOut(duration: 0.15), value: gameState.isTimerActive)
    }

    private var modeBinding: Binding<Bool> {
        Binding(
            get: { gameState.isTimedMode },
            set: { newVal in
                guard newVal != gameState.isTimedMode else { return }
                gameState.isTimedMode = newVal
                if newVal { gameState.stopTimedGame() }
                else { gameState.stopTimedGame(); gameState.reset() }
            }
        )
    }

    // MARK: - Difficulty Slider (practice mode)

    private var difficultySlider: some View {
        VStack(spacing: 3) {
            HStack(spacing: 0) {
                Text("Beg").frame(maxWidth: .infinity, alignment: .leading)
                Text("Int").frame(maxWidth: .infinity, alignment: .center)
                Text("Adv").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.white.opacity(0.45))

            SnapSlider(
                value: Binding(
                    get: { Difficulty.allCases.firstIndex(of: gameState.difficulty)! },
                    set: { gameState.setDifficulty(Difficulty.allCases[$0]) }
                ),
                steps: 3
            )
        }
        .frame(maxWidth: 160)
    }

    // MARK: - Duration + Start (timed, not running)

    private var durationCompact: some View {
        HStack(spacing: 6) {
            Picker("", selection: durationBinding) {
                Text("30s").tag(30)
                Text("1m").tag(60)
                Text("2m").tag(120)
            }
            .pickerStyle(.segmented)
            .tint(accent)

            Button(action: { gameState.startTimedGame() }) {
                Text("Start")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(accent))
            }
            .buttonStyle(.plain)
        }
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { gameState.timerDuration },
            set: { gameState.timerDuration = $0; gameState.timeRemaining = $0 }
        )
    }

    // MARK: - Timer + Stop (timed, running)

    private var timerActiveCompact: some View {
        HStack(spacing: 6) {
            Text(timeString)
                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                .foregroundColor(gameState.timeRemaining <= 10 ? .red : .white)
                .animation(.easeInOut(duration: 0.2), value: gameState.timeRemaining <= 10)
            Spacer()
            Text("\(gameState.correctCount) ✓")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            Button(action: { gameState.stopTimedGame() }) {
                Text("Stop")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.9)))
            }
            .buttonStyle(.plain)
        }
    }

    private var timeString: String {
        let m = gameState.timeRemaining / 60
        let s = gameState.timeRemaining % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : "\(s)s"
    }

    // MARK: - Prompt

    @ViewBuilder
    private var promptText: some View {
        if gameState.isTimedMode && !gameState.isTimerActive && !gameState.isTimeUp {
            Text("Tap Start to begin")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        } else {
            Text("What note is highlighted?")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Time-up Overlay

    private var timeUpOverlay: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Time's Up!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                VStack(spacing: 4) {
                    Text("\(gameState.correctCount)")
                        .font(.system(size: 68, weight: .heavy, design: .monospaced))
                        .foregroundColor(accent)
                    Text("notes correct")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }
                Button(action: { gameState.startTimedGame() }) {
                    Text("Play Again")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
    }
}

// MARK: - Custom metallic snap slider

struct SnapSlider: View {
    @Binding var value: Int
    let steps: Int

    private let trackH:   CGFloat = 5
    private let thumbSize: CGFloat = 18

    private let trackFill = LinearGradient(
        colors: [Color(hex: "#111111"), Color(hex: "#333333"), Color(hex: "#111111")],
        startPoint: .top, endPoint: .bottom
    )
    private let activeFill = LinearGradient(
        colors: [Color(hex: "#D0D0D0"), Color(hex: "#888888")],
        startPoint: .top, endPoint: .bottom
    )
    private let thumbFill = LinearGradient(
        colors: [Color(hex: "#F0F0F0"), Color(hex: "#C0C0C0"), Color(hex: "#808080")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - thumbSize
            let stepW  = usable / CGFloat(steps - 1)
            let thumbX = CGFloat(value) * stepW

            ZStack(alignment: .leading) {
                // Inset groove (track background)
                Capsule()
                    .fill(trackFill)
                    .frame(height: trackH)
                    .overlay(Capsule().stroke(Color.black.opacity(0.6), lineWidth: 0.5))
                    .padding(.horizontal, thumbSize / 2)

                // Active fill (metallic silver)
                Capsule()
                    .fill(activeFill)
                    .frame(width: max(thumbSize / 2, thumbX + thumbSize / 2), height: trackH)
                    .padding(.leading, thumbSize / 2)
                    .clipped()

                // Metallic thumb
                Circle()
                    .fill(thumbFill)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        // Specular highlight
                        Circle()
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.65), .clear],
                                startPoint: .topLeading, endPoint: .center
                            ))
                    )
                    .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .offset(x: thumbX)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: value)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let pct     = (drag.location.x - thumbSize / 2) / usable
                        let snapped = Int((pct * CGFloat(steps - 1)).rounded())
                        value = max(0, min(steps - 1, snapped))
                    }
            )
        }
        .frame(height: thumbSize)
    }
}
