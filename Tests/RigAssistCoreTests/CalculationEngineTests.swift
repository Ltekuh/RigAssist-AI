import XCTest
@testable import RigAssistCore

final class CalculationEngineTests: XCTestCase {
    
    func testLiftInputValidation() {
        let input = LiftInput(
            loadWeightLb: 5000.0,
            configuration: .twoLegBridle,
            angleDegrees: 60.0,
            slingRatedCapacityLb: 3000.0
        )
        
        XCTAssertGreaterThan(input.loadWeightLb, 0)
        XCTAssertEqual(input.configuration, .twoLegBridle)
        XCTAssertEqual(input.angleDegrees, 60.0)
    }
}