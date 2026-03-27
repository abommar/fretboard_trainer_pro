import SwiftUI

struct FretboardView: View {
    let fretboard: Fretboard
    let highlightString: Int?
    let highlightFret: Int?
    let highlightColor: Color
    /// Already-found positions to show as persistent green circles (Find The Fret mode).
    var foundPositions: [FretPosition] = []
    /// When true, renders every note name on the fretboard as a study overlay.
    var showNoteLabels: Bool = false
    /// When non-nil in study mode, only labels for this note are shown (others hidden).
    var studyFilterNote: Note? = nil
    /// Scale mode: dots at each scale position. Tuple of (position, dotColor).
    var scaleHighlights: [(FretPosition, Color)] = []
    /// Visual theme for the fretboard.
    var style: FretboardStyle = .rosewood
    /// When non-nil, this fret wire is drawn in gold to mark the difficulty boundary.
    var difficultyBoundaryFret: Int? = nil
    /// When non-nil, each fret/string intersection is tappable. Called with (stringIndex, fret).
    var onFretTap: ((Int, Int) -> Void)? = nil

    // Layout constants
    private let stringSpacing: CGFloat = 28
    private let fretWidth: CGFloat = 54
    private let nutWidth: CGFloat = 8
    private let fretboardPadding: CGFloat = 12
    private let markerFrets: Set<Int> = [3, 5, 7, 9, 15, 17, 19, 21]
    private let doubleMarkerFret: Int = 12

    private var totalStrings: Int { fretboard.tuning.stringCount }
    private var fretCount: Int { fretboard.fretCount }

