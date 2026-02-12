import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"

    static var defaultRawValue: String {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true ? AppLanguage.chinese.rawValue : AppLanguage.english.rawValue
    }

    static func resolve(_ rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .english
    }

    var id: String { rawValue }

    var label: String {
        switch self {
        case .english:
            return "EN"
        case .chinese:
            return "中文"
        }
    }
}
