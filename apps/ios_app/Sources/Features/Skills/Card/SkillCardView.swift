import SwiftUI

struct SkillCardView: View {
    let skill: Skill
    let onTap: () -> Void

    private var categoryGradient: LinearGradient {
        LinearGradient(
            gradient: FMFGradients.forCategory(skill.category),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var categoryAccent: Color {
        FMFGradients.accentForCategory(skill.category)
    }

    private var iconName: String? {
        switch skill.id {
        case "handstand":
            "handstand"
        case "pullups":
            "pullups"
        case "handstand_pushups":
            "handstand_pushups"
        default:
            nil
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: FMFSpacing.sm) {
                if let name = iconName {
                    SkillIconBadge(imageName: name, color: categoryAccent)
                }
                Text(skill.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(0.2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background { categoryGradient }
            .clipShape(RoundedRectangle(cornerRadius: FMFRadius.xl))
            .shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: 8)
            .shadow(color: categoryAccent.opacity(0.30), radius: 20, x: 0, y: 4)
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
                .fill(.white.opacity(0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: FMFRadius.lg)
                        .strokeBorder(.white.opacity(0.30), lineWidth: 1)
                }
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.white)
                .padding(10)
        }
        .frame(width: 64, height: 64)
    }
}
