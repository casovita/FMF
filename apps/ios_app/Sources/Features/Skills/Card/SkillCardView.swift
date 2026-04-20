import SwiftUI

struct SkillCardView: View {
    let skill: Skill
    let onTap: () -> Void

    private var categoryColor: Color {
        switch skill.category {
        case .balance:    return FMFColors.skillBalance
        case .strength:   return Color(hex: 0xE05252)
        case .bodyweight: return FMFColors.skillBodyweight
        }
    }

    private var iconName: String? {
        skill.id == "handstand" ? "handstand" : nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Top 1pt highlight edge
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.16), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Card content
                VStack(spacing: FMFSpacing.sm) {
                    if let name = iconName {
                        SkillIconBadge(imageName: name, color: categoryColor)
                    }
                    Text(skill.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0xEEF2FF))
                        .multilineTextAlignment(.center)
                        .tracking(0.2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            }
            .background {
                LinearGradient(
                    colors: [
                        Color(hex: 0x1E2D45).opacity(0.88),
                        Color(hex: 0x111D30).opacity(0.94),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    RoundedRectangle(cornerRadius: FMFRadius.xl)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
            .shadow(color: .black.opacity(0.45), radius: 28, x: 0, y: 10)
            .shadow(color: categoryColor.opacity(0.12), radius: 32, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct SkillIconBadge: View {
    let imageName: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FMFRadius.lg)
                .fill(color.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: FMFRadius.lg)
                        .strokeBorder(color.opacity(0.22), lineWidth: 1)
                }
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(color)
                .padding(10)
        }
        .frame(width: 64, height: 64)
    }
}
