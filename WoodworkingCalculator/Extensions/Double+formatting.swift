import Foundation

extension Double {
    func formatAsDecimal(toPlaces precision: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: self)) ?? self.formatted()
    }
}
