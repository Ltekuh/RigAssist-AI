import XCTest
@testable import RigAssistCore

final class CalculationEngineTests: XCTestCase {
    private let engine = CalculationEngine()

    private func input(_ weight: Double = 5_000, capacity: Double = 4_000,
                       configuration: SlingConfiguration = .twoLegBridle,
                       angle: Double? = 60) -> LiftInput {
        LiftInput(loadWeightLb: weight, configuration: configuration,
                  angleDegrees: angle, slingRatedCapacityLb: capacity)
    }

    func testVerticalHitch() throws {
        let result = try engine.calculate(input: input(configuration: .verticalHitch, angle: nil)).get()
        XCTAssertEqual(result.angleMultiplier, 1)
        XCTAssertEqual(result.loadPerLegLb, 5_000)
        XCTAssertEqual(result.tensionPerLegLb, 5_000)
        XCTAssertEqual(result.utilization, 1.25)
        XCTAssertFalse(result.withinRatedCapacity)
        XCTAssertTrue(result.warnings.contains { $0.contains("exceeds") })
    }

    func testKnownBridleAngles() throws {
        // Independent analytical expectations, rather than a second sine implementation.
        for (angle, factor) in [(30.0, 2.0), (45, Double(2).squareRoot()),
                                (60, 2 / Double(3).squareRoot()), (90, 1)] {
            let result = try engine.calculate(input: input(angle: angle)).get()
            XCTAssertEqual(result.angleMultiplier, factor, accuracy: 1e-12)
            XCTAssertEqual(result.loadPerLegLb, 2_500)
            XCTAssertEqual(result.tensionPerLegLb, 2_500 * factor, accuracy: 1e-9)
            XCTAssertEqual(result.utilization, 2_500 * factor / 4_000, accuracy: 1e-12)
            XCTAssertEqual(result.withinRatedCapacity, angle != 30)
            XCTAssertTrue(result.warnings.contains { $0.contains("equal load sharing") })
        }
    }

    func testCapacityBoundaryUsesUnroundedTension() throws {
        for angle in [30.0, 45, 60, 90] {
            let tension = try engine.calculate(input: input(angle: angle)).get().tensionPerLegLb
            for (capacity, expected) in [(tension.nextDown, false), (tension, true), (tension.nextUp, true)] {
                let result = try engine.calculate(input: input(capacity: capacity, angle: angle)).get()
                XCTAssertEqual(result.withinRatedCapacity, expected)
                XCTAssertEqual(result.warnings.contains { $0.contains("exceeds") }, !expected)
            }
        }
        let exact = try engine.calculate(input: input(capacity: 5_000, angle: 30)).get()
        XCTAssertEqual(exact.tensionPerLegLb, 5_000)
        XCTAssertEqual(exact.utilization, 1)
        XCTAssertTrue(exact.withinRatedCapacity)
    }

    func testRejectsInvalidWeightsAndCapacities() {
        for value in [0.0, -1, .nan, .infinity, -.infinity] {
            XCTAssertEqual(engine.calculate(input: input(value)), .failure(.invalidNumber))
            XCTAssertEqual(engine.calculate(input: input(capacity: value)), .failure(.invalidNumber))
        }
    }

    func testAngleValidation() {
        XCTAssertEqual(engine.calculate(input: input(angle: nil)), .failure(.missingAngle))
        for angle in [0.0, -30, 29.999, 90.001, 180] {
            XCTAssertEqual(engine.calculate(input: input(angle: angle)), .failure(.angleOutOfSupportedRange))
        }
        for angle in [Double.nan, .infinity, -.infinity] {
            XCTAssertEqual(engine.calculate(input: input(angle: angle)), .failure(.invalidNumber))
        }
        for angle in [30.0, .nan] {
            XCTAssertEqual(engine.calculate(input: input(configuration: .verticalHitch, angle: angle)),
                           .failure(.unexpectedAngle))
        }
    }

    func testRejectsUnrepresentableDerivedValues() {
        XCTAssertEqual(engine.calculate(input: input(.greatestFiniteMagnitude, capacity: .leastNonzeroMagnitude)),
                       .failure(.invalidNumber))
        XCTAssertEqual(engine.calculate(input: input(.leastNonzeroMagnitude)), .failure(.invalidNumber))
    }

    func testFractionalInputs() throws {
        let result = try engine.calculate(input: input(125.5, capacity: 200.25, angle: 90)).get()
        XCTAssertEqual(result.tensionPerLegLb, 62.75)
        XCTAssertTrue(result.withinRatedCapacity)
    }

    func testRepeatableLocalCalculationsWithoutExternalServices() throws {
        let request = input()
        let baseline = engine.calculate(input: request)
        for _ in 0..<100 {
            XCTAssertEqual(CalculationEngine().calculate(input: request), baseline)
        }
        XCTAssertEqual(try baseline.get().tensionPerLegLb, 2_886.751345948129, accuracy: 1e-9)
    }
}
