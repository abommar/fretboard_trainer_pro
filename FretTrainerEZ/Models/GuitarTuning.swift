import Foundation

struct GuitarTuning {
    /// Open note for each string, index 0 = lowest string (string 6 in guitar convention)
    let strings: [Note]

    static let standard = GuitarTuning(strings: [.E, .A, .D, .G, .B, .E])

    var stringCount: Int { strings.count }
}
