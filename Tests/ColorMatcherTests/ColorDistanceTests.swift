import XCTest
@testable import Core
import class Foundation.Bundle

final class ColorDistanceTests: XCTestCase {

    func testDistance() throws {
        let specs: [Core.ColorSpec] = [
            .init(name: "Spec1", value: "0x009000"),
            .init(name: "Spec2", value: "0xFA0000"),
            .init(name: "Spec3", value: "0xDD0000"),
            .init(name: "Spec4", value: "0x00C000"),
            .init(name: "Spec5", value: "0x0000D0"),
            .init(name: "Spec6", value: "0x0000C9"),
            .init(name: "Spec7", value: "0x0000A9"),
        ]

        let redValue = Core.ColorSpec(name: "Red", value: "0xDD0000")
        let redResults = specs.map { ($0, ColorDistance.distance(from: redValue, to: $0)) }
        let redBestResult = redResults.sorted { $0.1 < $1.1 }.first!.0
        XCTAssertEqual(redBestResult.name, "Spec3")

        let greenValue = Core.ColorSpec(name: "Red", value: "0x00A000")
        let greenResults = specs.map { ($0, ColorDistance.distance(from: greenValue, to: $0)) }
        let greenBestResult = greenResults.sorted { $0.1 < $1.1 }.first!.0
        XCTAssertEqual(greenBestResult.name, "Spec1")

        let blueValue = Core.ColorSpec(name: "Red", value: "0x0000F1")
        let blueResults = specs.map { ($0, ColorDistance.distance(from: blueValue, to: $0)) }
        let blueBestResult = blueResults.sorted { $0.1 < $1.1 }.first!.0
        XCTAssertEqual(blueBestResult.name, "Spec5")
    }
}
