import SwiftUI

struct CircleOfFifthsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndex: Int? = nil

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 20) {
                        circleCanvas
                            .padding(.top, 12)
                        if let idx = selectedIndex {
                            keyDetailCard(idx)
                                .padding(.horizontal, 20)
                        } else {
                            Text("Tap a key to see details")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.35))
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
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
            // Balance the back button
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBg)
    }

    // MARK: - Circle canvas

    private var circleCanvas: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, 340)
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
        .frame(height: 340)
    }

    // MARK: - Wedge drawing

    private func drawWedges(size: CGFloat, center: CGPoint) -> some View {
        let keys = MusicTheory.circleOfFifths
        let count = keys.count
        let sliceAngle = 2 * Double.pi / Double(count)
        let startOffset = -Double.pi / 2   // 12 o'clock = 0

        return Canvas { ctx, _ in
            // Outer ring (major keys) radius
            let outerR = size * 0.46
            let midR   = size * 0.30
            let innerR = size * 0.17

            for i in 0..<count {
                let start = startOffset + Double(i) * sliceAngle - sliceAngle / 2
                let end   = start + sliceAngle

                // Outer wedge
                let outerFill = outerColor(for: i)
                drawWedge(ctx: ctx, center: center, innerR: midR, outerR: outerR,
                          start: start, end: end, fill: outerFill,
                          highlighted: selectedIndex == i)

                // Inner wedge (relative minor)
                drawWedge(ctx: ctx, center: center, innerR: innerR, outerR: midR,
                          start: start, end: end, fill: innerColor(for: i),
                          highlighted: selectedIndex == i)
            }

            // Center circle
            let cp = Path(ellipseIn: CGRect(x: center.x - innerR, y: center.y - innerR,
                                            width: innerR * 2, height: innerR * 2))
            ctx.fill(cp, with: .color(Color(hex: "#0D0D1E")))
            ctx.stroke(cp, with: .color(Color.white.opacity(0.15)), lineWidth: 1)
        }
    }

    private func outerColor(for index: Int) -> Color {
        let hue = Double(index) / 12.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.45)
    }

    private func innerColor(for index: Int) -> Color {
        let hue = Double(index) / 12.0
        return Color(hue: hue, saturation: 0.35, brightness: 0.30)
    }

    private func drawWedge(ctx: GraphicsContext, center: CGPoint,
                           innerR: CGFloat, outerR: CGFloat,
                           start: Double, end: Double,
                           fill: Color, highlighted: Bool) {
        var path = Path()
        path.move(to: point(center: center, r: innerR, angle: start))
        path.addArc(center: center, radius: innerR, startAngle: .radians(start),
                    endAngle: .radians(end), clockwise: false)
        path.addLine(to: point(center: center, r: outerR, angle: end))
        path.addArc(center: center, radius: outerR, startAngle: .radians(end),
                    endAngle: .radians(start), clockwise: true)
        path.closeSubpath()

        ctx.fill(path, with: .color(highlighted ? fill.opacity(1.0) : fill.opacity(0.75)))
        ctx.stroke(path, with: .color(Color.black.opacity(0.4)), lineWidth: 1)
        if highlighted {
            ctx.stroke(path, with: .color(Color.white.opacity(0.7)), lineWidth: 2)
        }
    }

    private func point(center: CGPoint, r: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
    }

    // MARK: - Labels overlay

    private func drawLabels(size: CGFloat, center: CGPoint) -> some View {
        let keys = MusicTheory.circleOfFifths
        let count = keys.count
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
        let dx = location.x - center.x
        let dy = location.y - center.y
        let dist = sqrt(dx * dx + dy * dy)

        let innerR = size * 0.17
        let outerR = size * 0.46
        guard dist >= innerR && dist <= outerR else {
            selectedIndex = nil
            return
        }

        var angle = atan2(dy, dx)  // -π to π, 0 = right
        angle += Double.pi / 2     // rotate so 0 = up
        if angle < 0 { angle += 2 * Double.pi }

        let sliceAngle = 2 * Double.pi / 12.0
        let index = Int((angle / sliceAngle).rounded()) % 12
        selectedIndex = (selectedIndex == index) ? nil : index
    }

    // MARK: - Detail card

    private func keyDetailCard(_ index: Int) -> some View {
        let key = MusicTheory.circleOfFifths[index]
        let accidental = MusicTheory.accidentalLabel(sharpsOrFlats: key.sharpsOrFlats)

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(MusicTheory.enharmonicLabel(for: key.major, position: index))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Major")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(MusicTheory.relativeLabel(for: key.relative, position: index))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Relative minor")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Divider().background(Color.white.opacity(0.1))

            HStack {
                infoChip(label: "Key sig.", value: accidental == "0" ? "No #/b" : accidental)
                Spacer()
                infoChip(label: "Position", value: "\(index + 1) of 12")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(outerColor(for: index).opacity(0.6), lineWidth: 1.5))
        .animation(.easeInOut(duration: 0.2), value: index)
    }

    private func infoChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
