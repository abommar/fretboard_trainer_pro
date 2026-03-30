import Foundation

struct Fretboard {
    let tuning: GuitarTuning
    let fretCount: Int

    init(tuning: GuitarTuning = .standard, fretCount: Int = 22) {
        self.tuning = tuning
        self.fretCount = fretCount
    }

    /// string: 0-based index (0 = lowest string), fret: 0 = open
    func note(string: Int, fret: Int) -> Note {
        tuning.strings[string].advanced(by: fret)
    }

    /// Returns all (string, fret) positions matching the given note
    func allPositions(for note: Note) -> [(string: Int, fret: Int)] {
        var positions: [(string: Int, fret: Int)] = []
        for s in 0..<tuning.stringCount {
            for f in 0...fretCount {
                if self.note(string: s, fret: f) == note {
                    positions.append((s, f))
                }
            }
        }
        return positions
    }
}
