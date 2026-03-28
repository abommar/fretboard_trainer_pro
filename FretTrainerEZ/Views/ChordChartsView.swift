import SwiftUI

struct ChordChartsView: View {
    let audioEngine: NoteAudioEngine

    @Environment(\.dismiss) private var dismiss

    @AppStorage("soundEnabled") private var soundEnabled: Bool = false

    @State private var selectedRoot: Note = .C
    @State private var selectedType: ChordType = .major

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")

    private var voicings: [ChordVoicing] {
        ChordLibrary.voicings(root: selectedRoot, type: selectedType)
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                filtersRow
                Divider().background(Color.white.opacity(0.08))
                chordContent
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
            // Root note picker — two fixed rows of 6 so all 12 are always visible
            let notes = Note.allCases
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(notes.prefix(6), id: \.self) { noteChip($0) }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 6) {
                    ForEach(notes.dropFirst(6), id: \.self) { noteChip($0) }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)

            // Chord type picker (scrollable — 7 types, fits most screens)
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
            Text(note.sharpName)
                .font(.system(size: 13, weight: selected ? .bold : .medium, design: .rounded))
                .foregroundColor(selected ? .white : .white.opacity(0.55))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? accent : Color.white.opacity(0.07))
                )
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(selected ? accent.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Strum

    private func strumChord(_ voicing: ChordVoicing) {
        for (stringIdx, fret) in voicing.frets.enumerated() {
            guard let fret else { continue }
            let delay = Double(stringIdx) * 0.08
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                audioEngine.play(string: stringIdx, fret: fret)
            }
        }
    }

    // MARK: - Chord content

    @ViewBuilder
    private var chordContent: some View {
        if voicings.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.15))
                Text("No voicings in library yet")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.35))
                Spacer()
            }
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(voicings) { voicing in
                        ChordDiagramView(voicing: voicing) {
                            guard soundEnabled else { return }
                            strumChord(voicing)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Chord diagram

struct ChordDiagramView: View {
    let voicing: ChordVoicing
    var onPlay: (() -> Void)? = nil

    private let stringCount  = 6
    private let fretRows     = 5
    private let cellW: CGFloat = 28
    private let cellH: CGFloat = 22
    private let nutH: CGFloat  = 5

    private let cardBg = Color(hex: "#16213E")
    private let woodBg = Color(hex: "#2E1F14")

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(voicing.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                if let onPlay {
                    Button(action: onPlay) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#E94560"))
                    }
                    .buttonStyle(.plain)
                }
            }

            chordTonesRow

            diagramBody
                .frame(height: CGFloat(fretRows) * cellH + nutH + 28)

            if voicing.baseFret > 1 {
                Text("fr \(voicing.baseFret)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardBg))
    }

    private var chordTonesRow: some View {
        HStack(spacing: 4) {
            ForEach(voicing.chordTones, id: \.rawValue) { note in
                let hue = Double(note.rawValue) / 12.0
                let bg = Color(hue: hue, saturation: 0.80, brightness: 0.95)
                let fg: Color = (hue > 0.14 && hue < 0.56) ? Color.black.opacity(0.85) : .white
                Text(note.sharpName)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(fg)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(bg))
            }
        }
    }

    private var diagramBody: some View {
        let totalW = CGFloat(stringCount - 1) * cellW
        let totalH = CGFloat(fretRows) * cellH

        return ZStack(alignment: .topLeading) {
            // Fretboard background
            Rectangle()
                .fill(woodBg)
                .frame(width: totalW, height: totalH)
                .offset(y: nutH)

            // Nut or fret indicator
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

            // Fret wires
            ForEach(1...fretRows, id: \.self) { fret in
                Rectangle()
                    .fill(Color(hex: "#888888").opacity(0.7))
                    .frame(width: totalW, height: 1.5)
                    .offset(y: nutH + CGFloat(fret) * cellH)
            }

            // String lines
            ForEach(0..<stringCount, id: \.self) { s in
                Rectangle()
                    .fill(Color(hex: "#C0C0C0").opacity(0.8))
                    .frame(width: 1.5, height: totalH)
                    .offset(x: CGFloat(s) * cellW - 0.75, y: nutH)
            }

            // Muted / open indicators above nut
            ForEach(0..<stringCount, id: \.self) { s in
                let fret = voicing.frets[s]
                Group {
                    if fret == nil {
                        // X for muted
                        Text("×")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                    } else if fret == 0 {
                        // Circle for open
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                            .frame(width: 9, height: 9)
                    }
                }
                .offset(x: CGFloat(s) * cellW - 6,
                        y: -16)
            }

            // Finger dots
            ForEach(0..<stringCount, id: \.self) { s in
                if let fret = voicing.frets[s], fret > 0 {
                    let adjustedFret = fret - voicing.baseFret + 1
                    if adjustedFret >= 1 && adjustedFret <= fretRows {
                        Circle()
                            .fill(Color(hex: "#E94560"))
                            .frame(width: 16, height: 16)
                            .offset(x: CGFloat(s) * cellW - 8,
                                    y: nutH + CGFloat(adjustedFret - 1) * cellH + (cellH - 16) / 2)
                    }
                }
            }
        }
        .frame(width: totalW, height: totalH + nutH + 20)
        .padding(.top, 20) // space for open/muted symbols
    }
}
