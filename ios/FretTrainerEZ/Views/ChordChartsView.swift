import SwiftUI

struct ChordChartsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRoot: Note = .C
    @State private var selectedType: ChordType = .major

    @AppStorage("useFlats") private var useFlats: Bool = false

    @State private var audioEngine = NoteAudioEngine()

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

    private func playChord(_ voicing: ChordVoicing) {
        for (index, fret) in voicing.frets.enumerated() {
            guard let fret else { continue }
            let delay = Double(index) * 0.045
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                audioEngine.play(string: index, fret: fret)
            }
        }
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
                            VStack(spacing: 6) {
                                ChordDiagramView(voicing: voicing)
                                Button(action: { playChord(voicing) }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10))
                                        Text("Play")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 7)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(accent))
                                }
                                .buttonStyle(.plain)
                            }
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

// MARK: - Chord Jam

private struct SongChordPreset: Identifiable {
    let id: String
    let title: String
    let voicing: ChordVoicing
}

struct ArrangedChord: Identifiable, Equatable {
    let id: UUID
    let presetID: String

    init(id: UUID = UUID(), presetID: String) {
        self.id = id
        self.presetID = presetID
    }
}

enum ChordJamArrangementEngine {
    static func apply(
        arrangement: [ArrangedChord],
        payloads: [String],
        targetIndex: Int,
        validPresetIDs: Set<String>
    ) -> [ArrangedChord] {
        var updated = arrangement
        var insertIndex = max(0, min(targetIndex, updated.count))

        for payload in payloads {
            if payload.hasPrefix("arranged:") {
                let raw = String(payload.dropFirst("arranged:".count))
                guard let id = UUID(uuidString: raw),
                      let currentIndex = updated.firstIndex(where: { $0.id == id }) else { continue }

                let moving = updated.remove(at: currentIndex)
                if currentIndex < insertIndex { insertIndex -= 1 }
                updated.insert(moving, at: max(0, min(insertIndex, updated.count)))
                insertIndex += 1
            } else if payload.hasPrefix("preset:") {
                let presetID = String(payload.dropFirst("preset:".count))
                guard validPresetIDs.contains(presetID) else { continue }
                updated.insert(ArrangedChord(presetID: presetID), at: max(0, min(insertIndex, updated.count)))
                insertIndex += 1
            }
        }

        return updated
    }
}

