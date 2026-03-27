import SwiftUI

struct TimedResultView: View {
    let gameState: GameState
    let onDismiss: () -> Void

    private let accent  = Color(hex: "#E94560")
    private let cardBg  = Color(hex: "#16213E")
    private let bg      = Color(hex: "#1A1A2E")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Session Complete")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 32)

                // Big score
                VStack(spacing: 4) {
                    Text("\(gameState.correctCount)")
                        .font(.system(size: 72, weight: .heavy, design: .monospaced))
                        .foregroundColor(accent)
                    Text("correct out of \(gameState.totalCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    if gameState.isNewBest {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            Text("New best!")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .padding(.top, 4)
                    }
                }

                // Stats grid
                HStack(spacing: 12) {
                    statCard(
                        label: "Accuracy",
                        value: "\(gameState.scorePercent)%",
                        color: accuracyColor
                    )
                    statCard(
                        label: "Best Streak",
                        value: "\(gameState.bestStreakThisSession)",
                        color: .cyan
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        onDismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            gameState.startTimedGame()
                        }
                    } label: {
                        Text("Play Again")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(accent))
                    }
                    .buttonStyle(.plain)

                    Button { onDismiss() } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#16213E")))
    }

    private var accuracyColor: Color {
        let p = gameState.scorePercent
        if p >= 80 { return .green }
        if p >= 60 { return .yellow }
        return Color(hex: "#E94560")
    }
}
