import SwiftUI

enum AppTab: Int, CaseIterable {
    case home = 0
    case skills = 1
    case progress = 2
    case profile = 3

    var label: String {
        switch self {
        case .home: return "Home"
        case .skills: return "Skills"
        case .progress: return "Progress"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .skills: return "figure.strengthtraining.traditional"
        case .progress: return "chart.bar"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .skills: return "figure.strengthtraining.traditional"
        case .progress: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }
}

struct FloatingDockView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                let selected = tab == selectedTab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 3) {
                        if selected {
                            ZStack {
                                Circle()
                                    .fill(FMFColors.brandAccent.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .shadow(color: FMFColors.brandAccent.opacity(0.45), radius: 7)
                                Image(systemName: tab.selectedIcon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(FMFColors.accentBlueLight)
                            }
                            .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(FMFColors.neutral500.opacity(0.65))
                                .frame(width: 32, height: 32)
                        }
                        Text(tab.label)
                            .font(.system(size: 10, weight: selected ? .semibold : .regular))
                            .foregroundStyle(
                                selected
                                    ? FMFColors.accentBlueLight
                                    : FMFColors.neutral500.opacity(0.55)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
        .frame(height: 68)
        .padding(.horizontal, 20)
        .background {
            RoundedRectangle(cornerRadius: 36)
                .fill(Color(hex: 0x131D30).opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 36)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.4), radius: 28, x: 0, y: -4)
                .shadow(color: FMFColors.brandAccent.opacity(0.1), radius: 24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 36))
    }
}
