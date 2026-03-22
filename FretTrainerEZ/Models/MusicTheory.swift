import Foundation

// Circle of Fifths — ordered clockwise from 12 o'clock (C)
enum MusicTheory {
    struct KeyInfo: Identifiable {
        let id = UUID()
        let major: Note
        let relative: Note     // relative minor root
        let sharpsOrFlats: Int // positive = sharps, negative = flats
    }

    // 12 positions clockwise: C, G, D, A, E, B, F#/Gb, Db, Ab, Eb, Bb, F
    static let circleOfFifths: [KeyInfo] = [
        KeyInfo(major: .C,  relative: .A,  sharpsOrFlats:  0),
        KeyInfo(major: .G,  relative: .E,  sharpsOrFlats:  1),
        KeyInfo(major: .D,  relative: .B,  sharpsOrFlats:  2),
        KeyInfo(major: .A,  relative: .Fs, sharpsOrFlats:  3),
        KeyInfo(major: .E,  relative: .Cs, sharpsOrFlats:  4),
        KeyInfo(major: .B,  relative: .Gs, sharpsOrFlats:  5),
        KeyInfo(major: .Fs, relative: .Ds, sharpsOrFlats:  6),
        KeyInfo(major: .Cs, relative: .As, sharpsOrFlats: -5),
        KeyInfo(major: .Gs, relative: .F,  sharpsOrFlats: -4),
        KeyInfo(major: .Ds, relative: .C,  sharpsOrFlats: -3),
        KeyInfo(major: .As, relative: .G,  sharpsOrFlats: -2),
        KeyInfo(major: .F,  relative: .D,  sharpsOrFlats: -1),
    ]

    static func enharmonicLabel(for note: Note, position: Int) -> String {
        switch position {
        case 7:  return "C\u{266d}/B"    // Db/B# — show as Db
        case 8:  return "A\u{266d}/G#"
        case 9:  return "E\u{266d}/D#"
        case 10: return "B\u{266d}/A#"
        case 6:  return "F#/G\u{266d}"
        default: return note.sharpName
        }
    }

    static func relativeLabel(for note: Note, position: Int) -> String {
        switch position {
        case 3:  return "F#m"
        case 4:  return "C#m"
        case 5:  return "G#m"
        case 6:  return "D#m"
        case 7:  return "Bbm"
        case 8:  return "Fm"
        case 9:  return "Cm"
        case 10: return "Gm"
        case 11: return "Dm"
        default: return "\(note.sharpName)m"
        }
    }

    static func accidentalLabel(sharpsOrFlats: Int) -> String {
        if sharpsOrFlats == 0 { return "0" }
        let symbol = sharpsOrFlats > 0 ? "#" : "b"
        return "\(abs(sharpsOrFlats))\(symbol)"
    }
}
