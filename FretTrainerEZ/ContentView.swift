import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()

    private var highlightColor: Color {
        switch gameState.answerState {
        case .idle: return Color(hex: "#E94560")
        case .correct: return .green
        case .wrong: return .red
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#1A1A2E").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FretTrainerEZ")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("Name That Note")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#E94560"))
                    }
                    Spacer()
                    scoreView
                    Button("Reset") {
                        gameState.reset()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#E94560"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#E94560"), lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Fretboard
                FretboardView(
                    fretboard: Fretboard(),
                    highlightString: gameState.currentString,
                    highlightFret: gameState.currentFret,
                    highlightColor: highlightColor
                )
                .frame(height: 230)

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 8)

                // Question prompt
                Text("What note is highlighted?")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 10)

                // Answer buttons
                NoteAnswerButtonsView(gameState: gameState)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var scoreView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(gameState.correctCount) / \(gameState.totalCount)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text("\(gameState.scorePercent)%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(scoreColor)
        }
        .padding(.trailing, 10)
    }

    private var scoreColor: Color {
        let pct = gameState.scorePercent
        if pct >= 80 { return .green }
        if pct >= 60 { return .yellow }
        return Color(hex: "#E94560")
    }
}
