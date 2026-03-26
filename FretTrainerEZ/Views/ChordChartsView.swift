import SwiftUI

struct ChordChartsView: View {
    @Environment(\.dismiss) private var dismiss

    var audioEngine: NoteAudioEngine? = nil

    @State private var selectedRoot: Note = .C
    @State private var selectedType: ChordType = .major

    @AppStorage("useFlats")     private var useFlats:     Bool = false
    @AppStorage("soundEnabled") private var soundEnabled: Bool = false

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")

    private var voicings: [ChordVoicing] {
        ChordLibrary.voicings(root: selectedRoot, type: selectedType)
    }

    /// Chord tones for the current root + type (same across all voicings)
    private var chordTones: [Note] {
        voicings.first?.chordTones ?? []
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                filtersRow
                Divider().background(Color.white.opacity(0.08))
                GeometryReader { geo in
                    HStack(alignment: .top, spacing: 0) {
                        // Left: scrollable chord diagrams — fixed to diagram width
                        diagramList
                            .frame(width: min(geo.size.width * 0.44, 175))

                        Divider().background(Color.white.opacity(0.1))

                        // Right: theory breakdown — gets the rest
                        theoryPanel
                            .frame(maxWidth: .infinity)
                    }
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
            Text("Chord Charts")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBg)
    }

    // MARK: - Filter row

    private var filtersRow: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Note.allCases, id: \.self) { note in
                        noteChip(note)
                    }
                }
                .padding(.horizontal, 16)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ChordType.allCases) { type in
                        typeChip(type)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .background(cardBg.opacity(0.6))
    }

    private func noteChip(_ note: Note) -> some View {
        let selected = note == selectedRoot
        return Button(action: { selectedRoot = note }) {
            Text(useFlats ? note.flatName : note.sharpName)
                .font(.system(size: 13, weight: selected ? .bold : .medium, design: .rounded))
                .foregroundColor(selected ? .white : .white.opacity(0.55))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(selected ? accent : Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
    }

    private func typeChip(_ type: ChordType) -> some View {
        let selected = type == selectedType
        return Button(action: { selectedType = type }) {
            Text(type.rawValue)
                .font(.system(size: 12, weight: selected ? .bold : .medium))
                .foregroundColor(selected ? .white : .white.opacity(0.55))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(selected ? Color(hex: "#2A2A6A") : Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(selected ? accent.opacity(0.6) : Color.clear, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Left: diagram list

    private var diagramList: some View {
        Group {
            if voicings.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No voicings yet")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(voicings) { voicing in
                            ChordDiagramView(voicing: voicing)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    // MARK: - Right: theory breakdown

    private var theoryPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // Chord name + character as subtitle
                let rootName = useFlats ? selectedRoot.flatName : selectedRoot.sharpName
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(rootName)\(selectedType.suffix)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(selectedType.mood)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.45))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button {
                        strumChord()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text("Play")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(soundEnabled ? accent : .white.opacity(0.25))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(soundEnabled ? accent.opacity(0.15) : Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!soundEnabled)
                    .opacity(soundEnabled ? 1.0 : 0.4)
                }

                Divider().background(Color.white.opacity(0.1))

                // Notes + Intervals side by side
                HStack(alignment: .top, spacing: 16) {
                    // Left: note pills
                    if !chordTones.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("NOTES")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.35))
                            HStack(spacing: 6) {
                                ForEach(Array(zip(chordTones, selectedType.degreeSymbols).enumerated()), id: \.offset) { _, pair in
                                    let (note, degree) = pair
                                    let hue    = Double(note.rawValue) / 12.0
                                    let pillBg = Color(hue: hue, saturation: 0.80, brightness: 0.95)
                                    let fg: Color = (hue > 0.14 && hue < 0.56) ? .black.opacity(0.85) : .white
                                    VStack(spacing: 2) {
                                        Text(useFlats ? note.flatName : note.sharpName)
                                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                                            .foregroundColor(fg)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(pillBg))
                                        Text(degree)
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                        }
                    }

                    // Right: interval names
                    VStack(alignment: .leading, spacing: 5) {
                        Text("INTERVALS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                        ForEach(Array(zip(selectedType.degreeSymbols, selectedType.degreeNames).enumerated()), id: \.offset) { _, pair in
                            let (symbol, name) = pair
                            HStack(spacing: 6) {
                                Text(symbol)
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(accent)
                                    .frame(width: 20, alignment: .leading)
                                Text(name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .animation(.easeInOut(duration: 0.15), value: selectedType)
        .animation(.easeInOut(duration: 0.15), value: selectedRoot)
    }

    // MARK: - Strum

    private func strumChord() {
        guard let engine = audioEngine, let voicing = voicings.first else { return }
        let delay = 0.08
        for (index, fret) in voicing.frets.enumerated() {
            guard let f = fret else { continue }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * Double(index)) {
                engine.play(string: index, fret: f)
            }
        }
    }
}

// MARK: - Chord diagram card

struct ChordDiagramView: View {
    let voicing: ChordVoicing

    private let stringCount = 6
    private let fretRows    = 5
    private let cellW: CGFloat = 26
    private let cellH: CGFloat = 20
    private let nutH: CGFloat  = 5

    private let cardBg = Color(hex: "#16213E")
    private let woodBg = Color(hex: "#2E1F14")

    var body: some View {
        VStack(spacing: 6) {
            Text(voicing.name)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            diagramBody
                .frame(height: CGFloat(fretRows) * cellH + nutH + 24)

            if voicing.baseFret > 1 {
                Text("fr \(voicing.baseFret)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(cardBg))
    }

    private var diagramBody: some View {
        let totalW = CGFloat(stringCount - 1) * cellW
        let totalH = CGFloat(fretRows) * cellH

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(woodBg)
                .frame(width: totalW, height: totalH)
                .offset(y: nutH)

            if voicing.baseFret == 1 {
                Rectangle()
                    .fill(Color(hex: "#E8D5A3"))
                    .frame(width: totalW, height: nutH)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: totalW, height: 2)
                    .offset(y: nutH / 2)
            }

            ForEach(1...fretRows, id: \.self) { fret in
                Rectangle()
                    .fill(Color(hex: "#888888").opacity(0.7))
                    .frame(width: totalW, height: 1.5)
                    .offset(y: nutH + CGFloat(fret) * cellH)
            }

            ForEach(0..<stringCount, id: \.self) { s in
                Rectangle()
                    .fill(Color(hex: "#C0C0C0").opacity(0.8))
                    .frame(width: 1.5, height: totalH)
                    .offset(x: CGFloat(s) * cellW - 0.75, y: nutH)
            }

            ForEach(0..<stringCount, id: \.self) { s in
                let fret = voicing.frets[s]
                Group {
                    if fret == nil {
                        Text("×")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                    } else if fret == 0 {
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                            .frame(width: 8, height: 8)
                    }
                }
                .offset(x: CGFloat(s) * cellW - 5, y: -14)
            }

            ForEach(0..<stringCount, id: \.self) { s in
                if let fret = voicing.frets[s], fret > 0 {
                    let adj = fret - voicing.baseFret + 1
                    if adj >= 1 && adj <= fretRows {
                        Circle()
                            .fill(Color(hex: "#E94560"))
                            .frame(width: 14, height: 14)
                            .offset(x: CGFloat(s) * cellW - 7,
                                    y: nutH + CGFloat(adj - 1) * cellH + (cellH - 14) / 2)
                    }
                }
            }
        }
        .frame(width: totalW, height: totalH + nutH + 18)
        .padding(.top, 18)
    }
}
