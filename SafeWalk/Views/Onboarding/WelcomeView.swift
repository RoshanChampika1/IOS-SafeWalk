import SwiftUI

/// Shown once on first install BEFORE the login screen.
/// Shows SafeWalk feature slides, requests location + notification
/// permissions, then transitions to LoginView.
struct WelcomeView: View {

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    var onComplete: () -> Void

    @State private var page: Int = 0

    let pages: [(icon: String, title: String, description: String, color: Color)] = [
        ("figure.walk.circle.fill", "Walk safely",
         "SafeWalk watches your timer and helps you reach out when something feels wrong.",
         SafeWalkTheme.primaryBlue),
        ("timer.circle.fill", "Safety timer",
         "Set how long your walk should take. Disarm with Face ID when you arrive.",
         SafeWalkTheme.primaryBlue),
        ("person.fill.checkmark", "Trusted people",
         "Pick guardians and emergency contacts — call or message them in one tap.",
         SafeWalkTheme.callGreen),
        ("map.fill", "Live map",
         "Share your route when you walk so someone you trust can follow along.",
         SafeWalkTheme.primaryBlue),
        ("bell.badge.fill", "Stay connected",
         "Allow notifications so guardians can reach you and you can reach them instantly.",
         SafeWalkTheme.warningOrange)
    ]

    var body: some View {
        ZStack {
            SafeWalkTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Slide pages
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        WelcomePageView(
                            icon:        pages[index].icon,
                            title:       pages[index].title,
                            description: pages[index].description,
                            color:       pages[index].color
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // MARK: Next / Get Started button
                if page < pages.count - 1 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius,
                                                       style: .continuous))
                            .padding(.horizontal, 28)
                            .padding(.bottom, 36)
                    }
                } else {
                    Button {
                        // Request permissions then proceed to login
                        locationManager.requestPermission()
                        notificationManager.requestPermission()
                        onComplete()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SafeWalkTheme.callGreen)
                            .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius,
                                                       style: .continuous))
                            .padding(.horizontal, 28)
                            .padding(.bottom, 36)
                    }
                }
            }
        }
    }
}

// MARK: - Single slide

struct WelcomePageView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 80))
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
