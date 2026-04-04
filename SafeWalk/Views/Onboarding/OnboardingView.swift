import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var page: Int = 0
    @State private var name: String = ""
    
    let pages: [(icon: String, title: String, description: String, color: Color)] = [
        ("figure.walk.circle.fill", "Walk Safely", "SafeWalk monitors your journey and alerts your guardians if something seems wrong.", .indigo),
        ("timer.circle.fill", "Set Your Timer", "Start a countdown before your walk. Disarm it when you arrive safely.", .blue),
        ("person.fill.checkmark", "Guardian Network", "Assign trusted contacts as Guardians — they'll be notified in an emergency.", .purple),
        ("map.fill", "Live Map Sharing", "Share your live location with a Guardian during your walk.", .teal)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                    
                    // Final page — Name entry
                    VStack(spacing: 30) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.yellow)
                        
                        Text("What's your name?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        TextField("Enter your name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal, 40)
                        
                        Button {
                            if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                                locationManager.requestPermission()
                                notificationManager.requestPermission()
                                session.completeOnboarding(name: name)
                            }
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .cornerRadius(16)
                                .padding(.horizontal, 40)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 40)
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
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Text(description)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
