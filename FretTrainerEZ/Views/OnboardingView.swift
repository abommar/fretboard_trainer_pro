import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let accent = Color(hex: "#E94560")
    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: .nameTheNote,
            headline: "Name That Note",
            body: "A fret is highlighted on the neck.\nTap the correct note from the 12 buttons below."
        ),
        OnboardingPage(
            icon: .findTheFret,
            headline: "Find The Fret",
            body: "A note name is shown.\nTap every position on the neck where that note lives."
        ),
        OnboardingPage(
            icon: .studyMode,
            headline: "Study Mode",
            body: "Tap Study anytime to see all notes color-coded on the fretboard.\nTap a note button to filter to just that note."
        )
    ]

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Dots + buttons
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Circle()
                                .fill(i == page ? accent : Color.white.opacity(0.25))
                                .frame(width: i == page ? 8 : 6, height: i == page ? 8 : 6)
                                .animation(.easeInOut, value: page)
                        }
                    }

                    // Primary button
                    Button(action: advance) {
                        Text(page == pages.count - 1 ? "Get Started" : "Next")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(accent)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 32)

                    // Skip (hidden on last page)
                    if page < pages.count - 1 {
                        Button("Skip") { onFinish() }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    } else {
                        // Spacer to keep layout stable on last page
                        Color.clear.frame(height: 20)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page layout

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(cardBg)
                    .frame(width: 140, height: 140)
                    .shadow(color: accent.opacity(0.25), radius: 20)

                Canvas { ctx, size in
                    p.icon.draw(in: ctx, size: size, accent: accent)
                }
                .frame(width: 80, height: 80)
            }

            // Text
            VStack(spacing: 12) {
                Text(p.headline)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(p.body)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Navigation

    private func advance() {
        if page < pages.count - 1 {
            page += 1
        } else {
            onFinish()
        }
    }
}

// MARK: - Page model

private struct OnboardingPage {
    let icon: OnboardingIcon
    let headline: String
    let body: String
}

// MARK: - Canvas icons

private enum OnboardingIcon {
    case nameTheNote
    case findTheFret
    case studyMode

    func draw(in ctx: GraphicsContext, size: CGSize, accent: Color) {
        let w = size.width
        let h = size.height

        switch self {
        case .nameTheNote:
            drawNameTheNote(ctx: ctx, w: w, h: h, accent: accent)
        case .findTheFret:
            drawFindTheFret(ctx: ctx, w: w, h: h, accent: accent)
        case .studyMode:
            drawStudyMode(ctx: ctx, w: w, h: h, accent: accent)
        }
    }

