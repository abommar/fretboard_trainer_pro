import SwiftUI

struct FretboardStyleView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStyle: FretboardStyle

    private let accent = Color(hex: "#E94560")
    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accent)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Fretboard Style")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    // Balance the back button
                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider().background(Color.white.opacity(0.1))

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(FretboardStyle.allCases) { style in
                            styleRow(style)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func styleRow(_ style: FretboardStyle) -> some View {
        let isSelected = style == selectedStyle
        return Button(action: { selectedStyle = style }) {
            HStack(spacing: 14) {
                MiniStylePreview(style: style)
                    .frame(width: 160, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? accent : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(style.descriptor)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(accent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? cardBg : Color.white.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selectedStyle)
    }
}

// MARK: - Mini canvas preview

private struct MiniStylePreview: View {
    let style: FretboardStyle

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let nutW: CGFloat = 6
            let fretCount = 6

            // Board background
            let boardRect = CGRect(x: nutW, y: 0, width: w - nutW, height: h)
            ctx.fill(
                Path(boardRect),
                with: .linearGradient(
                    Gradient(colors: style.boardColors),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )

            // Nut
            ctx.fill(Path(CGRect(x: 0, y: 0, width: nutW, height: h)),
                     with: .color(style.nutColor))

            // Fret wires
            let fretSpacing = (w - nutW) / CGFloat(fretCount)
            for i in 1...fretCount {
                let x = nutW + CGFloat(i) * fretSpacing
                ctx.fill(Path(CGRect(x: x - 0.75, y: 0, width: 1.5, height: h)),
                         with: .color(style.fretColors[1]))
            }

            // Strings (6)
            let stringCount = 6
            let stringSpacing = h / CGFloat(stringCount + 1)
            for i in 1...stringCount {
                let y = CGFloat(i) * stringSpacing
                let thickness: CGFloat = i <= 3 ? 1.5 : 1.0
                ctx.fill(Path(CGRect(x: 0, y: y - thickness / 2, width: w, height: thickness)),
                         with: .color(style.stringColors[1]))
            }

            // Pearl inlay dots at fret 2 and 4
            let dotR: CGFloat = 4
            for fret in [2, 4] {
                let x = nutW + (CGFloat(fret) - 0.5) * fretSpacing
                let y = h / 2
                let dotRect = CGRect(x: x - dotR, y: y - dotR, width: dotR * 2, height: dotR * 2)
                // Base cream
                var base = Path(); base.addEllipse(in: dotRect)
                ctx.fill(base, with: .color(Color(hex: "#EDE8E0")))
                // Shimmer
                ctx.fill(base, with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.9), Color(hex: "#C8E8F0").opacity(0.5), Color.clear]),
                    center: CGPoint(x: x - dotR * 0.3, y: y - dotR * 0.3),
                    startRadius: 0, endRadius: dotR * 1.2
                ))
            }
        }
    }
}
