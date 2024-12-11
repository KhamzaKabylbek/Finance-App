import Foundation

struct Settings: Codable {
    var currency: Currency
    var isDarkMode: Bool
    var financialGoals: [FinancialGoal]
    
    static let defaultSettings = Settings(
        currency: .kzt,
        isDarkMode: false,
        financialGoals: []
    )
}

enum Currency: String, CaseIterable, Codable {
    case kzt = "₸"
    case usd = "$"
    case eur = "€"
    case rub = "₽"
    
    var name: String {
        switch self {
        case .kzt: return "Тенге"
        case .usd: return "Доллар США"
        case .eur: return "Евро"
        case .rub: return "Рубль"
        }
    }
}

struct FinancialGoal: Identifiable, Codable {
    var id = UUID()
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date
    var category: Category?
    
    var progress: Double {
        currentAmount / targetAmount
    }
} 