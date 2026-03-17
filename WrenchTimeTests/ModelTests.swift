import Testing
import Foundation
@testable import WrenchTime

@Suite("Component Type Tests")
struct ComponentTypeTests {
    @Test("All component types have default thresholds")
    func defaultThresholds() {
        for type in ComponentType.allCases {
            #expect(type.defaultThresholdMiles > 0, "Missing threshold for \(type)")
        }
    }

    @Test("All component types have display names")
    func displayNames() {
        for type in ComponentType.allCases {
            #expect(!type.displayName.isEmpty, "Missing display name for \(type)")
        }
    }

    @Test("All component types have icon names")
    func iconNames() {
        for type in ComponentType.allCases {
            #expect(!type.iconName.isEmpty, "Missing icon for \(type)")
        }
    }

    @Test("Default bike components are a subset of all cases")
    func defaultComponents() {
        let allCases = Set(ComponentType.allCases)
        for component in ComponentType.defaultBikeComponents {
            #expect(allCases.contains(component))
        }
    }

    @Test("Specific threshold values")
    func specificThresholds() {
        #expect(ComponentType.chain.defaultThresholdMiles == 2000)
        #expect(ComponentType.frontTire.defaultThresholdMiles == 3000)
        #expect(ComponentType.rearTire.defaultThresholdMiles == 2500)
        #expect(ComponentType.cassette.defaultThresholdMiles == 6000)
    }
}

@Suite("Extension Tests")
struct ExtensionTests {
    @Test("Formatted miles")
    func formattedMiles() {
        #expect(1234.0.formattedMiles.contains("1,234"))
        #expect(0.0.formattedMiles.contains("0"))
    }

    @Test("Formatted currency")
    func formattedCurrency() {
        let formatted = 29.99.formattedCurrency
        #expect(!formatted.isEmpty)
    }

    @Test("Date relative description")
    func dateRelative() {
        let now = Date()
        #expect(!now.relativeDescription.isEmpty)
    }

    @Test("Date short formatted")
    func dateShort() {
        let date = Date()
        #expect(!date.shortFormatted.isEmpty)
    }

    @Test("Percent formatted")
    func percentFormatted() {
        #expect(85.percentFormatted == "85%")
        #expect(0.percentFormatted == "0%")
        #expect(100.percentFormatted == "100%")
    }
}
