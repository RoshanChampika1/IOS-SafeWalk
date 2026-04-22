import CoreLocation
import SwiftUI

struct RouteReviewSheet: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var routeService: RouteService
    @EnvironmentObject var session: UserSessionManager
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    let routePoints: [CLLocationCoordinate2D]

    @State private var isSafe: Bool = true
    @State private var reviewMessage: String = ""
    @State private var isSubmitting: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                SafeWalkTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("You've completed your walk! How was your route?")
                            .font(.title2.bold())
                            .foregroundStyle(SafeWalkTheme.textPrimary)
                            .padding(.top, 16)

                        HStack(spacing: 20) {
                            Button {
                                isSafe = true
                            } label: {
                                VStack {
                                    Image(systemName: "hand.thumbsup.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(isSafe ? .white : SafeWalkTheme.callGreen)
                                    Text("Safe")
                                        .font(.headline)
                                        .foregroundStyle(isSafe ? .white : SafeWalkTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(isSafe ? SafeWalkTheme.callGreen : SafeWalkTheme.cardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            }

                            Button {
                                isSafe = false
                            } label: {
                                VStack {
                                    Image(systemName: "hand.thumbsdown.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(!isSafe ? .white : SafeWalkTheme.emergencyRed)
                                    Text("Unsafe")
                                        .font(.headline)
                                        .foregroundStyle(!isSafe ? .white : SafeWalkTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(!isSafe ? SafeWalkTheme.emergencyRed : SafeWalkTheme.cardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tell the community about this route (optional)")
                                .font(.subheadline.bold())
                                .foregroundStyle(SafeWalkTheme.textSecondary)

                            TextEditor(text: $reviewMessage)
                                .frame(height: 120)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(SafeWalkTheme.cardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }

                        Spacer(minLength: 40)

                        Button {
                            submitReview()
                        } label: {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(SafeWalkTheme.primaryBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius))
                            } else {
                                Text("Submit Review")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(SafeWalkTheme.primaryBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: SafeWalkTheme.buttonCornerRadius))
                            }
                        }
                        .disabled(isSubmitting)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Route Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        dashboardVM.endWalkSafely(session: session, location: locationManager, notifications: notificationManager)
                        dismiss()
                    }
                    .foregroundStyle(SafeWalkTheme.textSecondary)
                }
            }
        }
    }

    private func submitReview() {
        isSubmitting = true
        
        let savedRoute = SavedRoute(
            userID: session.currentUserID,
            userName: session.userName.isEmpty ? "Anonymous" : session.userName,
            isSafe: isSafe,
            reviewMessage: reviewMessage,
            routePoints: routePoints
        )
        
        routeService.saveRoute(savedRoute)
        
        // Simulate a slight delay so user feels the submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSubmitting = false
            dashboardVM.endWalkSafely(session: session, location: locationManager, notifications: notificationManager)
            dismiss()
        }
    }
}
