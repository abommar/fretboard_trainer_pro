import SwiftUI

struct TimedResultView: View {
    let gameState: GameState
    var onDismiss: () -> Void

    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")
    private let accent = Color(hex: "#E94560")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 28) {
                // Title
                Text("Time's Up!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                // Stat cards
                HStack(spacing: 16) {
                    statCard(label: "Correct", value: "\(gameState.correctCount)", color: .green)
                    statCard(label: "Wrong",   value: "\(gameState.totalCount - gameState.correctCount)", color: accent)
                }

                HStack(spacing: 16) {
                    statCard(label: "Best Streak", value: "\(gameState.bestStreakThisSession)", color: .orange)
                    statCard(label: "All-Time Streak", value: "\(gameState.bestStreak)", color: Color(hex: "#4499FF"))
                }

                if gameState.isNewBest {
                    Text("New personal best!")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(10)
                }

                // Play again
                Button(action: {
                    onDismiss()
                    gameState.startTimedGame()
                }) {
                    Text("Play Again")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(accent)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)

                // Done
                Button("Done") { onDismiss() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
        }
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(cardBg)
        .cornerRadius(14)
    }
}
