import Foundation
import CoreHaptics
import Observation

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

    // Current question
    var currentString: Int = 0
    var currentFret: Int = 0
    var correctNote: Note = .C

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
        currentString = Int.random(in: 0..<fretboard.tuning.stringCount)
        currentFret = Int.random(in: 0...difficulty.maxFret)
        correctNote = fretboard.note(string: currentString, fret: currentFret)
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

    func reset() {
        stopTimedGame()
        correctCount = 0
        totalCount = 0
        nextQuestion()
    }

    func startTimedGame() {
        correctCount = 0
        totalCount = 0
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
            }
        }
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
