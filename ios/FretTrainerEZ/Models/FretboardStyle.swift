import SwiftUI

enum FretboardStyle: String, CaseIterable, Identifiable {
    case rosewood = "Rosewood"
    case maple    = "Maple"
    case ebony    = "Ebony"
    case walnut   = "Walnut"
    case midnight = "Midnight"

    var id: String { rawValue }

    var descriptor: String {
        switch self {
        case .rosewood: return "Classic dark rosewood"
        case .maple:    return "Bright honey maple"
        case .ebony:    return "Jet black with gold frets"
        case .walnut:   return "Warm medium brown"
        case .midnight: return "Deep midnight blue"
        }
    }

    // MARK: - Colors

    var boardColors: [Color] {
        switch self {
        case .rosewood: return [Color(hex: "#4A3525"), Color(hex: "#3D2B1F"), Color(hex: "#2E1F14")]
        case .maple:    return [Color(hex: "#C8A87A"), Color(hex: "#B89358"), Color(hex: "#A07840")]
        case .ebony:    return [Color(hex: "#1C1C1C"), Color(hex: "#141414"), Color(hex: "#0C0C0C")]
        case .walnut:   return [Color(hex: "#5C3D1E"), Color(hex: "#4A2E14"), Color(hex: "#361E0A")]
        case .midnight: return [Color(hex: "#1A1A3E"), Color(hex: "#141430"), Color(hex: "#0D0D20")]
        }
    }

    var nutColor: Color {
        switch self {
        case .rosewood: return Color(hex: "#E8D5A3")
        case .maple:    return Color(hex: "#F5ECD0")
        case .ebony:    return Color(hex: "#D0C8B0")
        case .walnut:   return Color(hex: "#DFC898")
        case .midnight: return Color(hex: "#8888CC")
        }
    }

    var fretColors: [Color] {
        switch self {
        case .rosewood: return [Color(hex: "#A0A0A0"), Color(hex: "#D0D0D0"), Color(hex: "#A0A0A0")]
        case .maple:    return [Color(hex: "#C0B890"), Color(hex: "#E8D8B0"), Color(hex: "#C0B890")]
        case .ebony:    return [Color(hex: "#A08830"), Color(hex: "#D4B840"), Color(hex: "#A08830")]
        case .walnut:   return [Color(hex: "#A09060"), Color(hex: "#C8B070"), Color(hex: "#A09060")]
        case .midnight: return [Color(hex: "#6060A8"), Color(hex: "#9090D0"), Color(hex: "#6060A8")]
        }
    }

    var stringColors: [Color] {
        switch self {
        case .rosewood: return [Color(hex: "#B8B8B8"), Color(hex: "#E8E8E8"), Color(hex: "#B8B8B8")]
        case .maple:    return [Color(hex: "#C8C0A0"), Color(hex: "#F0E8C0"), Color(hex: "#C8C0A0")]
        case .ebony:    return [Color(hex: "#A8A8A8"), Color(hex: "#D8D8D8"), Color(hex: "#A8A8A8")]
        case .walnut:   return [Color(hex: "#B8A878"), Color(hex: "#E0D0A0"), Color(hex: "#B8A878")]
        case .midnight: return [Color(hex: "#8080C0"), Color(hex: "#C0C0F0"), Color(hex: "#8080C0")]
        }
    }

    /// Pearl inlay color — cream base used in mini previews (full FretboardView uses layered pearl rendering)
    var pearlBase: Color { Color(hex: "#EDE8E0") }
}
