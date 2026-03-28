import SwiftUI

// MARK: - Layout constants
// Every zone has an explicit fixed height. The fretboard's Y position on screen
// is therefore a compile-time constant — no state change can shift it.

private let fretboardH: CGFloat = 192  // FretboardView internal content height (always)

// Portrait fixed zone heights
private let portraitTopH:    CGFloat = 148  // header + mode picker + controls
private let portraitPromptH: CGFloat = 30   // prompt text row
private let portraitGameH:   CGFloat = 100  // game-UI zone (same height for all 3 modes)

// Landscape compact zone heights
private let landscapeTopH:    CGFloat = 78   // two-row top bar
private let landscapePromptH: CGFloat = 22
private let landscapeGameH:   CGFloat = 80

struct ContentView: View {
    @State private var gameState        = GameState()
    @State private var audioEngine      = NoteAudioEngine()
    @State private var isDrawerOpen     = false
    @State private var activeScreen: AppScreen? = nil
    @State private var memoryFlashProgress: CGFloat = 1.0
    @State private var isStudyMode = false
    @State private var studyHighlightNote: Note? = nil

    @AppStorage("soundEnabled")    private var soundEnabled:    Bool = false
    @AppStorage("useFlats")        private var useFlats:        Bool = false
    @AppStorage("fretboardStyle")  private var fretboardStyleRaw: String = FretboardStyle.rosewood.rawValue
    private var fretboardStyle: FretboardStyle {
        FretboardStyle(rawValue: fretboardStyleRaw) ?? .rosewood
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var compact: Bool { verticalSizeClass == .compact }

    private let fretboard = Fretboard()

    private let accent = Color(hex: "#E94560")
    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    // MARK: - Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            if compact { landscapeLayout } else { portraitLayout }
        }
        // Fretboard lives here in portrait — pinned by a compile-time constant,
        // completely outside portraitLayout's view hierarchy so nothing there can shift it.
        .overlay { if gameState.isTimeUp { timeUpOverlay } }
        .overlay {
            DrawerMenuView(isOpen: $isDrawerOpen) { screen in activeScreen = screen }
        }
        .sheet(isPresented: Binding(
            get: { gameState.showTimedResult },
            set: { if !$0 { gameState.showTimedResult = false } }
        )) {
            TimedResultView(gameState: gameState) { gameState.showTimedResult = false }
        }
        .fullScreenCover(item: $activeScreen) { screen in
            switch screen {
            case .circleOfFifths:  CircleOfFifthsView()
            case .chordCharts:     ChordChartsView()
            case .songGenerator:   SongGeneratorView()
            case .chromaticTuner:  ChromaticTunerView()
            case .scales:          ScalesView()
            case .fretboardStyle:  FretboardStyleView(selectedStyle: Binding(
                                       get: { fretboardStyle },
                                       set: { fretboardStyleRaw = $0.rawValue }
                                   ))
            case .settings:        SettingsView()
            }
        }
        .onChange(of: gameState.questionID) {
            if soundEnabled && gameState.gameMode == .nameTheNote {
                audioEngine.play(string: gameState.currentString, fret: gameState.currentFret)
            }
            if gameState.gameMode == .memoryChallenge {
                memoryFlashProgress = 1.0
                DispatchQueue.main.async { memoryFlashProgress = 0.0 }
            }
        }
        .onChange(of: gameState.memoryPhase) { _, newPhase in
            if newPhase != .flashing {
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) { memoryFlashProgress = 0.0 }
            }
        }
        // Suppress layout animations driven by game-state changes.
        .animation(nil, value: gameState.gameMode)
        .animation(nil, value: gameState.memoryPhase)
        .animation(nil, value: gameState.questionID)
        .preferredColorScheme(.dark)
    }

    // MARK: - Portrait layout
    // Fretboard is NOT in this view — it lives in the body overlay above.
    // This layout only contains the controls; a Color.clear spacer reserves
    // the fretboard's space so the zones below it sit at the right Y position.

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            topZone(compact: false)
                .frame(height: portraitTopH, alignment: .top)
                .clipped()
            fretboardView
                .frame(height: fretboardH)
                .transaction { $0.animation = nil }
            promptRow
                .frame(height: portraitPromptH)
            gameUIZone(btnH: 44)
                .frame(height: portraitGameH)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Landscape layout (compact vertical — same structure as portrait)

    private var landscapeLayout: some View {
        VStack(spacing: 0) {
            landscapeTopZone
                .frame(height: landscapeTopH)
                .clipped()
            Spacer(minLength: 0)
            fretboardView
                .frame(height: fretboardH)
                .transaction { $0.animation = nil }
            promptRow
                .frame(height: landscapePromptH)
            gameUIZone(btnH: 32)
                .frame(height: landscapeGameH)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Landscape top zone (two-row bar)

    private var landscapeTopZone: some View {
        VStack(spacing: 0) {
            // Row 1: hamburger + app name + spacer + score + study + reset
            HStack(spacing: 8) {
                Button { isDrawerOpen.toggle() } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)

                Text("FretTrainerEZ")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                if !gameState.isTimedMode {
                    Text("\(gameState.correctCount)/\(gameState.totalCount)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                studyButton

                Button("Reset") { gameState.reset() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).stroke(accent, lineWidth: 1.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 4)

            // Row 2: mode picker + practice/timed + difficulty/timer
            HStack(spacing: 8) {
                modePicker
                    .frame(maxWidth: 250)

                practiceTimedPicker
                    .opacity(gameState.gameMode == .memoryChallenge ? 0 : 1)
                    .disabled(gameState.gameMode == .memoryChallenge)

                ZStack(alignment: .leading) {
                    difficultySlider
                        .opacity(showDifficultySlider ? 1 : 0)
                        .allowsHitTesting(showDifficultySlider)
                    timerActiveView(compact: true)
                        .opacity(showTimerActive ? 1 : 0)
                        .allowsHitTesting(showTimerActive)
                    durationView(compact: true)
                        .opacity(showDuration ? 1 : 0)
                        .allowsHitTesting(showDuration)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Top Zone (portrait)

    private func topZone(compact: Bool) -> some View {
        VStack(spacing: 0) {
            portraitHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

            modePicker
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            controlRow(compact: compact)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
    }

    // MARK: - Fretboard

    private var fretboardView: some View {
        let highlightStr: Int? = {
            switch gameState.gameMode {
            case .nameTheNote: return gameState.currentString
            case .findTheFret, .memoryChallenge:
                if case .wrong(let s, _) = gameState.fretAnswerState { return s }
                return nil
            }
        }()
        let highlightFrt: Int? = {
            switch gameState.gameMode {
            case .nameTheNote: return gameState.currentFret
            case .findTheFret, .memoryChallenge:
                if case .wrong(_, let f) = gameState.fretAnswerState { return f }
                return nil
            }
        }()
        let hColor: Color = {
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
        }()
        let found: [FretPosition] =
            (gameState.gameMode == .findTheFret || gameState.gameMode == .memoryChallenge)
            ? Array(gameState.foundFrets) : []

        let scaleHL: [(FretPosition, Color)] = {
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
        }()

        let onTap: ((Int, Int) -> Void)? = {
            guard gameState.gameMode == .findTheFret || gameState.gameMode == .memoryChallenge else {
                return nil
            }
            return { s, f in
                if soundEnabled && fretboard.note(string: s, fret: f) == gameState.correctNote {
                    audioEngine.play(string: s, fret: f)
                }
                if gameState.gameMode == .memoryChallenge {
                    gameState.submitMemoryTap(string: s, fret: f)
                } else {
                    gameState.submitFret(string: s, fret: f)
                }
            }
        }()

        return FretboardView(
            fretboard: fretboard,
            highlightString: highlightStr,
            highlightFret:   highlightFrt,
            highlightColor:  hColor,
            foundPositions:  found,
            scaleHighlights: scaleHL,
            difficultyBoundaryFret: gameState.difficulty != .advanced ? gameState.difficulty.maxFret : nil,
            onFretTap: onTap,
            showNoteLabels: isStudyMode,
            studyFilterNote: studyHighlightNote
        )
        .transaction { $0.animation = nil }
    }

    // MARK: - Study Button

    private var studyButton: some View {
        Group {
            if gameState.gameMode != .memoryChallenge {
                Button {
                    isStudyMode.toggle()
                    if !isStudyMode { studyHighlightNote = nil }
                } label: {
                    Text("Study")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isStudyMode ? .black : Color(hex: "#FFD700"))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(isStudyMode ? Color(hex: "#FFD700") : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color(hex: "#FFD700").opacity(0.7), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Portrait Header

    private var portraitHeader: some View {
        HStack(spacing: 8) {
            Button { isDrawerOpen.toggle() } label: {
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

            studyButton

            Button("Reset") { gameState.reset() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).stroke(accent, lineWidth: 1.5))
        }
    }

    // MARK: - Landscape Header

    private var landscapeHeader: some View {
        HStack(spacing: 6) {
            Button { isDrawerOpen.toggle() } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Text("FretTrainerEZ")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            if !gameState.isTimedMode {
                Text("\(gameState.correctCount)/\(gameState.totalCount)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            Button("Reset") { gameState.reset() }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(accent)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).stroke(accent, lineWidth: 1.5))
        }
    }

    private var scoreColor: Color {
        let p = gameState.scorePercent
        if p >= 80 { return .green }
        if p >= 60 { return .yellow }
        return accent
    }

    // MARK: - Mode Picker (pure SwiftUI — no UIKit animation injection)

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                let selected = gameState.gameMode == mode
                Button {
                    guard gameState.gameMode != mode else { return }
                    if mode == .memoryChallenge { isStudyMode = false; studyHighlightNote = nil }
                    var t = Transaction(); t.disablesAnimations = true
                    withTransaction(t) {
                        gameState.setGameMode(mode)
                    }
                } label: {
                    Text(mode.shortName)
                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                        .foregroundColor(selected ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selected ? Color(white: 0.35) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 9).fill(Color(white: 0.18)))
        .frame(height: 32)
    }

    // MARK: - Control Row
    // Uses ZStack so all sub-views are always in the layout tree — only opacity changes.
    // The HStack height is fixed so this zone never changes size.

    private func controlRow(compact: Bool) -> some View {
        HStack(spacing: 10) {
            // Practice / Timed — hidden (opacity 0) in Memory mode, but always in layout
            practiceTimedPicker
                .opacity(gameState.gameMode == .memoryChallenge ? 0 : 1)
                .disabled(gameState.gameMode == .memoryChallenge)

            ZStack(alignment: .leading) {
                difficultySlider
                    .opacity(showDifficultySlider ? 1 : 0)
                    .allowsHitTesting(showDifficultySlider)
                timerActiveView(compact: compact)
                    .opacity(showTimerActive ? 1 : 0)
                    .allowsHitTesting(showTimerActive)
                durationView(compact: compact)
                    .opacity(showDuration ? 1 : 0)
                    .allowsHitTesting(showDuration)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 36)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 10).fill(cardBg))
        .transaction { $0.animation = nil }
    }

    private var showDifficultySlider: Bool {
        gameState.gameMode == .memoryChallenge || !gameState.isTimedMode
    }
    private var showTimerActive: Bool {
        gameState.gameMode != .memoryChallenge && gameState.isTimedMode && gameState.isTimerActive
    }
    private var showDuration: Bool {
        gameState.gameMode != .memoryChallenge && gameState.isTimedMode && !gameState.isTimerActive
    }

    private var practiceTimedPicker: some View {
        HStack(spacing: 0) {
            ForEach([false, true], id: \.self) { timed in
                let sel = gameState.isTimedMode == timed
                Button {
                    guard gameState.isTimedMode != timed else { return }
                    gameState.isTimedMode = timed
                    if !timed { gameState.stopTimedGame(); gameState.reset() }
                    else       { gameState.stopTimedGame() }
                } label: {
                    Text(timed ? "Timed" : "Practice")
                        .font(.system(size: 12, weight: sel ? .semibold : .regular))
                        .foregroundColor(sel ? .white : .white.opacity(0.5))
                        .frame(width: 62, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(sel ? Color(white: 0.35) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color(white: 0.12)))
        .frame(width: 132)
    }

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

    private func timerActiveView(compact: Bool) -> some View {
        HStack(spacing: 6) {
            Text(timeString)
                .font(.system(size: compact ? 17 : 20, weight: .heavy, design: .monospaced))
                .foregroundColor(gameState.timeRemaining <= 10 ? .red : .white)
                .monospacedDigit()
            Spacer()
            Text("\(gameState.correctCount) ✓")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            Button { gameState.stopTimedGame() } label: {
                Text("Stop")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.9)))
            }
            .buttonStyle(.plain)
        }
    }

    private func durationView(compact: Bool) -> some View {
        HStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach([30, 60, 120], id: \.self) { dur in
                    let sel = gameState.timerDuration == dur
                    Button {
                        gameState.timerDuration = dur
                        gameState.timeRemaining = dur
                    } label: {
                        Text(dur == 30 ? "30s" : dur == 60 ? "1m" : "2m")
                            .font(.system(size: 12, weight: sel ? .semibold : .regular))
                            .foregroundColor(sel ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background(RoundedRectangle(cornerRadius: 5).fill(sel ? Color(white:0.35) : .clear))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color(white: 0.12)))

            if gameState.bestTimedScore > 0 {
                Text("Best: \(gameState.bestTimedScore)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.yellow.opacity(0.8))
                    .lineLimit(1)
            }

            Button { gameState.startTimedGame() } label: {
                Text("Start")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(accent))
            }
            .buttonStyle(.plain)
        }
    }

    private var timeString: String {
        let m = gameState.timeRemaining / 60
        let s = gameState.timeRemaining % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : "\(s)s"
    }

    // MARK: - Prompt Row

    private var promptRow: some View {
        Text(promptMessage)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.65))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .transaction { $0.animation = nil }
    }

    private var promptMessage: String {
        if gameState.isTimedMode && !gameState.isTimerActive && !gameState.isTimeUp {
            return "Tap Start to begin"
        }
        switch gameState.gameMode {
        case .nameTheNote:
            return "What note is highlighted?"
        case .findTheFret:
            let note = useFlats ? gameState.correctNote.flatName : gameState.correctNote.sharpName
            return "Tap every \(note) on the fretboard"
        case .memoryChallenge:
            switch gameState.memoryPhase {
            case .flashing:  return "Memorize the positions!"
            case .recalling: return "Tap all positions from memory"
            case .complete:  return "Round complete!"
            }
        }
    }

    // MARK: - Game UI Zone
    // ZStack keeps all 3 mode views in the layout tree at all times.
    // Only opacity and hit-testing change — the layout tree is structurally
    // identical regardless of game mode, so no layout pass can shift the fretboard.

    private func gameUIZone(btnH: CGFloat) -> some View {
        ZStack {
            nameTheNoteUI(btnH: btnH)
                .opacity(gameState.gameMode == .nameTheNote ? 1 : 0)
                .allowsHitTesting(gameState.gameMode == .nameTheNote)

            findTheFretUI(btnH: btnH)
                .opacity(gameState.gameMode == .findTheFret ? 1 : 0)
                .allowsHitTesting(gameState.gameMode == .findTheFret)

            memoryUI(btnH: btnH)
                .opacity(gameState.gameMode == .memoryChallenge ? 1 : 0)
                .allowsHitTesting(gameState.gameMode == .memoryChallenge)
        }
        .transaction { $0.animation = nil }
    }

    // MARK: - Name That Note UI

    private func nameTheNoteUI(btnH: CGFloat) -> some View {
        NoteAnswerButtonsView(
            gameState: gameState,
            buttonHeight: btnH,
            onStudyTap: isStudyMode ? { note in
                studyHighlightNote = (studyHighlightNote == note) ? nil : note
            } : nil,
            studySelectedNote: isStudyMode ? studyHighlightNote : nil
        )
    }

    // MARK: - Find The Fret UI

    private func findTheFretUI(btnH: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(cardBg)
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text(useFlats ? gameState.correctNote.flatName : gameState.correctNote.sharpName)
                        .font(.system(size: btnH * 1.3, weight: .heavy, design: .rounded))
                        .foregroundColor(findNoteColor)

                    Text(findFeedbackText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(findNoteColor.opacity(0.8))
                }
                Spacer()
                Button { gameState.skipNote() } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "forward.fill").font(.system(size: 14))
                        Text("Skip").font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.trailing, 14)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }

    private var findNoteColor: Color {
        switch gameState.fretAnswerState {
        case .idle:    return .white
        case .correct: return .green
        case .wrong:   return accent
        }
    }

    private var findFeedbackText: String {
        switch gameState.fretAnswerState {
        case .idle:
            let total = gameState.required.count
            let found = gameState.foundFrets.count
            if found == 0 {
                let range: String
                switch gameState.difficulty {
                case .beginner:     range = " · frets 0–5"
                case .intermediate: range = " · frets 0–10"
                case .advanced:     range = ""
                }
                return "find all \(total) position\(total == 1 ? "" : "s")\(range)"
            }
            return "\(total - found) remaining"
        case .correct: return "found them all!"
        case .wrong:   return "wrong — keep looking"
        }
    }

    // MARK: - Memory UI

    private func memoryUI(btnH: CGFloat) -> some View {
        let gold    = Color(hex: "#FFD700")
        let total   = gameState.required.count
        let found   = gameState.foundFrets.count
        let remaining = total - found

        return ZStack {
            RoundedRectangle(cornerRadius: 12).fill(cardBg)
            VStack(spacing: 4) {
                Text(useFlats ? gameState.correctNote.flatName : gameState.correctNote.sharpName)
                    .font(.system(size: btnH * 1.3, weight: .heavy, design: .rounded))
                    .foregroundColor(gameState.memoryPhase == .flashing ? gold : .white)

                ZStack {
                    // Flash countdown bar — scoped animation, does NOT bleed to layout
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.12))
                        RoundedRectangle(cornerRadius: 3).fill(gold)
                            .scaleEffect(x: memoryFlashProgress, anchor: .leading)
                            .animation(.linear(duration: gameState.flashDuration),
                                       value: memoryFlashProgress)
                    }
                    .padding(.horizontal, 24)
                    .opacity(gameState.memoryPhase == .flashing ? 1 : 0)

                    // Recall / complete status
                    Text(gameState.memoryPhase == .complete
                         ? "Found all \(total)!"
                         : found == 0
                           ? "find all \(total) position\(total == 1 ? "" : "s")"
                           : "\(remaining) remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(gameState.memoryPhase == .complete ? .green : .white.opacity(0.6))
                        .opacity(gameState.memoryPhase == .flashing ? 0 : 1)
                }
                .frame(height: 14)
                .transaction { $0.animation = nil }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Time-Up Overlay

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
                        .font(.system(size: 15)).foregroundColor(.white.opacity(0.6))
                    if gameState.isNewBest {
                        Text("New Best!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                }
                Button { gameState.startTimedGame() } label: {
                    Text("Play Again")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(accent))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Snap Slider

struct SnapSlider: View {
    @Binding var value: Int
    let steps: Int

    private let trackH:    CGFloat = 5
    private let thumbSize: CGFloat = 18

    private let trackFill = LinearGradient(
        colors: [Color(hex: "#111111"), Color(hex: "#333333"), Color(hex: "#111111")],
        startPoint: .top, endPoint: .bottom)
    private let activeFill = LinearGradient(
        colors: [Color(hex: "#D0D0D0"), Color(hex: "#888888")],
        startPoint: .top, endPoint: .bottom)
    private let thumbFill = LinearGradient(
        colors: [Color(hex: "#F0F0F0"), Color(hex: "#C0C0C0"), Color(hex: "#808080")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - thumbSize
            let stepW  = usable / CGFloat(steps - 1)
            let thumbX = CGFloat(value) * stepW

            ZStack(alignment: .leading) {
                Capsule().fill(trackFill).frame(height: trackH)
                    .overlay(Capsule().stroke(Color.black.opacity(0.6), lineWidth: 0.5))
                    .padding(.horizontal, thumbSize / 2)

                Capsule().fill(activeFill).frame(width: thumbX + thumbSize / 2, height: trackH)
                    .padding(.leading, thumbSize / 2)
                    .clipped()

                Circle().fill(thumbFill)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    .offset(x: thumbX)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                let raw = drag.location.x / (usable / CGFloat(steps - 1))
                value = max(0, min(steps - 1, Int(raw.rounded())))
            })
        }
        .frame(height: thumbSize)
    }
}
