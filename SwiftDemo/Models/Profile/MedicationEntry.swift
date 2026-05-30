import Foundation

struct MedicationEntry {
    var name: String
    var dosage: String
    var morning: Bool
    var afternoon: Bool
    var night: Bool

    init(name: String, dosage: String = "", morning: Bool, afternoon: Bool, night: Bool) {
        self.name = name
        self.dosage = dosage
        self.morning = morning
        self.afternoon = afternoon
        self.night = night
    }

    // Format: "Dolo 500mg (1-0-1)"
    var displayString: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        let d = dosage.trimmingCharacters(in: .whitespaces)
        let nameAndDose = d.isEmpty ? trimmed : "\(trimmed) \(d)"
        let m = morning ? "1" : "0"
        let a = afternoon ? "1" : "0"
        let n = night ? "1" : "0"
        return "\(nameAndDose) (\(m)-\(a)-\(n))"
    }

    // Parse "Dolo 500mg (1-0-1), Paracetamol (1-1-1)" into entries
    static func parse(from string: String) -> [MedicationEntry] {
        guard !string.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let parts = string.components(separatedBy: ",")
        return parts.compactMap { part in
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            // Pattern: "name optional-dosage (m-a-n)"
            let pattern = #"^(.+?)\s+(\S+\s+)?\((\d)-(\d)-(\d)\)$"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
               let nameRange = Range(match.range(at: 1), in: trimmed),
               let mRange = Range(match.range(at: 3), in: trimmed),
               let aRange = Range(match.range(at: 4), in: trimmed),
               let nRange = Range(match.range(at: 5), in: trimmed) {
                let dosage = Range(match.range(at: 2), in: trimmed)
                    .map { String(trimmed[$0]).trimmingCharacters(in: .whitespaces) } ?? ""
                return MedicationEntry(
                    name: String(trimmed[nameRange]),
                    dosage: dosage,
                    morning: String(trimmed[mRange]) == "1",
                    afternoon: String(trimmed[aRange]) == "1",
                    night: String(trimmed[nRange]) == "1"
                )
            }
            // Plain text fallback
            return MedicationEntry(name: trimmed, morning: false, afternoon: false, night: false)
        }
    }

    // Convert entries back to display string
    static func toString(_ entries: [MedicationEntry]) -> String {
        entries
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.displayString }
            .joined(separator: ", ")
    }
}
