import SwiftUI

struct ProgressView: View {
    @Environment(\.practiceSessionRepository) private var repo
    @State private var vm: ProgressViewModel?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        ZStack {
            FMFColors.brandPrimary.ignoresSafeArea()

            Group {
                if let vm {
                    content(vm: vm)
                }
            }
        }
        .navigationTitle(String(localized: "progressTitle"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let viewModel = ProgressViewModel(repo: repo)
            vm = viewModel
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func content(vm: ProgressViewModel) -> some View {
        if vm.isLoading {
            ProgressView().tint(FMFColors.brandAccent)
        } else if let error = vm.errorMessage {
            Text("Error loading progress: \(error)")
                .foregroundStyle(.white)
                .padding()
        } else if vm.sessions.isEmpty {
            Text(String(localized: "emptyStateNoSessions"))
                .font(FMFTypography.bodyLarge)
                .foregroundStyle(FMFColors.neutral500)
                .multilineTextAlignment(.center)
                .padding(FMFSpacing.lg)
        } else {
            List(vm.sessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.skillId)
                            .font(FMFTypography.titleSmall)
                            .foregroundStyle(.white)
                        Text(Self.dateFormatter.string(from: session.date))
                            .font(FMFTypography.bodySmall)
                            .foregroundStyle(FMFColors.neutral500)
                    }
                    Spacer()
                    Text("\(session.durationMinutes) min")
                        .font(FMFTypography.labelMedium)
                        .foregroundStyle(FMFColors.neutral300)
                }
                .padding(.vertical, FMFSpacing.xs)
                .listRowBackground(FMFColors.brandPrimary)
                .listRowSeparatorTint(FMFColors.neutral700)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
