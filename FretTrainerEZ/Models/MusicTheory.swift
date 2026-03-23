import Foundation

// MARK: - Chord function classification

/// The harmonic function of a chord within a key.
enum ChordFunction {
    case tonic        // I, iii, vi  — stable, home
    case subdominant  // ii, IV      — movement, bridge
    case dominant     // V, vii°     — tension, resolves to tonic
}

// MARK: - Diatonic chord descriptor

struct DiatonicChord {
    let numeral: String       // "I", "ii", "iii", "IV", "V", "vi", "vii°"
    let name: String          // e.g. "G", "Am", "Bm", "C", "D", "Em", "F#°"
    let chordFunction: ChordFunction
}

// MARK: - Common progression descriptor

struct Progression {
    let name: String          // e.g. "I–IV–V"
    let style: String         // e.g. "Rock & Blues"
    let indices: [Int]        // indices into diatonicChords array (0 = I … 6 = vii°)
}

// MARK: - Circle of Fifths data + helpers

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

    // MARK: - Diatonic chords for a key

    /// Returns the 7 diatonic chords for the key at circle position `k`.
    /// Index mapping: 0=I, 1=ii, 2=iii, 3=IV, 4=V, 5=vi, 6=vii°
    static func diatonicChords(forKeyAt k: Int, useFlats: Bool = false) -> [DiatonicChord] {
        let cof = circleOfFifths
        let km1 = (k - 1 + 12) % 12
        let kp1 = (k + 1) % 12
        func n(_ note: Note) -> String { note.displayName(useFlats: useFlats) }
        return [
            DiatonicChord(numeral: "I",    name: n(cof[k].major),                              chordFunction: .tonic),
            DiatonicChord(numeral: "ii",   name: n(cof[km1].relative) + "m",                   chordFunction: .subdominant),
            DiatonicChord(numeral: "iii",  name: n(cof[kp1].relative) + "m",                   chordFunction: .tonic),
            DiatonicChord(numeral: "IV",   name: n(cof[km1].major),                             chordFunction: .subdominant),
            DiatonicChord(numeral: "V",    name: n(cof[kp1].major),                             chordFunction: .dominant),
            DiatonicChord(numeral: "vi",   name: n(cof[k].relative)   + "m",                   chordFunction: .tonic),
            DiatonicChord(numeral: "vii°", name: n(cof[k].major.advanced(by: 11)) + "°",       chordFunction: .dominant),
        ]
    }

    /// Maps circle positions to chord function for the 3 adjacent wedges when key `k` is selected.
    /// Outer ring: IV (k-1) = subdominant, I (k) = tonic, V (k+1) = dominant
    /// Inner ring: ii (k-1) = subdominant, vi (k) = tonic, iii (k+1) = tonic
    static func diatonicCirclePositions(forKeyAt k: Int) -> [Int: ChordFunction] {
        let km1 = (k - 1 + 12) % 12
        let kp1 = (k + 1) % 12
        return [km1: .subdominant, k: .tonic, kp1: .dominant]
    }

    // MARK: - Common progressions

    static let commonProgressions: [Progression] = [
        Progression(name: "I–IV–V",       style: "Rock & Blues",  indices: [0, 3, 4]),
        Progression(name: "I–V–vi–IV",    style: "Pop",           indices: [0, 4, 5, 3]),
        Progression(name: "I–vi–IV–V",    style: "50s / Doo-wop", indices: [0, 5, 3, 4]),
        Progression(name: "ii–V–I",       style: "Jazz",          indices: [1, 4, 0]),
    ]

    // MARK: - Display helpers

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
        let symbol = sharpsOrFlats > 0 ? "♯" : "♭"
        return "\(abs(sharpsOrFlats))\(symbol)"
    }
}
