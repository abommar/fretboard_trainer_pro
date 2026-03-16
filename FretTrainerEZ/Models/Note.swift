import Foundation

enum Note: Int, CaseIterable, Codable {
    case C = 0, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B

    var sharpName: String {
        switch self {
        case .C: return "C"
        case .Cs: return "C#"
        case .D: return "D"
        case .Ds: return "D#"
        case .E: return "E"
        case .F: return "F"
        case .Fs: return "F#"
        case .G: return "G"
        case .Gs: return "G#"
        case .A: return "A"
        case .As: return "A#"
        case .B: return "B"
        }
    }

    var flatName: String {
        switch self {
        case .C: return "C"
        case .Cs: return "Db"
        case .D: return "D"
        case .Ds: return "Eb"
        case .E: return "E"
        case .F: return "F"
        case .Fs: return "Gb"
        case .G: return "G"
        case .Gs: return "Ab"
        case .A: return "A"
        case .As: return "Bb"
        case .B: return "B"
        }
    }

    func displayName(useFlats: Bool = false) -> String {
        useFlats ? flatName : sharpName
    }

    func advanced(by semitones: Int) -> Note {
        let raw = (self.rawValue + semitones % 12 + 12) % 12
        return Note(rawValue: raw)!
    }
}
