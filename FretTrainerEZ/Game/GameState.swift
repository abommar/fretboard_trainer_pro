import Foundation
import CoreHaptics
import Observation

enum GameMode: String, CaseIterable {
    case nameTheNote = "Name That Note"
    case findTheFret = "Find The Fret"
}

struct FretPosition: Hashable {
    let string: Int
    let fret: Int
}

enum Difficulty: String, CaseIterable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"

    var maxFret: Int {
        switch self {
        case .beginner:     return 5
        case .intermediate: return 10
        case .advanced:     return 22
        }
    }
}

@Observable
final class GameState {
    private let fretboard: Fretboard

    // Difficulty
    var difficulty: Difficulty = .beginner

    var gameMode: GameMode = .nameTheNote

    // Current question
    var currentString: Int = 0
    var currentFret: Int = 0
    var correctNote: Note = .C
    var questionID: UUID = UUID()

    // Score
    var correctCount: Int = 0
    var totalCount: Int = 0

    var scorePercent: Int {
        guard totalCount > 0 else { return 0 }
        return Int(Double(correctCount) / Double(totalCount) * 100)
    }

    // Answer feedback
    enum AnswerState: Equatable {
        case idle
        case correct(tapped: Note)
        case wrong(tapped: Note, correct: Note)
    }
    var answerState: AnswerState = .idle

    enum FretAnswerState: Equatable {
        case idle
        case correct(string: Int, fret: Int)
        case wrong(string: Int, fret: Int)
    }
    var fretAnswerState: FretAnswerState = .idle

    // Find The Fret: positions the user has already tapped correctly this round
    var foundFrets: Set<FretPosition> = []

    // Best score persistence
    var isNewBest: Bool = false
    var bestTimedScore: Int { UserDefaults.standard.integer(forKey: timedScoreKey) }
    private var timedScoreKey: String { "best_\(gameMode.rawValue)_\(timerDuration)" }

    // Timer
    var isTimedMode: Bool = false
    var timerDuration: Int = 60
    var timeRemaining: Int = 60
    var isTimerActive: Bool = false
    var isTimeUp: Bool = false

    var canAnswer: Bool {
        if isTimedMode { return isTimerActive && !isTimeUp }
        return true
    }

    private var countdownTimer: Timer?
    private var hapticEngine: CHHapticEngine?

    init(fretboard: Fretboard = Fretboard()) {
        self.fretboard = fretboard
        prepareHaptics()
        nextQuestion()
    }

    func nextQuestion() {
        answerState = .idle
        fretAnswerState = .idle
        foundFrets = []
        questionID = UUID()
        if gameMode == .nameTheNote {
            currentString = Int.random(in: 0..<fretboard.tuning.stringCount)
            currentFret   = Int.random(in: 0...difficulty.maxFret)
            correctNote   = fretboard.note(string: currentString, fret: currentFret)
        } else {
            // Pick a random note; position is unknown — user must find it
            correctNote   = Note.allCases.randomElement()!
            currentString = 0
            currentFret   = 0
        }
    }

    func setDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        correctCount = 0
        totalCount = 0
        nextQuestion()
    }

    func submit(answer: Note) {
        guard case .idle = answerState else { return }
        guard canAnswer else { return }
        totalCount += 1
        let correctDelay: Double = isTimedMode ? 0.5 : 0.8
        let wrongDelay: Double   = isTimedMode ? 0.7 : 1.5
        if answer == correctNote {
            correctCount += 1
            answerState = .correct(tapped: answer)
            playHaptic(success: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + correctDelay) { [weak self] in
                guard let self, !self.isTimeUp else { return }
                self.nextQuestion()
            }
        } else {
            answerState = .wrong(tapped: answer, correct: correctNote)
            playHaptic(success: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + wrongDelay) { [weak self] in
                guard let self, !self.isTimeUp else { return }
                self.nextQuestion()
            }
        }
    }

    func submitFret(string: Int, fret: Int) {
        guard canAnswer else { return }
        let pos = FretPosition(string: string, fret: fret)
        guard !foundFrets.contains(pos) else { return }   // already lit up
        guard case .idle = fretAnswerState else { return } // block during wrong flash / completion

        if fretboard.note(string: string, fret: fret) == correctNote {
            foundFrets.insert(pos)
            playHaptic(success: true)

            // Advance when all required positions (within difficulty range) are found
            let required = Set(
                fretboard.allPositions(for: correctNote)
                    .filter { $0.fret <= difficulty.maxFret }
                    .map { FretPosition(string: $0.string, fret: $0.fret) }
            )
            if required.isSubset(of: foundFrets) {
                correctCount += 1
                totalCount += 1
                fretAnswerState = .correct(string: string, fret: fret) // blocks further taps
                DispatchQueue.main.asyncAfter(deadline: .now() + (isTimedMode ? 0.5 : 0.8)) { [weak self] in
                    guard let self, !self.isTimeUp else { return }
                    self.nextQuestion()
                }
            }
        } else {
            totalCount += 1
            fretAnswerState = .wrong(string: string, fret: fret)
            playHaptic(success: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self else { return }
                if case .wrong = self.fretAnswerState { self.fretAnswerState = .idle }
            }
        }
    }

    func skipNote() {
        guard gameMode == .findTheFret else { return }
        let other = Note.allCases.filter { $0 != correctNote }
        correctNote = other.randomElement() ?? correctNote
        answerState = .idle
        fretAnswerState = .idle
        foundFrets = []
    }

    func setGameMode(_ mode: GameMode) {
        gameMode = mode
        reset()
    }

    func reset() {
        fretAnswerState = .idle
        foundFrets = []
        isNewBest = false
        stopTimedGame()
        correctCount = 0
        totalCount = 0
        nextQuestion()
    }

    func startTimedGame() {
        correctCount = 0
        totalCount = 0
        isNewBest = false
        foundFrets = []
        timeRemaining = timerDuration
        isTimeUp = false
        isTimerActive = true
        nextQuestion()
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 1 {
                self.timeRemaining -= 1
            } else {
                self.timeRemaining = 0
                self.isTimerActive = false
                self.isTimeUp = true
                self.answerState = .idle
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.saveTimedScoreIfBetter()
            }
        }
    }

    private func saveTimedScoreIfBetter() {
        guard correctCount > bestTimedScore else { return }
        UserDefaults.standard.set(correctCount, forKey: timedScoreKey)
        isNewBest = true
    }

    func stopTimedGame() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isTimerActive = false
        isTimeUp = false
        timeRemaining = timerDuration
    }

    // MARK: - Haptics
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
    }

    private func playHaptic(success: Bool) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true else { return }
        guard let engine = hapticEngine,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: success ? 0.8 : 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: success ? 0.3 : 0.9)
        let event = CHHapticEvent(eventType: success ? .hapticContinuous : .hapticTransient,
                                  parameters: [intensity, sharpness],
                                  relativeTime: 0,
                                  duration: success ? 0.3 : 0.1)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }
}
