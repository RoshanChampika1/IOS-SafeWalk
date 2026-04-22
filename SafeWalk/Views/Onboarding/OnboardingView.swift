import Combine
import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var page: Int = 0
    @State private var name: String = ""

    let pages: [(icon: String, title: String, description: String, color: Color)] = [
        ("figure.walk.circle.fill", "Walk safely", "SafeWalk watches your timer and helps you reach out when something feels wrong.", SafeWalkTheme.primaryBlue),
        ("timer.circle.fill", "Safety timer", "Set how long your walk should take. Disarm with Face ID or Touch ID when you arrive.", SafeWalkTheme.primaryBlue),
        ("person.fill.checkmark", "Trusted people", "Pick guardians and emergency contacts — call or message them in one tap.", SafeWalkTheme.callGreen),
        ("map.fill", "Live map", "Share your route when you walk so someone you trust can follow along.", SafeWalkTheme.primaryBlue)
    ]

    var body: some View {
        ZStack {
            SafeWalkTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            icon: pages[index].icon,
                            title: pages[index].title,
                            description: pages[index].description,
                            color: pages[index].color
                        )
                        .tag(index)
                    }

                    VStack(spacing: 28) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(SafeWalkTheme.warningOrange)

                        Text("What's your name?")
                            .font(.title.bold())
                            .foregroundStyle(SafeWalkTheme.textPrimary)

                        TextField("Enter your name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(SafeWalkTheme.cardElevated)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                            .padding(.horizontal, 32)

                        Button {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            locationManager.requestPermission()
                            notificationManager.requestPermission()
                            session.completeOnboarding(name: trimmed)
                        } label: {
                            Text("Get started")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(SafeWalkTheme.primaryBlue)
                                .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                        }
                        .padding(.horizontal, 32)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                if page < pages.count {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius, style: .continuous))
                            .padding(.horizontal, 28)
                            .padding(.bottom, 36)
                    }
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(SafeWalkTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.body)
                .foregroundStyle(SafeWalkTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }
}
