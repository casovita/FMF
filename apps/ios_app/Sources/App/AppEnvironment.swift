import Foundation

enum AppFlavor: String {
    case dev
    case staging
    case prod

    static var current: AppFlavor {
        let value = Bundle.main.object(forInfoDictionaryKey: "APP_FLAVOR") as? String ?? "dev"
        return AppFlavor(rawValue: value) ?? .dev
    }

    var isDev: Bool { self == .dev }
    var isStaging: Bool { self == .staging }
    var isProd: Bool { self == .prod }
    var displayLabel: String {
        switch self {
        case .dev: return "[DEV]"
        case .staging: return "[STAGING]"
        case .prod: return ""
        }
    }
}
