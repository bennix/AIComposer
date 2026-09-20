import Foundation
import SwiftUI

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"

    var id: String { rawValue }

    static let storageKey = "appLanguage"

    var localeIdentifier: String? {
        self == .system ? nil : rawValue
    }

    var locale: Locale {
        if let localeIdentifier { return Locale(identifier: localeIdentifier) }
        return Locale.autoupdatingCurrent
    }

    var title: String {
        switch self {
        case .system: L10n.t("System Default")
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        }
    }

    static func stored() -> AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "system") ?? .system
    }

    static func resolvedLocale() -> Locale { stored().locale }
}

@Observable
@MainActor
final class AppLanguageController {
    static let shared = AppLanguageController()
    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.storageKey) }
    }

    init() { language = .stored() }

    var locale: Locale { language.locale }
}

nonisolated enum L10n {
    static func languageBundle() -> Bundle {
        guard let code = AppLanguage.stored().localeIdentifier else { return .main }
        for name in [code, code.replacingOccurrences(of: "-", with: "_")] {
            if let path = Bundle.main.path(forResource: name, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return .main
    }

    static func t(_ key: String) -> String {
        languageBundle().localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: AppLanguage.resolvedLocale(), arguments: arguments)
    }
}

struct AppLocaleModifier: ViewModifier {
    @Bindable private var languages = AppLanguageController.shared
    func body(content: Content) -> some View {
        content.environment(\.locale, languages.locale)
    }
}

extension View {
    func appLocalized() -> some View {
        modifier(AppLocaleModifier())
    }
}
