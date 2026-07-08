import Foundation

struct SamsungDevice: Equatable, Sendable {
    var name: String
    var model: String?
    var serial: String?
    var connection: String
    var carrierHint: Carrier? = nil

    var displayModel: String { name.isEmpty ? (model ?? "Samsung Galaxy") : name }
    var maskedSerial: String? {
        guard let serial, serial.count > 4 else { return serial }
        return String(repeating: "•", count: max(4, serial.count - 4)) + serial.suffix(4)
    }
}

enum Carrier: String, CaseIterable, Identifiable {
    case att = "AT&T"
    case tmobile = "T-Mobile"
    case verizon = "Verizon"
    case other = "Another carrier"

    var id: String { rawValue }

    init?(salesCode: String) {
        switch salesCode.uppercased() {
        case "ATT", "AIO": self = .att
        case "TMB", "TMK", "TMO", "MET": self = .tmobile
        case "VZW", "VPP": self = .verizon
        default: return nil
        }
    }

    var officialURL: URL {
        switch self {
        case .att: URL(string: "https://www.att.com/deviceunlock/")!
        case .tmobile: URL(string: "https://www.t-mobile.com/support/devices/unlock-your-mobile-wireless-device")!
        case .verizon: URL(string: "https://www.verizon.com/support/device-unlocking-policy/")!
        case .other: URL(string: "https://www.samsung.com/us/support/contact/")!
        }
    }

    var actionTitle: String {
        switch self {
        case .att: "Open AT&T unlock service"
        case .tmobile: "Open T-Mobile instructions"
        case .verizon: "Review Verizon unlock status"
        case .other: "Contact Samsung support"
        }
    }

    var guidance: String {
        switch self {
        case .att:
            "AT&T checks payment, account, and lost-or-stolen status. Eligible Android phones may be directed to AT&T’s Device Unlock app."
        case .tmobile:
            "On the phone, open Settings → Connections → More connection settings → Network Unlock → Permanent Unlock. T-Mobile confirms eligibility on its servers."
        case .verizon:
            "Eligible Verizon devices are generally unlocked automatically under the current policy. Review your device status and contact Verizon if it remains locked."
        case .other:
            "Only the carrier that locked the phone can authorize its unlock. Samsung Support can help identify the right carrier path."
        }
    }
}
