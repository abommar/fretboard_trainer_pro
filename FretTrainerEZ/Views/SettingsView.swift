import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("soundEnabled")   private var soundEnabled:   Bool = false
    @AppStorage("useFlats")       private var useFlats:       Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    private let accent  = Color(hex: "#E94560")
    private let bg      = Color(hex: "#1A1A2E")
    private let cardBg  = Color(hex: "#16213E")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

                // Settings cards
                VStack(spacing: 12) {
                    settingRow(
                        icon: "speaker.wave.2.fill",
                        iconColor: Color(hex: "#4CAF50"),
                        title: "Sound Effects",
                        subtitle: "Play note audio on each question",
                        isOn: $soundEnabled
                    )

                    settingRow(
                        icon: "hand.tap.fill",
                        iconColor: Color(hex: "#FF9800"),
                        title: "Haptic Feedback",
                        subtitle: "Vibration on correct and wrong answers",
                        isOn: $hapticsEnabled
                    )

                    settingRow(
                        icon: "music.note",
                        iconColor: Color(hex: "#9C27B0"),
                        title: "Use Flat Names",
                        subtitle: "Show Bb, Eb instead of A#, D#",
                        isOn: $useFlats
                    )
                }
                .padding(.horizontal, 20)

                Spacer()

                Text("FretTrainerEZ")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func settingRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardBg))
    }
}