    // Fretboard with a single highlighted dot + a question mark
    private func drawNameTheNote(ctx: GraphicsContext, w: CGFloat, h: CGFloat, accent: Color) {
        var ctx = ctx
        let stringCount = 4
        let fretCount = 4
        let boardH = h * 0.55
        let boardY = h * 0.08
        let boardX: CGFloat = w * 0.05
        let boardW = w * 0.90
        let spacing = boardH / CGFloat(stringCount - 1)

        // Board background
        var board = Path()
        board.addRoundedRect(in: CGRect(x: boardX, y: boardY, width: boardW, height: boardH),
                             cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(board, with: .color(Color(hex: "#3D1C02").opacity(0.85)))

        // Fret wires
        for f in 0...fretCount {
            let x = boardX + CGFloat(f) * boardW / CGFloat(fretCount)
            var line = Path()
            line.move(to: CGPoint(x: x, y: boardY))
            line.addLine(to: CGPoint(x: x, y: boardY + boardH))
            ctx.stroke(line, with: .color(.white.opacity(0.35)), lineWidth: f == 0 ? 3 : 1)
        }

        // Strings
        for s in 0..<stringCount {
            let y = boardY + CGFloat(s) * spacing
            var line = Path()
            line.move(to: CGPoint(x: boardX, y: y))
            line.addLine(to: CGPoint(x: boardX + boardW, y: y))
            ctx.stroke(line, with: .color(.white.opacity(0.55)), lineWidth: 1.2)
        }

        // Highlight dot (fret 2, string 1)
        let dotX = boardX + 2.5 * boardW / CGFloat(fretCount)
        let dotY = boardY + 1.0 * spacing
        ctx.fill(Path(ellipseIn: CGRect(x: dotX - 9, y: dotY - 9, width: 18, height: 18)),
                 with: .color(accent))
        ctx.stroke(Path(ellipseIn: CGRect(x: dotX - 9, y: dotY - 9, width: 18, height: 18)),
                   with: .color(.white.opacity(0.6)), lineWidth: 1.5)

        // Question mark below board
        let qText = Text("?")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(.white)
        ctx.draw(qText, at: CGPoint(x: w / 2, y: boardY + boardH + 18))
    }

    // Fretboard with multiple dots + a note label
    private func drawFindTheFret(ctx: GraphicsContext, w: CGFloat, h: CGFloat, accent: Color) {
        var ctx = ctx
        let stringCount = 4
        let fretCount = 4
        let boardH = h * 0.50
        let boardY = h * 0.08
        let boardX: CGFloat = w * 0.05
        let boardW = w * 0.90
        let spacing = boardH / CGFloat(stringCount - 1)

        // Board
        var board = Path()
        board.addRoundedRect(in: CGRect(x: boardX, y: boardY, width: boardW, height: boardH),
                             cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(board, with: .color(Color(hex: "#3D1C02").opacity(0.85)))

        // Frets
        for f in 0...fretCount {
            let x = boardX + CGFloat(f) * boardW / CGFloat(fretCount)
            var line = Path()
            line.move(to: CGPoint(x: x, y: boardY))
            line.addLine(to: CGPoint(x: x, y: boardY + boardH))
            ctx.stroke(line, with: .color(.white.opacity(0.35)), lineWidth: f == 0 ? 3 : 1)
        }

        // Strings
        for s in 0..<stringCount {
            let y = boardY + CGFloat(s) * spacing
            var line = Path()
            line.move(to: CGPoint(x: boardX, y: y))
            line.addLine(to: CGPoint(x: boardX + boardW, y: y))
            ctx.stroke(line, with: .color(.white.opacity(0.55)), lineWidth: 1.2)
        }

        // Three green dots (multiple positions of same note)
        let dotPositions: [(CGFloat, Int)] = [(0.5, 0), (1.5, 2), (3.5, 3)]
        for (fretPos, strIdx) in dotPositions {
            let dx = boardX + fretPos * boardW / CGFloat(fretCount)
            let dy = boardY + CGFloat(strIdx) * spacing
            ctx.fill(Path(ellipseIn: CGRect(x: dx - 8, y: dy - 8, width: 16, height: 16)),
                     with: .color(.green))
            ctx.stroke(Path(ellipseIn: CGRect(x: dx - 8, y: dy - 8, width: 16, height: 16)),
                       with: .color(.white.opacity(0.6)), lineWidth: 1.5)
        }

        // Note label below
        let noteLabel = Text("A#")
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundColor(accent)
        ctx.draw(noteLabel, at: CGPoint(x: w / 2, y: boardY + boardH + 18))
    }

    // Fretboard with colorful note pills on every intersection
    private func drawStudyMode(ctx: GraphicsContext, w: CGFloat, h: CGFloat, accent: Color) {
        var ctx = ctx
        let stringCount = 3
        let fretCount = 4
        let boardH = h * 0.45
        let boardY = h * 0.10
        let boardX: CGFloat = w * 0.05
        let boardW = w * 0.90
        let vSpacing = boardH / CGFloat(stringCount - 1)
        let hSpacing = boardW / CGFloat(fretCount)

        // Board
        var board = Path()
        board.addRoundedRect(in: CGRect(x: boardX, y: boardY, width: boardW, height: boardH),
                             cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(board, with: .color(Color(hex: "#3D1C02").opacity(0.85)))

        // Frets
        for f in 0...fretCount {
            let x = boardX + CGFloat(f) * hSpacing
            var line = Path()
            line.move(to: CGPoint(x: x, y: boardY))
            line.addLine(to: CGPoint(x: x, y: boardY + boardH))
            ctx.stroke(line, with: .color(.white.opacity(0.35)), lineWidth: f == 0 ? 3 : 1)
        }

        // Strings
        for s in 0..<stringCount {
            let y = boardY + CGFloat(s) * vSpacing
            var line = Path()
            line.move(to: CGPoint(x: boardX, y: y))
            line.addLine(to: CGPoint(x: boardX + boardW, y: y))
            ctx.stroke(line, with: .color(.white.opacity(0.55)), lineWidth: 1.2)
        }

        // Color pills at every intersection
        let noteColors: [Color] = [
            Color(hue: 0.0,  saturation: 0.8, brightness: 0.95),
            Color(hue: 0.08, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.17, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.25, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.33, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.50, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.58, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.67, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.75, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.83, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.91, saturation: 0.8, brightness: 0.95),
            Color(hue: 0.95, saturation: 0.8, brightness: 0.95),
        ]
        var colorIdx = 0
        for s in 0..<stringCount {
            for f in 0...fretCount {
                let px = boardX + CGFloat(f) * hSpacing - hSpacing / 2
                let py = boardY + CGFloat(s) * vSpacing
                if f == 0 { colorIdx += 1; continue }
                let pillW: CGFloat = 18
                let pillH: CGFloat = 11
                var pill = Path()
                pill.addRoundedRect(in: CGRect(x: px - pillW/2, y: py - pillH/2,
                                               width: pillW, height: pillH),
                                    cornerSize: CGSize(width: 5.5, height: 5.5))
                ctx.fill(pill, with: .color(noteColors[colorIdx % noteColors.count]))
                colorIdx += 1
            }
        }

        // "Study" label below
        let studyLabel = Text("STUDY")
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(accent)
        ctx.draw(studyLabel, at: CGPoint(x: w / 2, y: boardY + boardH + 18))
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
