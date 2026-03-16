import Foundation
import CoreHaptics
import Observation

@Observable
final class GameState {
    private let fretboard: Fretboard

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

    private var hapticEngine: CHHapticEngine?

    init(fretboard: Fretboard = Fretboard()) {
        self.fretboard = fretboard
        prepareHaptics()
        nextQuestion()
    }

    func nextQuestion() {
        answerState = .idle
        currentString = Int.random(in: 0..<fretboard.tuning.stringCount)
        currentFret = Int.random(in: 0...fretboard.fretCount)
        correctNote = fretboard.note(string: currentString, fret: currentFret)
    }

    func submit(answer: Note) {
        guard case .idle = answerState else { return }
        totalCount += 1
        if answer == correctNote {
            correctCount += 1
            answerState = .correct(tapped: answer)
            playHaptic(success: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.nextQuestion()
            }
        } else {
            answerState = .wrong(tapped: answer, correct: correctNote)
            playHaptic(success: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.nextQuestion()
            }
        }
    }

    func reset() {
        correctCount = 0
        totalCount = 0
        nextQuestion()
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