struct SongGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("useFlats") private var useFlats: Bool = false

    @State private var audioEngine = NoteAudioEngine()
    @State private var arrangement: [ArrangedChord] = []

    private let accent = Color(hex: "#E94560")
    private let bg = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    private var isLandscape: Bool { verticalSizeClass == .compact }

    private var presets: [SongChordPreset] {
        func preset(_ root: Note, _ type: ChordType) -> SongChordPreset {
            let voicing = ChordLibrary.voicings(root: root, type: type).first!
            let name = "\(useFlats ? root.flatName : root.sharpName)\(type.suffix)"
            return SongChordPreset(id: "\(root.rawValue)-\(type.rawValue)", title: name, voicing: voicing)
        }

        return [
            preset(.C, .major),
            preset(.G, .major),
            preset(.D, .major),
            preset(.A, .major),
            preset(.E, .major),
            preset(.F, .major),
            preset(.A, .minor),
            preset(.E, .minor),
            preset(.D, .minor),
            preset(.B, .minor),
            preset(.C, .dominant7),
            preset(.G, .dominant7),
            preset(.D, .dominant7),
            preset(.A, .dominant7),
            preset(.E, .dominant7),
            preset(.F, .major7),
            preset(.G, .major7),
            preset(.C, .major7),
            preset(.A, .minor7),
            preset(.D, .minor7),
        ]
    }

    private var presetByID: [String: SongChordPreset] {
        Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            GeometryReader { geo in
                VStack(spacing: 0) {
                    navBar
                    Divider().background(Color.white.opacity(0.08))
                    if isLandscape {
                        landscapeBody
                    } else {
                        portraitBody(contentHeight: geo.size.height)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func portraitBody(contentHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            arrangementPanel
                .frame(height: contentHeight * 0.44)
            Divider().background(Color.white.opacity(0.08))
            palettePanel
        }
    }

    private var landscapeBody: some View {
        HStack(spacing: 0) {
            arrangementPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider().background(Color.white.opacity(0.08))
            palettePanel
                .frame(width: 330)
                .frame(maxHeight: .infinity)
        }
    }

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

            Text("Chord Jam")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button("Clear") { arrangement.removeAll() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(arrangement.isEmpty ? .white.opacity(0.35) : accent)
                .disabled(arrangement.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBg)
    }

    private var arrangementPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            let columns = [GridItem(.adaptive(minimum: 86), spacing: 8, alignment: .leading)]
            Text("YOUR PROGRESSION")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.45))
                .tracking(1.2)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(Array(arrangement.enumerated()), id: \.element.id) { idx, item in
                        if let preset = presetByID[item.presetID] {
                            arrangedChip(preset: preset, item: item)
                                .dropDestination(for: String.self) { items, _ in
                                    handleDrop(items, targetIndex: idx)
                                }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in
                handleDrop(items, targetIndex: arrangement.count)
            }

            if arrangement.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 26))
                        .foregroundColor(.white.opacity(0.25))
                    Text("Tap to add chords and build your song")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 24)
            }
        }
        .background(cardBg.opacity(0.5))
    }

    private var palettePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("20 COMMON CHORDS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.45))
                .tracking(1.2)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(presets) { preset in
                        paletteChip(preset: preset)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(cardBg.opacity(0.35))
    }

    private func chordTypeColor(for type: ChordType) -> Color {
        switch type {
        case .major:     return Color(red: 0.29, green: 0.56, blue: 0.89)  // steel blue
        case .minor:     return Color(red: 0.66, green: 0.34, blue: 0.97)  // purple
        case .dominant7: return Color(red: 0.95, green: 0.62, blue: 0.08)  // amber
        case .major7:    return Color(red: 0.07, green: 0.73, blue: 0.52)  // teal
        case .minor7:    return Color(red: 0.55, green: 0.37, blue: 0.97)  // violet
        case .sus2:      return Color(red: 0.04, green: 0.72, blue: 0.85)  // cyan
        case .sus4:      return Color(red: 0.09, green: 0.65, blue: 0.92)  // sky
        }
    }

    private func arrangedChip(preset: SongChordPreset, item: ArrangedChord) -> some View {
        let typeColor = chordTypeColor(for: preset.voicing.type)
        let rootText  = useFlats ? preset.voicing.root.flatName : preset.voicing.root.sharpName
        let suffix    = preset.voicing.type.suffix

        return Button(action: { playChord(preset.voicing) }) {
            VStack(spacing: 0) {
                // Thin color bar at top
                typeColor
                    .frame(height: 3)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))

                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(rootText)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            if !suffix.isEmpty {
                                Text(suffix)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(typeColor)
                                    .baselineOffset(1)
                            }
                        }
                        Text(preset.voicing.type.rawValue)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                        .foregroundColor(typeColor.opacity(0.85))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [typeColor.opacity(0.22), typeColor.opacity(0.08)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(typeColor.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .draggable("arranged:\(item.id.uuidString)")
        .contextMenu {
            Button("Remove") {
                arrangement.removeAll { $0.id == item.id }
            }
        }
    }

    private func paletteChip(preset: SongChordPreset) -> some View {
        let typeColor = chordTypeColor(for: preset.voicing.type)
        let rootText  = useFlats ? preset.voicing.root.flatName : preset.voicing.root.sharpName
        let suffix    = preset.voicing.type.suffix

        return VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(rootText)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(typeColor)
                        .baselineOffset(1)
                }
            }
            Text(preset.voicing.type.rawValue)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(typeColor.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [typeColor.opacity(0.18), typeColor.opacity(0.06)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(typeColor.opacity(0.38), lineWidth: 1)
                )
                .overlay(alignment: .top) {
                    typeColor.opacity(0.3)
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                        .padding(.top, 1)
                }
        )
        .draggable("preset:\(preset.id)")
        .onTapGesture {
            arrangement.append(ArrangedChord(presetID: preset.id))
        }
    }

    private func handleDrop(_ payloads: [String], targetIndex: Int) -> Bool {
        arrangement = ChordJamArrangementEngine.apply(
            arrangement: arrangement,
            payloads: payloads,
            targetIndex: targetIndex,
            validPresetIDs: Set(presetByID.keys)
        )
        return true
    }

    private func playChord(_ voicing: ChordVoicing) {
        for (index, fret) in voicing.frets.enumerated() {
            guard let fret else { continue }
            let delay = Double(index) * 0.045
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                audioEngine.play(string: index, fret: fret)
            }
        }
    }
}
