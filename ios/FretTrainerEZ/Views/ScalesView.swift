import SwiftUI

struct ScalesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRoot: Note = .A
    @State private var selectedScale: ScaleType = .pentatonicMinor

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")
    private let fretboard = Fretboard()

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                bg.ignoresSafeArea()
                if isLandscape {
                    landscapeContent(geo: geo)
                } else {
                    portraitPlaceholder
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Portrait placeholder

    private var portraitPlaceholder: some View {
        VStack(spacing: 20) {
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accent)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            Spacer()
            Image(systemName: "rotate.right")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text("Rotate to Landscape")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            Text("The scale viewer works best in landscape mode")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .padding(.top, 20)
    }

    // MARK: - Landscape layout

    private func landscapeContent(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accent)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 16)
                    .background(Color.white.opacity(0.2))

                Text("\(selectedRoot.sharpName) \(selectedScale.rawValue)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("· \(selectedScale.flavor)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                // Scale note pills
                HStack(spacing: 4) {
                    ForEach(selectedScale.notes(root: selectedRoot), id: \.rawValue) { note in
                        let isRoot = note == selectedRoot
                        Text(note.sharpName)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(isRoot ? .white : .black.opacity(0.75))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(isRoot ? accent : Color.white.opacity(0.75)))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(cardBg)

            // Root + scale selectors + fretboard
            HStack(spacing: 0) {
                // Left panel: selectors
                VStack(spacing: 12) {
                    // Root note picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ROOT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                            ForEach(Note.allCases, id: \.self) { note in
                                rootChip(note)
                            }
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // Scale type picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SCALE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.horizontal, 4)

                        Picker("Scale", selection: $selectedScale) {
                            ForEach(ScaleType.allCases) { scale in
                                Text(scale.rawValue).tag(scale)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxHeight: .infinity)
                        .clipped()
                    }

                    Spacer(minLength: 0)
                }
                .frame(width: 170)
                .padding(12)
                .background(cardBg)

                // Fretboard
                FretboardView(
                    fretboard: fretboard,
                    highlightString: nil,
                    highlightFret: nil,
                    highlightColor: .clear,
                    scaleHighlights: computeScaleDots()
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Root chip

    private func rootChip(_ note: Note) -> some View {
        let selected = note == selectedRoot
        return Button(action: { selectedRoot = note }) {
            Text(note.sharpName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selected ? .white : .white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selected ? accent : Color.white.opacity(0.07))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: selectedRoot)
    }

    // MARK: - Scale dot computation

    private func computeScaleDots() -> [(FretPosition, Color)] {
        let scaleNotes = Set(selectedScale.notes(root: selectedRoot))
        var dots: [(FretPosition, Color)] = []
        for s in 0..<fretboard.tuning.stringCount {
            for f in 0...fretboard.fretCount {
                let note = fretboard.note(string: s, fret: f)
                if scaleNotes.contains(note) {
                    let color: Color = note == selectedRoot ? accent : Color(hex: "#4A9EFF")
                    dots.append((FretPosition(string: s, fret: f), color))
                }
            }
        }
        return dots
    }
}
