import SwiftUI

struct CircleOfFifthsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndex: Int? = nil
    @AppStorage("useFlats") private var useFlats: Bool = false

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                bg.ignoresSafeArea()
                if isLandscape {
                    landscapeBody(geo: geo)
                } else {
                    portraitBody
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Portrait layout

    private var portraitBody: some View {
        VStack(spacing: 0) {
            navBar
            ScrollView {
                VStack(spacing: 20) {
                    circleCanvas(maxSize: 340)
                        .padding(.top, 12)
                    if let idx = selectedIndex {
                        keyDetailCard(idx)
                            .padding(.horizontal, 16)
                    } else {
                        Text("Tap a key to explore its chords")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.top, 4)
                    }
                }
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Landscape layout

    private func landscapeBody(geo: GeometryProxy) -> some View {
        // Circle fits in the left panel (square: available height minus navBar)
        let navBarH: CGFloat = 44
        let circleSize = min(geo.size.height - navBarH - 16, 300)

        return VStack(spacing: 0) {
            navBar
            Divider().background(Color.white.opacity(0.08))
            HStack(spacing: 0) {
                // Left: circle (fixed square)
                ScrollView {
                    circleCanvas(maxSize: circleSize)
                        .padding(8)
                }
                .frame(width: circleSize + 16)

                Divider().background(Color.white.opacity(0.1))

                // Right: detail card or hint
                ScrollView {
                    if let idx = selectedIndex {
                        keyDetailCard(idx)
                            .padding(12)
                    } else {
                        Text("Tap a key to explore its chords")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 40)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accent)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Circle of Fifths")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBg)
    }

    // MARK: - Circle canvas

    private func circleCanvas(maxSize: CGFloat) -> some View {
        GeometryReader { geo in
            let size = min(geo.size.width, maxSize)
            let center = CGPoint(x: size / 2, y: size / 2)
            ZStack {
                drawWedges(size: size, center: center)
                drawLabels(size: size, center: center)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { location in
                handleTap(at: location, size: size, center: center)
            }
        }
        .frame(height: maxSize)
    }

    // MARK: - Wedge drawing

    private func wedgePath(center: CGPoint, innerR: CGFloat, outerR: CGFloat,
                           start: Double, end: Double) -> Path {
        var path = Path()
        path.move(to: point(center: center, r: innerR, angle: start))
        path.addArc(center: center, radius: innerR, startAngle: .radians(start),
                    endAngle: .radians(end), clockwise: false)
        path.addLine(to: point(center: center, r: outerR, angle: end))
        path.addArc(center: center, radius: outerR, startAngle: .radians(end),
                    endAngle: .radians(start), clockwise: true)
        path.closeSubpath()
        return path
    }

    private func drawWedge(ctx: GraphicsContext, center: CGPoint,
                           innerR: CGFloat, outerR: CGFloat,
                           start: Double, end: Double, fill: Color) {
        let path = wedgePath(center: center, innerR: innerR, outerR: outerR, start: start, end: end)
        ctx.fill(path, with: .color(fill))
        ctx.stroke(path, with: .color(Color.black.opacity(0.4)), lineWidth: 1)
    }

    private func drawWedges(size: CGFloat, center: CGPoint) -> some View {
        let keys       = MusicTheory.circleOfFifths
        let count      = keys.count
        let sliceAngle = 2 * Double.pi / Double(count)
        let startOffset = -Double.pi / 2

        let outerR = size * 0.46
        let midR   = size * 0.30
        let innerR = size * 0.17

        // Precompute diatonic position map (empty when nothing selected)
        let sel = selectedIndex
        let fnMap: [Int: ChordFunction] = sel.map { MusicTheory.diatonicCirclePositions(forKeyAt: $0) } ?? [:]
        let hasSelection = sel != nil

        // Function colours — captured as value types in the Canvas @Sendable closure
        let tonicClr      = Color(hex: "#2ECC71")
        let subdomClr     = Color(hex: "#4499FF")
        let dominantClr   = Color(hex: "#FF8C00")

        func fc(_ fn: ChordFunction) -> Color {
            switch fn {
            case .tonic:       return tonicClr
            case .subdominant: return subdomClr
            case .dominant:    return dominantClr
            }
        }

        return Canvas { ctx, _ in
            for i in 0..<count {
                let start = startOffset + Double(i) * sliceAngle - sliceAngle / 2
                let end   = start + sliceAngle

                let isSelected = sel == i
                let isDiatonic = fnMap[i] != nil
                let baseAlpha: Double = hasSelection ? (isDiatonic || isSelected ? 0.88 : 0.20) : 0.75

                // 1. Base outer (major) wedge
                let outerBase = Color(hue: Double(i)/12.0, saturation: 0.55, brightness: 0.45)
                drawWedge(ctx: ctx, center: center, innerR: midR, outerR: outerR,
                          start: start, end: end, fill: outerBase.opacity(baseAlpha))

                // 2. Base inner (relative minor) wedge
                let innerBase = Color(hue: Double(i)/12.0, saturation: 0.35, brightness: 0.30)
                drawWedge(ctx: ctx, center: center, innerR: innerR, outerR: midR,
                          start: start, end: end, fill: innerBase.opacity(baseAlpha))

                // 3. Chord-function colour overlay for diatonic positions
                if let fn = fnMap[i] {
                    let overlay = fc(fn).opacity(0.32)
                    drawWedge(ctx: ctx, center: center, innerR: midR, outerR: outerR,
                              start: start, end: end, fill: overlay)
                    drawWedge(ctx: ctx, center: center, innerR: innerR, outerR: midR,
                              start: start, end: end, fill: overlay)
                }

                // 4. White selection border (drawn last = on top)
                if isSelected {
                    let op = wedgePath(center: center, innerR: midR, outerR: outerR,
                                       start: start, end: end)
                    ctx.stroke(op, with: .color(Color.white.opacity(0.85)), lineWidth: 2.5)
                    let ip = wedgePath(center: center, innerR: innerR, outerR: midR,
                                       start: start, end: end)
                    ctx.stroke(ip, with: .color(Color.white.opacity(0.85)), lineWidth: 2.5)
                }
            }

            // Center circle
            let cp = Path(ellipseIn: CGRect(x: center.x - innerR, y: center.y - innerR,
                                            width: innerR * 2, height: innerR * 2))
            ctx.fill(cp, with: .color(Color(hex: "#0D0D1E")))
            ctx.stroke(cp, with: .color(Color.white.opacity(0.15)), lineWidth: 1)
        }
    }

    private func point(center: CGPoint, r: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
    }

    // MARK: - Labels overlay

    private func drawLabels(size: CGFloat, center: CGPoint) -> some View {
        let keys       = MusicTheory.circleOfFifths
        let count      = keys.count
        let sliceAngle = 2 * Double.pi / Double(count)
        let startOffset = -Double.pi / 2

        let outerR = size * 0.46
        let midR   = size * 0.30
        let innerR = size * 0.17

        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let midAngle = startOffset + Double(i) * sliceAngle
                let key = keys[i]

                // Major label
                let majorR = (midR + outerR) / 2
                let majorPos = point(center: center, r: majorR, angle: midAngle)
                Text(MusicTheory.enharmonicLabel(for: key.major, position: i))
                    .font(.system(size: outerR > 60 ? 12 : 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .position(majorPos)

                // Relative minor label
                let minorR = (innerR + midR) / 2
                let minorPos = point(center: center, r: minorR, angle: midAngle)
                Text(MusicTheory.relativeLabel(for: key.relative, position: i))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .position(minorPos)
            }

            // Center label
            VStack(spacing: 1) {
                Text("Circle")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text("of 5ths")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .position(center)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Tap handling

    private func handleTap(at location: CGPoint, size: CGFloat, center: CGPoint) {
        let dx   = location.x - center.x
        let dy   = location.y - center.y
        let dist = sqrt(dx * dx + dy * dy)

        let innerR = size * 0.17
        let outerR = size * 0.46
        guard dist >= innerR && dist <= outerR else {
            selectedIndex = nil
            return
        }

        var angle = atan2(dy, dx)
        angle += Double.pi / 2
        if angle < 0 { angle += 2 * Double.pi }

        let sliceAngle = 2 * Double.pi / 12.0
        let index = Int((angle / sliceAngle).rounded()) % 12
        selectedIndex = (selectedIndex == index) ? nil : index
    }

    // MARK: - Detail card

    private func keyDetailCard(_ index: Int) -> some View {
        let key        = MusicTheory.circleOfFifths[index]
        let accidental = MusicTheory.accidentalLabel(sharpsOrFlats: key.sharpsOrFlats)
        let chords     = MusicTheory.diatonicChords(forKeyAt: index, useFlats: useFlats)

        return VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(MusicTheory.enharmonicLabel(for: key.major, position: index))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Major  ·  \(accidental == "0" ? "No ♯/♭" : accidental)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(MusicTheory.relativeLabel(for: key.relative, position: index))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Relative minor")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Diatonic chords section
            Text("DIATONIC CHORDS")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(chords.enumerated()), id: \.offset) { _, chord in
                        chordPill(chord)
                    }
                }
            }

            // Function legend
            HStack(spacing: 14) {
                legendItem(color: Color(hex: "#2ECC71"), label: "Tonic")
                legendItem(color: Color(hex: "#4499FF"), label: "Subdominant")
                legendItem(color: Color(hex: "#FF8C00"), label: "Dominant")
            }

            Divider().background(Color.white.opacity(0.1))

            // Common progressions section
            Text("COMMON PROGRESSIONS")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(MusicTheory.commonProgressions.enumerated()), id: \.offset) { _, prog in
                    progressionCard(prog, chords: chords)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(outerColor(for: index).opacity(0.6), lineWidth: 1.5))
        .animation(.easeInOut(duration: 0.2), value: index)
    }

    private func chordPill(_ chord: DiatonicChord) -> some View {
        let col = functionColor(chord.chordFunction)
        return VStack(spacing: 3) {
            Text(chord.numeral)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(col)
            Text(chord.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(col.opacity(0.18))
                        .overlay(Capsule().stroke(col.opacity(0.55), lineWidth: 1))
                )
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private func progressionCard(_ prog: Progression, chords: [DiatonicChord]) -> some View {
        let resolved = prog.indices
            .filter { $0 < chords.count }
            .map { chords[$0].name }
            .joined(separator: " – ")

        return VStack(alignment: .leading, spacing: 4) {
            Text(prog.name)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(accent)
            Text(prog.style)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
            Text(resolved)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Colour helpers

    private func outerColor(for index: Int) -> Color {
        Color(hue: Double(index) / 12.0, saturation: 0.55, brightness: 0.45)
    }

    private func functionColor(_ fn: ChordFunction) -> Color {
        switch fn {
        case .tonic:       return Color(hex: "#2ECC71")
        case .subdominant: return Color(hex: "#4499FF")
        case .dominant:    return Color(hex: "#FF8C00")
        }
    }
}
