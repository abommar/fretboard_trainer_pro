import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled")   private var soundEnabled: Bool   = false
    @AppStorage("useFlats")       private var useFlats: Bool       = false
    @AppStorage("tipsEnabled")    private var tipsEnabled: Bool    = true

    private let accent = Color(hex: "#E94560")
    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accent)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Settings")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider().background(Color.white.opacity(0.1))

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: Gameplay
                        settingsSection(title: "GAMEPLAY") {
                            toggleRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Haptics",
                                subtitle: "Vibration feedback on answers",
                                value: $hapticsEnabled
                            )
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 52)
                            toggleRow(
                                icon: "lightbulb",
                                title: "Fretboard Tips",
                                subtitle: "Show learning tips below the answer buttons",
                                value: $tipsEnabled
                            )
                        }

                        // MARK: Sound
                        settingsSection(title: "SOUND") {
                            toggleRow(
                                icon: "speaker.wave.2.fill",
                                title: "Sound Effects",
                                subtitle: "Play note tones on the fretboard",
                                value: $soundEnabled
                            )
                        }

                        // MARK: Display
                        settingsSection(title: "DISPLAY") {
                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    Image(systemName: "textformat")
                                        .font(.system(size: 16))
                                        .foregroundColor(accent)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Note Names")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("How accidentals are displayed")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.4))
                                    }

                                    Spacer()

                                    Picker("", selection: $useFlats) {
                                        Text("Sharps  ♯").tag(false)
                                        Text("Flats   ♭").tag(true)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 150)
                                    .tint(accent)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 52)

                                // Live preview
                                HStack(spacing: 8) {
                                    Text("Preview:")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.35))
                                    ForEach([Note.Cs, .Ds, .Fs, .Gs, .As], id: \.self) { note in
                                        let hue = Double(note.rawValue) / 12.0
                                        Text(useFlats ? note.flatName : note.sharpName)
                                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                                            .foregroundColor(hue > 0.14 && hue < 0.56 ? .black.opacity(0.8) : .white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color(hue: hue, saturation: 0.8, brightness: 0.95)))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .animation(.easeInOut(duration: 0.15), value: useFlats)
                            }
                        }

                        // App info footer
                        VStack(spacing: 4) {
                            Text("FretTrainerEZ")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.25))
                            Text("iOS 17+  ·  No network required")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.15))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                    .padding(16)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Components

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(cardBg))
        }
    }

    private func toggleRow(icon: String, title: String, subtitle: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Toggle("", isOn: value)
                .tint(accent)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
