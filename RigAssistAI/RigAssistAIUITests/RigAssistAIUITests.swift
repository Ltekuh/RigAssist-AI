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
    func testAskAIExplainsWhenNoVerifiedReferenceMatches() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Ask AI"].tap()
        let questionField = app.descendants(matching: .any)
            .matching(identifier: "assistant.question")
            .firstMatch
        XCTAssertTrue(questionField.waitForExistence(timeout: 5))
        questionField.tap()
        questionField.typeText("unsupported fixture zebra")
        app.buttons["Ask"].tap()

        let answer = app.staticTexts["assistant.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        XCTAssertTrue(answer.label.contains("verified local reference"))
    }

    @MainActor
    func testReferenceAndAskAIUseTheSameTestRecord() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing-reference-flow")
        app.launch()

        let weight = app.textFields["Enter weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5))
        weight.tap()
        weight.typeText("1000")
        let capacity = app.textFields["Enter capacity"]
        capacity.tap()
        capacity.typeText("2000")
        app.swipeUp()
        app.buttons["CALCULATE"].tap()
        XCTAssertTrue(app.staticTexts["Within Rated Capacity"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["50% capacity utilization"].exists)

        app.tabBars.buttons["Reference"].tap()
        let search = app.textFields["Search references"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("fixture topic")
        XCTAssertTrue(app.staticTexts["Fixture topic alpha"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Ask AI"].tap()
        ask("fixture topic", in: app)
        let answer = app.staticTexts["assistant.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        XCTAssertEqual(answer.label, "Synthetic fixture context.")
        XCTAssertTrue(app.staticTexts["REF-900"].exists)
        XCTAssertTrue(app.staticTexts["Synthetic test source"].exists)
        XCTAssertTrue(app.staticTexts["UI TEST DATA ONLY. Not a rigging reference."].exists)
    }

    @MainActor
    func testCalculationRequestIsBlockedWithTestProviderConfigured() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing-reference-flow")
        app.launch()
        app.tabBars.buttons["Ask AI"].tap()
        ask("Calculate fixture topic tension for 5000 lb", in: app)
        let answer = app.staticTexts["assistant.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        XCTAssertTrue(answer.label.contains("deterministic Calculator"))
        XCTAssertFalse(app.staticTexts["REF-900"].exists)
    }

    @MainActor
    func testProviderFailureShowsCitedLocalFallback() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing-reference-flow", "--ui-testing-provider-failure"]
        app.launch()
        app.tabBars.buttons["Ask AI"].tap()
        ask("fixture topic", in: app)
        let answer = app.staticTexts["assistant.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        XCTAssertTrue(answer.label.contains("Synthetic fixture summary."))
        XCTAssertTrue(app.staticTexts["REF-900"].exists)
        XCTAssertTrue(app.staticTexts["Synthetic test source"].exists)
        XCTAssertTrue(app.staticTexts["Why this response was limited"].exists)
    }

    @MainActor
    private func ask(_ question: String, in app: XCUIApplication) {
        let field = app.descendants(matching: .any)
            .matching(identifier: "assistant.question").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(question)
        app.buttons["Ask"].tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