    private var fretboardHeight: CGFloat {
        CGFloat(totalStrings - 1) * stringSpacing + fretboardPadding * 2
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                fretboardBackground
                nutView
                fretWires
                if let bf = difficultyBoundaryFret { difficultyBoundaryLine(at: bf) }
                stringLines
                inlayDots
                if showNoteLabels { noteLabelsOverlay }
                scaleHighlightDots
                foundPositionCircles
                highlightCircle
                fretNumbers
                stringLabels
                if onFretTap != nil { fretTapOverlay }
            }
            .frame(width: fretboardWidth, height: fretboardHeight + 28)
            .padding(.leading, 40) // space for string labels
        }
    }

    private var fretboardWidth: CGFloat {
        CGFloat(fretCount) * fretWidth + nutWidth + 40
    }

    // MARK: - Background
    private var fretboardBackground: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: style.boardColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: fretboardWidth, height: fretboardHeight)
    }

    // MARK: - Nut
    private var nutView: some View {
        Rectangle()
            .fill(style.nutColor)
            .frame(width: nutWidth, height: fretboardHeight)
    }

    // MARK: - Fret wires
    private var fretWires: some View {
        ForEach(1...fretCount, id: \.self) { fret in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: style.fretColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: fretboardHeight)
                .offset(x: nutWidth + CGFloat(fret) * fretWidth)
        }
    }

    // MARK: - Difficulty boundary marker
    private func difficultyBoundaryLine(at fret: Int) -> some View {
        let x = nutWidth + CGFloat(fret) * fretWidth
        return ZStack {
            // Glow
            Rectangle()
                .fill(Color(hex: "#FFD700").opacity(0.35))
                .frame(width: 8, height: fretboardHeight)
                .blur(radius: 4)
            // Gold wire
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFE066"), Color(hex: "#FFD700"), Color(hex: "#B8860B")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: fretboardHeight)
        }
        .offset(x: x)
    }

    // MARK: - Strings
    private var stringLines: some View {
        ForEach(0..<totalStrings, id: \.self) { stringIdx in
            let thickness = stringThickness(for: stringIdx)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: style.stringColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: fretboardWidth, height: thickness)
                .offset(y: fretboardPadding + CGFloat(totalStrings - 1 - stringIdx) * stringSpacing - thickness / 2)
        }
    }

    private func stringThickness(for stringIdx: Int) -> CGFloat {
        // Low strings (higher index in our array = lower string) are thicker
        // stringIdx 0 = low E, 5 = high E
        switch stringIdx {
        case 0: return 3.5
        case 1: return 3.0
        case 2: return 2.5
        case 3: return 2.0
        case 4: return 1.5
        case 5: return 1.0
        default: return 1.5
        }
    }

    // MARK: - Inlay dots
    private var inlayDots: some View {
        Group {
            ForEach(Array(markerFrets), id: \.self) { fret in
                singleDot(at: fret, verticalFraction: 0.5)
            }
            singleDot(at: doubleMarkerFret, verticalFraction: 0.3)
            singleDot(at: doubleMarkerFret, verticalFraction: 0.7)
        }
    }

    private func singleDot(at fret: Int, verticalFraction: CGFloat) -> some View {
        let x = nutWidth + CGFloat(fret) * fretWidth - fretWidth / 2
        let y = fretboardHeight * verticalFraction
        return ZStack {
            // Base cream
            Circle()
                .fill(Color(hex: "#EDE8E0"))
            // Iridescent shimmer — offset radial blends teal, pink, and white
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color(hex: "#C8E8F0").opacity(0.60),
                        Color(hex: "#F0C8E0").opacity(0.40),
                        Color(hex: "#D0E8D8").opacity(0.25),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.38, y: 0.28),
                    startRadius: 0,
                    endRadius: 9
                ))
            // Specular highlight — small bright fleck
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 4, height: 4)
                .offset(x: -3.5, y: -3.5)
            // Subtle rim shadow
            Circle()
                .stroke(Color(hex: "#A09888").opacity(0.45), lineWidth: 0.75)
        }
        .frame(width: 16, height: 16)
        .offset(x: x - 8, y: y - 8)
    }

    // MARK: - Scale highlight dots
    @ViewBuilder
    private var scaleHighlightDots: some View {
        ForEach(Array(scaleHighlights.enumerated()), id: \.offset) { _, pair in
            let (pos, color) = pair
            let x = fretX(fret: pos.fret)
            let y = stringY(string: pos.string)
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                .position(x: x, y: y)
                .animation(nil, value: color)
        }
        .transaction { $0.animation = nil }
    }

    // MARK: - Study mode note labels
    private var noteLabelsOverlay: some View {
        let pillW: CGFloat = 26
        let pillH: CGFloat = 16
        return ForEach(0..<totalStrings, id: \.self) { stringIdx in
            ForEach(0...fretCount, id: \.self) { fret in
                let note = fretboard.note(string: stringIdx, fret: fret)
                // If a filter is active, skip all other notes
                if let filter = studyFilterNote, note != filter { return AnyView(EmptyView()) }
                let label = fretboard.tuning.useFlats ? note.flatName : note.sharpName
                let x = fretX(fret: fret)
                let y = stringY(string: stringIdx)
                return AnyView(
                    Text(label)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(noteLabelTextColor(for: note))
                        .frame(width: pillW, height: pillH)
                        .background(Capsule().fill(noteColor(for: note)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                        .position(x: x, y: y)
                )
            }
        }
    }

    private func noteColor(for note: Note) -> Color {
        let hue = Double(note.rawValue) / 12.0
        return Color(hue: hue, saturation: 0.80, brightness: 0.95)
    }

    /// Use dark text on light-hue pills (yellow/cyan range), white elsewhere.
    private func noteLabelTextColor(for note: Note) -> Color {
        // Notes in the yellow/green/cyan band (roughly hue 0.15–0.55) are light enough to need dark text
        let hue = Double(note.rawValue) / 12.0
        return (hue > 0.14 && hue < 0.56) ? Color.black.opacity(0.85) : .white
    }

    // MARK: - Found positions (persistent green dots in Find The Fret)
    @ViewBuilder
    private var foundPositionCircles: some View {
        ForEach(foundPositions, id: \.self) { pos in
            let x = fretX(fret: pos.fret)
            let y = stringY(string: pos.string)
            Circle()
                .fill(Color.green)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
                .position(x: x, y: y)
        }
    }

    // MARK: - Highlight circle
    @ViewBuilder
    private var highlightCircle: some View {
        if let s = highlightString, let f = highlightFret {
            let x = fretX(fret: f)
            let y = stringY(string: s)
            ZStack {
                Circle()
                    .fill(highlightColor.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .blur(radius: 8)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: highlightColor)
                Circle()
                    .fill(highlightColor)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 2)
                    )
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: highlightColor)
            }
            // .position() places the CENTER of the view at (x, y) regardless of view size.
            // This is unambiguous unlike .offset() which depends on knowing the view's frame size.
            .position(x: x, y: y)
            .id("\(s)-\(f)")
        }
    }

    private func fretX(fret: Int) -> CGFloat {
        if fret == 0 {
            return nutWidth / 2
        }
        return nutWidth + CGFloat(fret) * fretWidth - fretWidth / 2
    }

    private func stringY(string: Int) -> CGFloat {
        fretboardPadding + CGFloat(totalStrings - 1 - string) * stringSpacing
    }

    // MARK: - Tap overlay (Find The Fret mode)
    private var fretTapOverlay: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<totalStrings, id: \.self) { stringIdx in
                ForEach(0...fretCount, id: \.self) { fret in
                    Color.clear
                        .frame(width: fretWidth, height: stringSpacing)
                        .contentShape(Rectangle())
                        .offset(
                            x: fretX(fret: fret) - fretWidth / 2,
                            y: stringY(string: stringIdx) - stringSpacing / 2
                        )
                        .onTapGesture { onFretTap?(stringIdx, fret) }
                }
            }
        }
    }

    // MARK: - Fret numbers
    private var fretNumbers: some View {
        ForEach(0...fretCount, id: \.self) { fret in
            Text("\(fret)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .offset(x: fretX(fret: fret) - 8, y: fretboardHeight + 4)
        }
    }

    // MARK: - String labels
    private var stringLabels: some View {
        ForEach(0..<totalStrings, id: \.self) { stringIdx in
            Text(fretboard.tuning.strings[stringIdx].sharpName)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .offset(x: -32, y: stringY(string: stringIdx) - 7)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
