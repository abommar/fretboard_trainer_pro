import SwiftUI

struct FretboardView: View {
    let fretboard: Fretboard
    let highlightString: Int?
    let highlightFret: Int?
    let highlightColor: Color
    /// Positions already found (Find The Fret / Memory) — shown as persistent green circles.
    var foundPositions: [FretPosition] = []
    /// Scale / memory highlights: (position, color) pairs drawn as filled dots.
    var scaleHighlights: [(FretPosition, Color)] = []
    /// When non-nil, draws a gold boundary line at this fret wire.
    var difficultyBoundaryFret: Int? = nil
    /// When non-nil, each fret intersection is tappable.
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
                scaleHighlightDots
                foundPositionCircles
                highlightCircle
                fretNumbers
                stringLabels
                if onFretTap != nil { fretTapOverlay }
            }
            .frame(width: fretboardWidth, height: fretboardHeight + 28)
            .padding(.leading, 40)
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
                    colors: [Color(hex: "#4A3525"), Color(hex: "#3D2B1F"), Color(hex: "#2E1F14")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: fretboardWidth, height: fretboardHeight)
    }

    // MARK: - Nut
    private var nutView: some View {
        Rectangle()
            .fill(Color(hex: "#E8D5A3"))
            .frame(width: nutWidth, height: fretboardHeight)
    }

    // MARK: - Fret wires
    private var fretWires: some View {
        ForEach(1...fretCount, id: \.self) { fret in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#A0A0A0"), Color(hex: "#D0D0D0"), Color(hex: "#A0A0A0")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: fretboardHeight)
                .offset(x: nutWidth + CGFloat(fret) * fretWidth)
        }
    }

    // MARK: - Strings
    private var stringLines: some View {
        ForEach(0..<totalStrings, id: \.self) { stringIdx in
            let thickness = stringThickness(for: stringIdx)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#B8B8B8"), Color(hex: "#E8E8E8"), Color(hex: "#B8B8B8")],
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
        return Circle()
            .fill(Color.white.opacity(0.25))
            .frame(width: 14, height: 14)
            .offset(x: x - 7, y: y - 7)
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
            .offset(x: x - 11, y: y - 11)
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

    // MARK: - Difficulty boundary line

    private func difficultyBoundaryLine(at fret: Int) -> some View {
        Rectangle()
            .fill(Color(hex: "#FFD700"))
            .frame(width: 2, height: fretboardHeight)
            .offset(x: nutWidth + CGFloat(fret) * fretWidth)
    }

    // MARK: - Scale / memory highlight dots

    private var scaleHighlightDots: some View {
        ForEach(scaleHighlights.indices, id: \.self) { i in
            let (pos, color) = scaleHighlights[i]
            let x = fretX(fret: pos.fret)
            let y = stringY(string: pos.string)
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                .position(x: x, y: y)
        }
    }

    // MARK: - Found position circles (Find The Fret / Memory)

    private var foundPositionCircles: some View {
        ForEach(foundPositions.indices, id: \.self) { i in
            let pos = foundPositions[i]
            let x = fretX(fret: pos.fret)
            let y = stringY(string: pos.string)
            Circle()
                .fill(Color.green)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                .position(x: x, y: y)
        }
    }

    // MARK: - Fret tap overlay

    private var fretTapOverlay: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<totalStrings, id: \.self) { s in
                ForEach(0...fretboard.fretCount, id: \.self) { f in
                    Color.clear
                        .frame(width: f == 0 ? nutWidth + fretWidth / 2 : fretWidth,
                               height: stringSpacing)
                        .contentShape(Rectangle())
                        .offset(x: f == 0 ? 0 : nutWidth + CGFloat(f) * fretWidth - fretWidth / 2,
                                y: fretboardPadding + CGFloat(totalStrings - 1 - s) * stringSpacing - stringSpacing / 2)
                        .onTapGesture { onFretTap?(s, f) }
                }
            }
        }
    }

    // MARK: - Fret numbers
    private var fretNumbers: some View {
        ForEach(0...fretCount, id: \.self) { fret in
            Text("\(fret)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
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
