import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page: Int = 0

    private let accent = Color(hex: "#E94560")
    private let bg     = Color(hex: "#1A1A2E")
    private let cardBg = Color(hex: "#16213E")

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "music.note",
            title: "Learn the Fretboard",
            body: "FretTrainerEZ turns fretboard knowledge into muscle memory through fast, focused practice. Three game modes, three difficulty levels."
        ),
        OnboardingPage(
            icon: "hand.tap",
            title: "Three Ways to Play",
            body: "Name It — identify highlighted notes.\nFind It — tap every position of a note.\nMemory — memorize positions, then recall them."
        ),
        OnboardingPage(
            icon: "timer",
            title: "Practice or Race the Clock",
            body: "Practice mode: unlimited rounds at your pace.\nTimed mode: score as many as you can in 30s, 1m, or 2m."
        ),
    ]

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .buttonStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 16)
                        .padding(.trailing, 24)
                }

                Spacer()

                // Page content
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 360)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == page ? accent : Color.white.opacity(0.25))
                            .frame(width: 7, height: 7)
                            .animation(.easeInOut(duration: 0.2), value: page)
                    }
                }
                .padding(.top, 24)

                Spacer()

                // CTA
                Button {
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 20) {
            Image(systemName: p.icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(accent)
                .frame(height: 72)

            Text(p.title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(p.body)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
    }
}

private struct OnboardingPage {
    let icon:  String
    let title: String
    let body:  String
}
