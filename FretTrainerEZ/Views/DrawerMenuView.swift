import SwiftUI

enum AppScreen: Identifiable {
    case circleOfFifths
    case chordCharts
    case chromaticTuner
    case scales
    case fretboardStyle
    case settings

    var id: String {
        switch self {
        case .circleOfFifths:  return "circleOfFifths"
        case .chordCharts:     return "chordCharts"
        case .chromaticTuner:  return "chromaticTuner"
        case .scales:          return "scales"
        case .fretboardStyle:  return "fretboardStyle"
        case .settings:        return "settings"
        }
    }
}

struct DrawerMenuView: View {
    @Binding var isOpen: Bool
    var onSelect: (AppScreen) -> Void

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#111128")
    private let itemBg  = Color(hex: "#1A1A3A")

    var body: some View {
        ZStack(alignment: .leading) {
            // Scrim
            if isOpen {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
            }

            // Drawer panel
            if isOpen {
                HStack(spacing: 0) {
                    drawerPanel
                        .transition(.move(edge: .leading))
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isOpen)
    }

    private var drawerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("FretTrainerEZ")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Music Tools")
                    .font(.system(size: 10))
                    .foregroundColor(accent)
            }
            .padding(.top, 52)
            .padding(.horizontal, 18)
            .padding(.bottom, 14)

            Divider().background(Color.white.opacity(0.1))

            // Menu items
            menuItem(icon: "circle.dotted", title: "Circle of Fifths", subtitle: "Key relationships") {
                navigate(to: .circleOfFifths)
            }

            menuItem(icon: "music.note.list", title: "Chord Charts", subtitle: "Common voicings") {
                navigate(to: .chordCharts)
            }

            menuItem(icon: "tuningfork", title: "Chromatic Tuner", subtitle: "Tune by ear") {
                navigate(to: .chromaticTuner)
            }

            menuItem(icon: "music.quarternote.3", title: "Scale Explorer", subtitle: "Landscape · 10 scales") {
                navigate(to: .scales)
            }

            menuItem(icon: "paintpalette.fill", title: "Fretboard Style", subtitle: "5 wood themes") {
                navigate(to: .fretboardStyle)
            }

            Divider().background(Color.white.opacity(0.1))

            menuItem(icon: "gearshape.fill", title: "Settings", subtitle: "Sound, haptics, note names") {
                navigate(to: .settings)
            }

            Spacer()
        }
        .frame(width: 240)
        .background(bg.ignoresSafeArea())
        .shadow(color: .black.opacity(0.5), radius: 20, x: 10, y: 0)
    }

    private func menuItem(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(accent)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func navigate(to screen: AppScreen) {
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSelect(screen)
        }
    }

    private func close() {
        isOpen = false
    }
}
