import Foundation

extension Double {
    /// Format as miles string, e.g. "1,234 mi"
    var formattedMiles: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "\(formatted) mi"
    }

    /// Format as distance with unit
    func formattedDistance(unit: DistanceUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "\(formatted) \(unit.abbreviation)"
    }

    /// Format as currency
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}

extension Date {
    /// Relative description, e.g. "2 hours ago", "yesterday"
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Short date format, e.g. "Mar 17, 2026"
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

extension Int {
    /// Format as a percentage string, e.g. "85%"
    var percentFormatted: String {
        "\(self)%"
    }
}
