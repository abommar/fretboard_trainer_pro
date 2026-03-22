import Foundation

// frets: nil = muted, 0 = open string, 1+ = fret number
// strings: index 0 = low E, 5 = high E
struct ChordVoicing: Identifiable {
    let id = UUID()
    let root: Note
    let type: ChordType
    let frets: [Int?]   // 6 values
    let baseFret: Int   // fret the diagram starts on (usually 1)

    var name: String { "\(root.sharpName)\(type.suffix)" }
}

enum ChordType: String, CaseIterable, Identifiable {
    case major       = "Major"
    case minor       = "Minor"
    case dominant7   = "7"
    case major7      = "maj7"
    case minor7      = "m7"
    case sus2        = "sus2"
    case sus4        = "sus4"

    var id: String { rawValue }
    var suffix: String {
        switch self {
        case .major:     return ""
        case .minor:     return "m"
        case .dominant7: return "7"
        case .major7:    return "maj7"
        case .minor7:    return "m7"
        case .sus2:      return "sus2"
        case .sus4:      return "sus4"
        }
    }
}

enum ChordLibrary {
    static let all: [ChordVoicing] = [
        // MARK: - Major open chords
        ChordVoicing(root: .C, type: .major,     frets: [nil, 3, 2, 0, 1, 0], baseFret: 1),
        ChordVoicing(root: .D, type: .major,     frets: [nil, nil, 0, 2, 3, 2], baseFret: 1),
        ChordVoicing(root: .E, type: .major,     frets: [0, 2, 2, 1, 0, 0], baseFret: 1),
        ChordVoicing(root: .F, type: .major,     frets: [1, 3, 3, 2, 1, 1], baseFret: 1),
        ChordVoicing(root: .G, type: .major,     frets: [3, 2, 0, 0, 0, 3], baseFret: 1),
        ChordVoicing(root: .A, type: .major,     frets: [nil, 0, 2, 2, 2, 0], baseFret: 1),
        ChordVoicing(root: .B, type: .major,     frets: [nil, 2, 4, 4, 4, 2], baseFret: 1),

        // MARK: - Minor open chords
        ChordVoicing(root: .C, type: .minor,     frets: [nil, 3, 5, 5, 4, 3], baseFret: 3),
        ChordVoicing(root: .D, type: .minor,     frets: [nil, nil, 0, 2, 3, 1], baseFret: 1),
        ChordVoicing(root: .E, type: .minor,     frets: [0, 2, 2, 0, 0, 0], baseFret: 1),
        ChordVoicing(root: .F, type: .minor,     frets: [1, 3, 3, 1, 1, 1], baseFret: 1),
        ChordVoicing(root: .G, type: .minor,     frets: [3, 5, 5, 3, 3, 3], baseFret: 3),
        ChordVoicing(root: .A, type: .minor,     frets: [nil, 0, 2, 2, 1, 0], baseFret: 1),
        ChordVoicing(root: .B, type: .minor,     frets: [nil, 2, 4, 4, 3, 2], baseFret: 1),

        // MARK: - Dominant 7
        ChordVoicing(root: .C, type: .dominant7, frets: [nil, 3, 2, 3, 1, 0], baseFret: 1),
        ChordVoicing(root: .D, type: .dominant7, frets: [nil, nil, 0, 2, 1, 2], baseFret: 1),
        ChordVoicing(root: .E, type: .dominant7, frets: [0, 2, 0, 1, 0, 0], baseFret: 1),
        ChordVoicing(root: .G, type: .dominant7, frets: [3, 2, 0, 0, 0, 1], baseFret: 1),
        ChordVoicing(root: .A, type: .dominant7, frets: [nil, 0, 2, 0, 2, 0], baseFret: 1),
        ChordVoicing(root: .B, type: .dominant7, frets: [nil, 2, 1, 2, 0, 2], baseFret: 1),

        // MARK: - Major 7
        ChordVoicing(root: .C, type: .major7,    frets: [nil, 3, 2, 0, 0, 0], baseFret: 1),
        ChordVoicing(root: .D, type: .major7,    frets: [nil, nil, 0, 2, 2, 2], baseFret: 1),
        ChordVoicing(root: .E, type: .major7,    frets: [0, 2, 1, 1, 0, 0], baseFret: 1),
        ChordVoicing(root: .G, type: .major7,    frets: [3, 2, 0, 0, 0, 2], baseFret: 1),
        ChordVoicing(root: .A, type: .major7,    frets: [nil, 0, 2, 1, 2, 0], baseFret: 1),

        // MARK: - Minor 7
        ChordVoicing(root: .A, type: .minor7,    frets: [nil, 0, 2, 0, 1, 0], baseFret: 1),
        ChordVoicing(root: .D, type: .minor7,    frets: [nil, nil, 0, 2, 1, 1], baseFret: 1),
        ChordVoicing(root: .E, type: .minor7,    frets: [0, 2, 2, 0, 3, 0], baseFret: 1),
        ChordVoicing(root: .G, type: .minor7,    frets: [3, 5, 3, 3, 3, 3], baseFret: 3),

        // MARK: - Sus2
        ChordVoicing(root: .D, type: .sus2,      frets: [nil, nil, 0, 2, 3, 0], baseFret: 1),
        ChordVoicing(root: .A, type: .sus2,      frets: [nil, 0, 2, 2, 0, 0], baseFret: 1),
        ChordVoicing(root: .E, type: .sus2,      frets: [0, 2, 4, 4, 0, 0], baseFret: 1),
        ChordVoicing(root: .G, type: .sus2,      frets: [3, 0, 0, 0, 3, 3], baseFret: 1),

        // MARK: - Sus4
        ChordVoicing(root: .D, type: .sus4,      frets: [nil, nil, 0, 2, 3, 3], baseFret: 1),
        ChordVoicing(root: .A, type: .sus4,      frets: [nil, 0, 2, 2, 3, 0], baseFret: 1),
        ChordVoicing(root: .E, type: .sus4,      frets: [0, 2, 2, 2, 0, 0], baseFret: 1),
        ChordVoicing(root: .G, type: .sus4,      frets: [3, 3, 0, 0, 1, 3], baseFret: 1),
    ]

    static func voicings(root: Note, type: ChordType) -> [ChordVoicing] {
        all.filter { $0.root == root && $0.type == type }
    }
}
