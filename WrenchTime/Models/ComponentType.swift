import Foundation

enum BrakeType: String, Codable, CaseIterable, Identifiable {
    case disc
    case rim

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .disc: return "Disc"
        case .rim:  return "Rim"
        }
    }
}

enum ComponentType: String, Codable, CaseIterable, Identifiable {
    case chain
    case frontTire
    case rearTire
    case brakePadsFront
    case brakePadsRear
    case cassette
    case cables
    case barTape
    case custom

    var id: String { rawValue }

    /// Default threshold ignoring brake type (uses disc defaults for brake pads)
    var defaultThresholdMiles: Double {
        defaultThresholdMiles(brakeType: .disc)
    }

    /// Default threshold accounting for brake type
    func defaultThresholdMiles(brakeType: BrakeType) -> Double {
        switch self {
        case .chain:           return 2000
        case .frontTire:       return 3000
        case .rearTire:        return 2500
        case .brakePadsFront, .brakePadsRear:
            switch brakeType {
            case .disc: return 1000
            case .rim:  return 3000
            }
        case .cassette:        return 6000
        case .cables:          return 4000
        case .barTape:         return 3000
        case .custom:          return 1000
        }
    }

    var displayName: String {
        switch self {
        case .chain:           return "Chain"
        case .frontTire:       return "Front Tire"
        case .rearTire:        return "Rear Tire"
        case .brakePadsFront:  return "Brake Pads (Front)"
        case .brakePadsRear:   return "Brake Pads (Rear)"
        case .cassette:        return "Cassette"
        case .cables:          return "Cables"
        case .barTape:         return "Bar Tape"
        case .custom:          return "Custom"
        }
    }

    var iconName: String {
        switch self {
        case .chain:           return "link"
        case .frontTire:       return "circle.circle"
        case .rearTire:        return "circle.circle.fill"
        case .brakePadsFront:  return "hand.raised"
        case .brakePadsRear:   return "hand.raised.fill"
        case .cassette:        return "gearshape.2"
        case .cables:          return "cable.connector"
        case .barTape:         return "rectangle.roundedtop"
        case .custom:          return "wrench"
        }
    }

    /// Default components to add when a new bike is created
    static var defaultBikeComponents: [ComponentType] {
        [.chain, .frontTire, .rearTire, .brakePadsFront, .brakePadsRear, .cassette]
    }
}
