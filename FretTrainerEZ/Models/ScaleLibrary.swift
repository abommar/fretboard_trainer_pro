import Foundation

enum ScaleType: String, CaseIterable, Identifiable {
    case pentatonicMinor  = "Pentatonic Minor"
    case pentatonicMajor  = "Pentatonic Major"
    case blues            = "Blues"
    case major            = "Major"
    case naturalMinor     = "Natural Minor"
    case dorian           = "Dorian"
    case mixolydian       = "Mixolydian"
    case harmonicMinor    = "Harmonic Minor"
    case phrygian         = "Phrygian"
    case lydian           = "Lydian"

    var id: String { rawValue }

    /// Semitone intervals from the root
    var intervals: [Int] {
        switch self {
        case .major:           return [0, 2, 4, 5, 7, 9, 11]
        case .naturalMinor:    return [0, 2, 3, 5, 7, 8, 10]
        case .pentatonicMajor: return [0, 2, 4, 7, 9]
        case .pentatonicMinor: return [0, 3, 5, 7, 10]
        case .blues:           return [0, 3, 5, 6, 7, 10]
        case .dorian:          return [0, 2, 3, 5, 7, 9, 10]
        case .mixolydian:      return [0, 2, 4, 5, 7, 9, 10]
        case .harmonicMinor:   return [0, 2, 3, 5, 7, 8, 11]
        case .phrygian:        return [0, 1, 3, 5, 7, 8, 10]
        case .lydian:          return [0, 2, 4, 6, 7, 9, 11]
        }
    }

    var flavor: String {
        switch self {
        case .pentatonicMinor:  return "Rock & blues staple"
        case .pentatonicMajor:  return "Country & folk"
        case .blues:            return "Soulful & gritty"
        case .major:            return "Happy & bright"
        case .naturalMinor:     return "Dark & moody"
        case .dorian:           return "Jazz & funk"
        case .mixolydian:       return "Bluesy major"
        case .harmonicMinor:    return "Classical & exotic"
        case .phrygian:         return "Spanish & metal"
        case .lydian:           return "Dreamy & ethereal"
        }
    }

    /// Notes of this scale for a given root
    func notes(root: Note) -> [Note] {
        intervals.map { root.advanced(by: $0) }
    }
}
