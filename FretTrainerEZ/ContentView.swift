import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var isDrawerOpen = false
    @State private var activeScreen: AppScreen? = nil
    @State private var isStudyMode = false
    @State private var studyHighlightNote: Note? = nil
    @State private var audioEngine = NoteAudioEngine()
    @AppStorage("fretboardStyle") private var fretboardStyleRaw: String = FretboardStyle.rosewood.rawValue
    @AppStorage("useFlats") private var useFlats: Bool = false
    @AppStorage("soundEnabled") private var soundEnabled: Bool = false
    @AppStorage("tipsEnabled")  private var tipsEnabled: Bool  = true
    @State private var memoryFlashProgress: CGFloat = 1.0

    private let fretboard = Fretboard()

    private var fretboardStyle: FretboardStyle {
        FretboardStyle(rawValue: fretboardStyleRaw) ?? .rosewood
    }

    private let accent = Color(hex: "#E94560")

    private let fretboardTips: [String] = [
        "E→F and B→C are always 1 fret apart — no sharp between them.",
        "Fret 12 is the same note as the open string, one octave higher.",
        "Open strings low→high: E · A · D · G · B · E",
        "Strings 1 and 6 are both E — same notes at every fret.",
        "There are only 12 notes — the pattern repeats every 12 frets.",
        "5th fret of any string matches the next open string above it.",
        "Exception: fret 4 on the G string = open B (B string tunes a 3rd, not a 4th).",
        "Octave shape: same note lives 2 strings up and 2 frets right. Add 1 extra fret when crossing the B string.",
        "Frets 0–5 on the low E: E · F · F# · G · G# · A",
        "Fret 5 on strings 6–4: A · D · G — the same as the open strings just above them.",
        "Fret 7 on the low E = B. Same pitch as the open B string.",
        "Natural notes in order: A B C D E F G — only half-steps are E→F and B→C.",
        "A# and Bb are the same pitch — two names for one fret.",
        "C is always 1 fret above B. F is always 1 fret above E.",
        "The notes on fret 3: G · C · F · A# · D · G (low E to high E).",
        "Memorise frets 3 and 5 as anchors — together they cover all 7 natural notes.",
        "Every note appears on every string within the first 12 frets.",
        "The CAGED system: chord shapes C · A · G · E · D repeat up the neck as movable shapes.",
    ]
    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    private var activeHighlightString: Int? {
        switch gameState.gameMode {
        case .nameTheNote:
            return gameState.currentString
        case .findTheFret, .memoryChallenge:
            if case .wrong(let s, _) = gameState.fretAnswerState { return s }
            return nil
        }
    }

    private var activeHighlightFret: Int? {
        switch gameState.gameMode {
        case .nameTheNote:
            return gameState.currentFret
        case .findTheFret, .memoryChallenge:
            if case .wrong(_, let f) = gameState.fretAnswerState { return f }
            return nil
        }
    }

    private var highlightColor: Color {
        switch gameState.gameMode {
        case .nameTheNote:
            switch gameState.answerState {
            case .idle:    return accent
            case .correct: return .green
            case .wrong:   return .red
            }
        case .findTheFret, .memoryChallenge:
            return .red
        }
    }

    /// Gold highlights during flash, red for missed positions during complete.
    private var memoryScaleHighlights: [(FretPosition, Color)] {
        guard gameState.gameMode == .memoryChallenge else { return [] }
        switch gameState.memoryPhase {
        case .flashing:
            return gameState.required.map { ($0, Color(hex: "#FFD700")) }
        case .recalling:
            return []
        case .complete:
            let missed = gameState.required.subtracting(gameState.foundFrets)
            return missed.map { ($0, Color.red.opacity(0.85)) }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 500
            let hPad: CGFloat    = compact ? 4 : 8
            let btnH: CGFloat    = compact ? 34 : 44
            let fbH: CGFloat     = fretboardFrameHeight(geo, compact: compact, btnH: btnH)

            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 16)
                    .padding(.top, hPad)
                    .padding(.bottom, compact ? 4 : 6)

                gameModeRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, compact ? 4 : 6)

                controlRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, compact ? 4 : 6)

                FretboardView(
                    fretboard: fretboard,
                    highlightString: isStudyMode ? nil : activeHighlightString,
                    highlightFret: isStudyMode ? nil : activeHighlightFret,
                    highlightColor: highlightColor,
                    foundPositions: !isStudyMode && (gameState.gameMode == .findTheFret || gameState.gameMode == .memoryChallenge)
                        ? Array(gameState.foundFrets)
                        : [],
                    showNoteLabels: isStudyMode,
                    studyFilterNote: studyHighlightNote,
                    scaleHighlights: isStudyMode ? [] : memoryScaleHighlights,
                    style: fretboardStyle,
                    difficultyBoundaryFret: (!isStudyMode && gameState.difficulty != .advanced)
                        ? gameState.difficulty.maxFret : nil,
                    onFretTap: (isStudyMode || gameState.gameMode == .findTheFret ||
                                gameState.gameMode == .memoryChallenge)
                        ? { s, f in
                            if isStudyMode {
                                if soundEnabled { audioEngine.play(string: s, fret: f) }
                            } else if gameState.gameMode == .memoryChallenge {
                                if soundEnabled && fretboard.note(string: s, fret: f) == gameState.correctNote {
                                    audioEngine.play(string: s, fret: f)
                                }
                                gameState.submitMemoryTap(string: s, fret: f)
                            } else {
                                if soundEnabled && fretboard.note(string: s, fret: f) == gameState.correctNote {
                                    audioEngine.play(string: s, fret: f)
                                }
                                gameState.submitFret(string: s, fret: f)
                            }
                        }
                        : nil
                )
                .frame(height: fbH, alignment: .top)
                .clipped()
                .transaction { $0.animation = nil }

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, compact ? 3 : 5)

                promptText
                    .frame(height: 20)
                    .clipped()
                    .transaction { $0.animation = nil }
                    .padding(.bottom, compact ? 3 : 5)

                if gameState.gameMode == .nameTheNote {
                    NoteAnswerButtonsView(
                        gameState: gameState,
                        buttonHeight: btnH,
                        onStudyTap: isStudyMode ? { note in
                            studyHighlightNote = (studyHighlightNote == note) ? nil : note
                        } : nil,
                        studySelectedNote: studyHighlightNote
                    )
                } else if gameState.gameMode == .findTheFret {
                    findTheFretPrompt(btnH: btnH, compact: compact)
                } else {
                    memoryPrompt(btnH: btnH, compact: compact)
                }

                if !compact && !isStudyMode && tipsEnabled && gameState.gameMode != .memoryChallenge {
                    tipView
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                }

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
        .sheet(isPresented: Binding(
            get: { gameState.showTimedResult },
            set: { if !$0 { gameState.showTimedResult = false } }
        )) {
            TimedResultView(gameState: gameState) {
                gameState.showTimedResult = false
            }
        }
        .fullScreenCover(item: $activeScreen) { screen in
            switch screen {
            case .circleOfFifths:  CircleOfFifthsView()
            case .chordCharts:     ChordChartsView(audioEngine: audioEngine)
            case .chromaticTuner:  ChromaticTunerView()
            case .scales:          ScalesView()
            case .fretboardStyle:
                FretboardStyleView(selectedStyle: Binding(
                    get: { fretboardStyle },
                    set: { fretboardStyleRaw = $0.rawValue }
                ))
            case .settings:
                SettingsView()
            }
        }
        .onChange(of: gameState.questionID) {
            if soundEnabled && !isStudyMode && gameState.gameMode == .nameTheNote {
                audioEngine.play(string: gameState.currentString, fret: gameState.currentFret)
            }
            if gameState.gameMode == .memoryChallenge {
                memoryFlashProgress = 1.0
                withAnimation(.linear(duration: gameState.flashDuration)) {
                    memoryFlashProgress = 0.0
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // FretboardView internal content height is exactly fretboardHeight(164) + 20 = 184pt.
    // The frame must never exceed 184pt or SwiftUI will center the content and cause layout jitter.
    private let fretboardContentHeight: CGFloat = 184

    private func fretboardFrameHeight(_ geo: GeometryProxy, compact: Bool, btnH: CGFloat) -> CGFloat {
        if compact {
            return fretboardContentHeight   // lock to content height; no centering offset
        }
        let headerH:   CGFloat = 48
        let gameModeH: CGFloat = 40
        let controlH:  CGFloat = 54
        let dividerH:  CGFloat = 12
        let promptH:   CGFloat = 24
        let buttonsH:  CGFloat = btnH * 2 + 8
        let fixed = headerH + gameModeH + controlH + dividerH + promptH + buttonsH
        return min(max(geo.size.height - fixed, 120), fretboardContentHeight)
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
                Text(gameState.gameMode.rawValue)
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
            Button(action: {
                isStudyMode.toggle()
                if !isStudyMode { studyHighlightNote = nil }
            }) {
                Text("Study")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isStudyMode ? .black : .white.opacity(0.7))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(isStudyMode ? Color.yellow : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(isStudyMode ? Color.yellow : Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: isStudyMode)

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

    // MARK: - Game Mode Row

    private var gameModeRow: some View {
        Picker("", selection: Binding(
            get: { gameState.gameMode },
            set: { gameState.setGameMode($0); studyHighlightNote = nil }
        )) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                Text(mode.shortName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .tint(accent)
    }

    // MARK: - Find The Fret Prompt

    private func findTheFretPrompt(btnH: CGFloat, compact: Bool = false) -> some View {
        let cardBg = Color(hex: "#16213E")
        return ZStack {
            RoundedRectangle(cornerRadius: 12).fill(cardBg)
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text(useFlats ? gameState.correctNote.flatName : gameState.correctNote.sharpName)
                        .font(.system(size: compact ? 20 : btnH * 1.4, weight: .heavy, design: .rounded))
                        .foregroundColor(findTheFretNoteColor)
                        .animation(.easeInOut(duration: 0.15), value: gameState.fretAnswerState)
                    Text(findTheFretFeedback)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(findTheFretNoteColor.opacity(0.8))
                        .animation(.easeInOut(duration: 0.15), value: gameState.fretAnswerState)
                }
                Spacer()
                Button(action: { gameState.skipNote() }) {
                    VStack(spacing: 2) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                        Text("Skip")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.trailing, 14)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: compact ? 50 : (btnH * 2 + 8))
        .padding(.horizontal, 12)
    }

    // MARK: - Memory Challenge Prompt

    private func memoryPrompt(btnH: CGFloat, compact: Bool = false) -> some View {
        let noteName = useFlats ? gameState.correctNote.flatName : gameState.correctNote.sharpName
        let cardBg   = Color(hex: "#16213E")
        let gold     = Color(hex: "#FFD700")

        return ZStack {
            RoundedRectangle(cornerRadius: 12).fill(cardBg)

            VStack(spacing: 2) {
                // Note name — shown in all phases
                Text(noteName)
                    .font(.system(size: compact ? 20 : btnH * 1.4, weight: .heavy, design: .rounded))
                    .foregroundColor(gameState.memoryPhase == .flashing ? gold : .white)
                    .animation(.easeInOut(duration: 0.3), value: gameState.memoryPhase)

                // Flash progress bar (only during flash phase)
                if gameState.memoryPhase == .flashing {
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.12))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(gold)
                                .frame(width: barGeo.size.width * memoryFlashProgress)
                        }
                    }
                    .frame(height: 5)
                    .padding(.horizontal, 24)
                } else {
                    // Recall status
                    let found     = gameState.foundFrets.count
                    let total     = gameState.required.count
                    let remaining = total - found
                    Text(gameState.memoryPhase == .complete ? "Found all \(total)!" :
                         found == 0 ? "find all \(total) position\(total == 1 ? "" : "s")" :
                         "\(remaining) remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(gameState.memoryPhase == .complete ? .green : .white.opacity(0.6))
                        .animation(.easeInOut(duration: 0.15), value: gameState.memoryPhase)
                }
            }
            .padding(.vertical, compact ? 4 : 8)
        }
        .frame(height: compact ? 50 : (btnH * 2 + 8))
        .padding(.horizontal, 12)
    }

    // MARK: - Tip of the question

    private var tipView: some View {
        let idx = abs(gameState.questionID.hashValue) % fretboardTips.count
        let tip = fretboardTips[idx]
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#FFD700"))
                .padding(.top, 2)
            Text(tip)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#16213E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#FFD700").opacity(0.25), lineWidth: 1)
                )
        )
        .id(gameState.questionID)
        .animation(.easeInOut(duration: 0.3), value: gameState.questionID)
    }

    private var findTheFretNoteColor: Color {
        switch gameState.fretAnswerState {
        case .idle:    return .white
        case .correct: return .green
        case .wrong:   return accent
        }
    }

    private var findTheFretFeedback: String {
        switch gameState.fretAnswerState {
        case .idle:
            let total = gameState.required.count
            let found = gameState.foundFrets.count
            if found == 0 {
                let rangeNote: String
                switch gameState.difficulty {
                case .beginner:     rangeNote = " · frets 0–5"
                case .intermediate: rangeNote = " · frets 0–10"
                case .advanced:     rangeNote = ""
                }
                return "find all \(total) position\(total == 1 ? "" : "s")\(rangeNote)"
            } else {
                let remaining = total - found
                return "\(remaining) remaining"
            }
        case .correct: return "correct!"
        case .wrong:   return "wrong — keep looking"
        }
    }

    // MARK: - Single Control Row

    private var controlRow: some View {
        HStack(spacing: 10) {
            if gameState.gameMode != .memoryChallenge {
                // Practice / Timed toggle — not shown in memory mode
                Picker("", selection: modeBinding) {
                    Text("Practice").tag(false)
                    Text("Timed").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
                .tint(accent)
            }

            Group {
                if gameState.gameMode == .memoryChallenge || !gameState.isTimedMode {
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
        .animation(.easeInOut(duration: 0.15), value: gameState.gameMode)
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

            if gameState.bestTimedScore > 0 {
                Text("Best: \(gameState.bestTimedScore)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.yellow.opacity(0.8))
                    .lineLimit(1)
            }

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
        } else if gameState.gameMode == .nameTheNote {
            Text("What note is highlighted?")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        } else if gameState.gameMode == .findTheFret {
            Text("Tap every \(useFlats ? gameState.correctNote.flatName : gameState.correctNote.sharpName) on the fretboard")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        } else {
            // Memory mode
            switch gameState.memoryPhase {
            case .flashing:
                Text("Memorize the positions!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#FFD700").opacity(0.9))
            case .recalling:
                Text("Tap all positions from memory")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            case .complete:
                Text("Round complete!")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            }
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
                    if gameState.isNewBest {
                        Text("🎉 New Best!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                    } else if gameState.bestTimedScore > 0 {
                        Text("Best: \(gameState.bestTimedScore)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    }
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
