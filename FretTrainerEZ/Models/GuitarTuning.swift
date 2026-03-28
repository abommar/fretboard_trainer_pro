import Foundation

struct GuitarTuning: Identifiable, Hashable {
    let id: String
    let name: String
    /// Open note for each string, index 0 = lowest string (string 6 in guitar convention)
    let strings: [Note]
    /// When true, display enharmonic notes as flats (e.g. Eb instead of D#)
    let useFlats: Bool

    var stringCount: Int { strings.count }

    // MARK: - Presets (top 10 tunings)

    static let standard     = GuitarTuning(id: "standard",    name: "Standard",       strings: [.E,  .A,  .D,  .G,  .B,  .E],  useFlats: false)
    static let dropD        = GuitarTuning(id: "dropD",       name: "Drop D",         strings: [.D,  .A,  .D,  .G,  .B,  .E],  useFlats: false)
    static let openG        = GuitarTuning(id: "openG",       name: "Open G",         strings: [.D,  .G,  .D,  .G,  .B,  .D],  useFlats: false)
    static let openD        = GuitarTuning(id: "openD",       name: "Open D",         strings: [.D,  .A,  .D,  .Fs, .A,  .D],  useFlats: false)
    static let dadgad       = GuitarTuning(id: "dadgad",      name: "DADGAD",         strings: [.D,  .A,  .D,  .G,  .A,  .D],  useFlats: false)
    static let openE        = GuitarTuning(id: "openE",       name: "Open E",         strings: [.E,  .B,  .E,  .Gs, .B,  .E],  useFlats: false)
    static let openA        = GuitarTuning(id: "openA",       name: "Open A",         strings: [.E,  .A,  .E,  .A,  .Cs, .E],  useFlats: false)
    static let halfStepDown = GuitarTuning(id: "halfStepDown",name: "Half Step Down", strings: [.Ds, .Gs, .Cs, .Fs, .As, .Ds], useFlats: true)
    static let fullStepDown = GuitarTuning(id: "fullStepDown",name: "Full Step Down", strings: [.D,  .G,  .C,  .F,  .A,  .D],  useFlats: false)
    static let dropC        = GuitarTuning(id: "dropC",       name: "Drop C",         strings: [.C,  .G,  .C,  .F,  .A,  .D],  useFlats: false)

    static let all: [GuitarTuning] = [
        standard, dropD, openG, openD, dadgad,
        openE, openA, halfStepDown, fullStepDown, dropC
    ]
}
