import SwiftUI

struct WorkoutBackHarnessView: View {
    @State private var showsWorkout = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if showsWorkout {
                    Text("Workout Visible")
                        .accessibilityIdentifier("workout.visibleMarker")
                } else {
                    Text("Workout Dismissed")
                        .accessibilityIdentifier("workout.dismissedMarker")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FMFColors.brandPrimary.ignoresSafeArea())
            .fullScreenCover(isPresented: $showsWorkout) {
                WorkoutView(skillId: "pullups")
            }
        }
    }
}
