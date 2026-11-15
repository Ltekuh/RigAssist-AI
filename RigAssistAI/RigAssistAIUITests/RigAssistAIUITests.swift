// Leonel's contribution: Verify the integrated Reference and Ask AI navigation fallback.
//
//  RigAssistAIUITests.swift
//  RigAssistAIUITests
//
//  Created by Macauley Wain on 11/2/26.
//

import XCTest

final class RigAssistAIUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Calculator"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Reference"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ask AI"].exists)
    }

    @MainActor
    func testAskAIExplainsWhenNoVerifiedReferencesExist() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Ask AI"].tap()
        let questionField = app.descendants(matching: .any)
            .matching(identifier: "assistant.question")
            .firstMatch
        XCTAssertTrue(questionField.waitForExistence(timeout: 5))
        questionField.tap()
        questionField.typeText("sling angle")
        app.buttons["Ask"].tap()

        let answer = app.staticTexts["assistant.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        XCTAssertTrue(answer.label.contains("verified local reference"))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
