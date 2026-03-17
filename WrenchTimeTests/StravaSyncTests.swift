import Testing
import Foundation
@testable import WrenchTime

@Suite("Strava Model Decoding Tests")
struct StravaModelTests {
    @Test("Decode StravaAthlete with bikes")
    func decodeAthlete() throws {
        let json = """
        {
            "id": 12345,
            "firstname": "John",
            "lastname": "Doe",
            "bikes": [
                {
                    "id": "b1234567",
                    "name": "Canyon Aeroad",
                    "primary": true,
                    "distance": 8046720.0
                },
                {
                    "id": "b7654321",
                    "name": "Specialized Diverge",
                    "primary": false,
                    "distance": 3218688.0
                }
            ]
        }
        """.data(using: .utf8)!

        let athlete = try JSONDecoder().decode(StravaAthlete.self, from: json)
        #expect(athlete.id == 12345)
        #expect(athlete.firstname == "John")
        #expect(athlete.bikes.count == 2)
        #expect(athlete.bikes[0].id == "b1234567")
        #expect(athlete.bikes[0].primary == true)
        #expect(athlete.bikes[0].distance == 8046720.0)
    }

    @Test("Decode StravaGear with snake_case keys")
    func decodeGear() throws {
        let json = """
        {
            "id": "b1234567",
            "name": "Canyon Aeroad",
            "brand_name": "Canyon",
            "model_name": "Aeroad CF SLX",
            "distance": 8046720.0,
            "primary": true
        }
        """.data(using: .utf8)!

        let gear = try JSONDecoder().decode(StravaGear.self, from: json)
        #expect(gear.id == "b1234567")
        #expect(gear.brandName == "Canyon")
        #expect(gear.modelName == "Aeroad CF SLX")
        #expect(gear.distance == 8046720.0)
    }

    @Test("Decode StravaTokenResponse")
    func decodeTokenResponse() throws {
        let json = """
        {
            "access_token": "abc123",
            "refresh_token": "def456",
            "expires_at": 1700000000
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StravaTokenResponse.self, from: json)
        #expect(response.accessToken == "abc123")
        #expect(response.refreshToken == "def456")
        #expect(response.expiresAt == 1700000000)
        #expect(response.athlete == nil)
    }

    @Test("Decode StravaGear with nil brand/model")
    func decodeGearNilOptionals() throws {
        let json = """
        {
            "id": "b9999999",
            "name": "My Bike",
            "distance": 0.0,
            "primary": false
        }
        """.data(using: .utf8)!

        let gear = try JSONDecoder().decode(StravaGear.self, from: json)
        #expect(gear.brandName == nil)
        #expect(gear.modelName == nil)
    }
}

@Suite("Distance Unit Tests")
struct DistanceUnitTests {
    @Test("Miles abbreviation")
    func milesAbbreviation() {
        #expect(DistanceUnit.miles.abbreviation == "mi")
    }

    @Test("Kilometers abbreviation")
    func kmAbbreviation() {
        #expect(DistanceUnit.kilometers.abbreviation == "km")
    }

    @Test("Conversion from meters")
    func conversion() {
        #expect(DistanceUnit.miles.conversionFromMeters == 1609.34)
        #expect(DistanceUnit.kilometers.conversionFromMeters == 1000.0)
    }
}
