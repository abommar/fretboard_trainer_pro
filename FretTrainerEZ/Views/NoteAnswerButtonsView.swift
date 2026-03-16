import SwiftUI

struct NoteAnswerButtonsView: View {
    let gameState: GameState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Note.allCases, id: \.self) { note in
                NoteButton(note: note, gameState: gameState)
            }
        }
        .padding(.horizontal, 12)
    }
}

private struct NoteButton: View {
    let note: Note
    let gameState: GameState

    @State private var isPressed = false

    private var buttonColor: Color {
        switch gameState.answerState {
        case .idle:
            return Color(hex: "#2A2A4A")
        case .correct(let tapped):
            if note == tapped { return .green }
            return Color(hex: "#2A2A4A")
        case .wrong(let tapped, let correct):
            if note == tapped { return .red }
            if note == correct { return Color(hex: "#2A2A4A") } // green outline handled separately
            return Color(hex: "#2A2A4A")
        }
    }

    private var borderColor: Color {
        switch gameState.answerState {
        case .wrong(_, let correct):
            if note == correct { return .green }
        default: break
        }
        return .clear
    }

    var body: some View {
        Button {
            gameState.submit(answer: note)
        } label: {
            Text(note.sharpName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(buttonColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 2.5)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.15), value: gameState.answerState)
        .disabled({
            if case .idle = gameState.answerState { return false }
            return true
        }())
    }
}
