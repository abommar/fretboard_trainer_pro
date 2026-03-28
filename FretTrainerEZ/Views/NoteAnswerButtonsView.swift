import SwiftUI

struct NoteAnswerButtonsView: View {
    let gameState: GameState
    var buttonHeight: CGFloat = 44
    var onStudyTap: ((Note) -> Void)? = nil
    var studySelectedNote: Note? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Note.allCases, id: \.self) { note in
                NoteButton(note: note, gameState: gameState, buttonHeight: buttonHeight, onStudyTap: onStudyTap, studySelectedNote: studySelectedNote)
            }
        }
        .padding(.horizontal, 12)
    }
}

private struct NoteButton: View {
    let note: Note
    let gameState: GameState
    var buttonHeight: CGFloat = 44
    var onStudyTap: ((Note) -> Void)? = nil
    var studySelectedNote: Note? = nil

    @AppStorage("useFlats") private var useFlats: Bool = false

    private var isStudyMode: Bool { onStudyTap != nil }
    private var isStudySelected: Bool { studySelectedNote == note }

    private var studyColor: Color {
        let hue = Double(note.rawValue) / 12.0
        return Color(hue: hue, saturation: 0.80, brightness: 0.95)
    }

    private var studyTextColor: Color {
        let hue = Double(note.rawValue) / 12.0
        return (hue > 0.14 && hue < 0.56) ? Color.black.opacity(0.85) : .white
    }

    private var buttonColor: Color {
        if let _ = onStudyTap {
            return studySelectedNote == note ? .yellow.opacity(0.85) : Color(hex: "#2A2A4A")
        }
        switch gameState.answerState {
        case .idle:
            return Color(hex: "#2A2A4A")
        case .correct(let tapped):
            if note == tapped { return .green }
            return Color(hex: "#2A2A4A")
        case .wrong(let tapped, let correct):
            if note == tapped { return .red }
            if note == correct { return Color(hex: "#2A2A4A") }
            return Color(hex: "#2A2A4A")
        }
    }

    private var borderColor: Color {
        if onStudyTap != nil { return .clear }
        switch gameState.answerState {
        case .wrong(_, let correct):
            if note == correct { return .green }
        default: break
        }
        return .clear
    }

    private var labelColor: Color {
        if isStudyMode && isStudySelected { return studyTextColor }
        return .white
    }

    var body: some View {
        Button {
            if let onStudyTap {
                onStudyTap(note)
            } else {
                gameState.submit(answer: note)
            }
        } label: {
            Text(useFlats ? note.flatName : note.sharpName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity)
                .frame(height: buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(buttonColor)
                        .animation(.easeInOut(duration: 0.15), value: buttonColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 2.5)
                                .animation(.easeInOut(duration: 0.15), value: borderColor)
                        )
                )
        }
        .disabled({
            if onStudyTap != nil { return false }
            if !gameState.canAnswer { return true }
            if case .idle = gameState.answerState { return false }
            return true
        }())
    }
}
