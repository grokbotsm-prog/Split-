import Foundation

// Same cent rules as the web page. The tip is rounded once, half a cent up,
// then the total is split so shares differ by at most one cent and add up exactly.

enum CheckSplit {
    static let presets = [15, 18, 20, 25]
    static let maxPeople = 99

    struct Result {
        var billCents: Int
        var basisPoints: Int
        var tipCents: Int
        var totalCents: Int
        var people: Int
        var shares: [Int]

        var isEven: Bool {
            guard let first = shares.first else { return true }
            return shares.allSatisfy { $0 == first }
        }

        var higherCount: Int {
            guard let higher = shares.first else { return 0 }
            return shares.filter { $0 == higher }.count
        }
    }

    static func calculate(bill: String, tip: String, people: Int) -> Result {
        let billText = sanitizeMoney(bill)
        let tipText = sanitizePercent(tip)
        let count = clampPeople(people)
        let billCents = moneyToCents(billText)
        let basisPoints = percentToBps(tipText)
        let tipAmount = tipCents(billCents: billCents, basisPoints: basisPoints)
        let total = billCents + tipAmount
        return Result(
            billCents: billCents,
            basisPoints: basisPoints,
            tipCents: tipAmount,
            totalCents: total,
            people: count,
            shares: splitCents(total, people: count)
        )
    }

    static func sanitizeMoney(_ raw: String) -> String {
        var value = String(raw.filter { character in
            character != "$" && character != "€" && character != "£" && character != "¥" && !character.isWhitespace
        })
        let lastComma = value.lastIndex(of: ",")
        let lastDot = value.lastIndex(of: ".")
        if let lastComma, let lastDot {
            if lastComma > lastDot {
                value = value.replacingOccurrences(of: ".", with: "")
                value = value.replacingOccurrences(of: ",", with: ".")
            } else {
                value = value.replacingOccurrences(of: ",", with: "")
            }
        } else if value.contains(",") {
            if isThousandsGrouped(value) {
                value = value.replacingOccurrences(of: ",", with: "")
            } else {
                value = value.replacingOccurrences(of: ",", with: ".")
            }
        }

        let digitsAndDot = String(value.filter { isDigit($0) || $0 == "." })
        guard let dot = digitsAndDot.firstIndex(of: ".") else {
            return String(stripLeadingZeros(String(digitsAndDot.filter(isDigit))).prefix(6))
        }
        let whole = String(stripLeadingZeros(String(digitsAndDot[..<dot].filter(isDigit))).prefix(6))
        let frac = String(digitsAndDot[digitsAndDot.index(after: dot)...].filter(isDigit).prefix(2))
        return (whole.isEmpty ? "0" : whole) + "." + frac
    }

    static func sanitizePercent(_ raw: String) -> String {
        let value = String(raw.replacingOccurrences(of: ",", with: ".").filter { isDigit($0) || $0 == "." })
        let hasDot = value.contains(".")
        var whole: String
        var frac = ""
        if let dot = value.firstIndex(of: ".") {
            whole = String(value[..<dot].filter(isDigit))
            frac = String(value[value.index(after: dot)...].filter(isDigit).prefix(2))
        } else {
            whole = value
        }
        whole = String(stripLeadingZeros(whole).prefix(3))
        if whole.isEmpty && !hasDot { return "" }
        if whole.isEmpty { whole = "0" }
        if (Int(whole) ?? 0) >= 100 { return "100" }
        let numeric = Double(whole + "." + (frac.isEmpty ? "0" : frac)) ?? 0
        if numeric > 100 { return "100" }
        return hasDot ? whole + "." + frac : whole
    }

    static func tidyMoney(_ raw: String) -> String {
        let sanitized = sanitizeMoney(raw)
        if sanitized.isEmpty || sanitized == "." { return "" }
        let cents = moneyToCents(sanitized)
        return "\(cents / 100)." + String(format: "%02d", cents % 100)
    }

    static func tidyPercent(_ raw: String) -> String {
        var next = sanitizePercent(raw)
        if next.isEmpty || next == "." { return "0" }
        if next.hasSuffix(".") { next.removeLast() }
        if next.contains(".") {
            while next.hasSuffix("0") { next.removeLast() }
            if next.hasSuffix(".") { next.removeLast() }
        }
        return next.isEmpty ? "0" : next
    }

    static func moneyToCents(_ text: String) -> Int {
        if text.isEmpty || text == "." { return 0 }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        let dollars = Int(parts.first ?? "0") ?? 0
        var frac = parts.count > 1 ? String(parts[1]) : ""
        if frac.count < 2 {
            frac = frac.padding(toLength: 2, withPad: "0", startingAt: 0)
        }
        let cents = Int(frac.prefix(2)) ?? 0
        return dollars * 100 + cents
    }

    // 18% = 1800, 18.5% = 1850, 18.25% = 1825.
    static func percentToBps(_ text: String) -> Int {
        if text.isEmpty || text == "." { return 0 }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        let whole = Int(parts.first ?? "0") ?? 0
        var fracText = parts.count > 1 ? String(parts[1]) : ""
        if fracText.count < 2 {
            fracText = fracText.padding(toLength: 2, withPad: "0", startingAt: 0)
        }
        let frac = Int(fracText.prefix(2)) ?? 0
        return min(10000, whole * 100 + frac)
    }

    static func tipCents(billCents: Int, basisPoints: Int) -> Int {
        (billCents * basisPoints + 5000) / 10000
    }

    static func clampPeople(_ people: Int) -> Int {
        min(max(people, 1), maxPeople)
    }

    static func splitCents(_ totalCents: Int, people: Int) -> [Int] {
        let count = clampPeople(people)
        let base = totalCents / count
        let extra = totalCents % count
        return (0..<count).map { index in index < extra ? base + 1 : base }
    }

    static func formatCents(_ cents: Int) -> String {
        let negative = cents < 0
        let absolute = abs(cents)
        let dollars = absolute / 100
        let frac = absolute % 100
        return (negative ? "-$" : "$") + grouped(dollars) + "." + String(format: "%02d", frac)
    }

    static func formatPercent(_ basisPoints: Int) -> String {
        let whole = basisPoints / 100
        let frac = basisPoints % 100
        if frac == 0 { return "\(whole)%" }
        if frac % 10 == 0 { return "\(whole).\(frac / 10)%" }
        return String(format: "%d.%02d%%", whole, frac)
    }

    private static func grouped(_ value: Int) -> String {
        let digits = String(value)
        var out = ""
        for (index, character) in digits.reversed().enumerated() {
            if index > 0 && index % 3 == 0 { out.append(",") }
            out.append(character)
        }
        return String(out.reversed())
    }

    private static func stripLeadingZeros(_ digits: String) -> String {
        var result = digits
        while result.count > 1 && result.first == "0" {
            result.removeFirst()
        }
        return result
    }

    private static func isDigit(_ character: Character) -> Bool {
        character >= "0" && character <= "9"
    }

    private static func isThousandsGrouped(_ text: String) -> Bool {
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return false }
        guard (1...3).contains(parts[0].count), parts[0].allSatisfy(isDigit) else { return false }
        return parts.dropFirst().allSatisfy { $0.count == 3 && $0.allSatisfy(isDigit) }
    }
}
