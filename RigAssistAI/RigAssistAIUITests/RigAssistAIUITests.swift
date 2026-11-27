//
//  RigAssistAIUITests.swift
//  RigAssistAIUITests
//
//  Created by Macauley Wain on 11/2/26.
//
//  UI tests for the integrated RigAssist AI application.
//  These tests verify navigation and interaction across the Calculator,
//  Reference Library, and Ask AI interfaces.
//
//  Leonel's Reference/AI integration fixture is used only when explicitly
//  enabled through the UI-testing launch argument. It does not alter the
//  approval status of the bundled production reference dataset.
//

import XCTest

final class RigAssistAIUITests: XCTestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        // Stop immediately when a test assertion fails so later UI actions
        // do not produce misleading secondary failures.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // No persistent UI-test state currently requires cleanup.
    }

    // MARK: - Basic Navigation

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.tabBars.buttons["Calculator"].waitForExistence(timeout: 5),
            "Calculator tab should appear after launch."
        )

        XCTAssertTrue(
            app.tabBars.buttons["Reference"].exists,
            "Reference tab should appear after launch."
        )

        XCTAssertTrue(
            app.tabBars.buttons["Ask AI"].exists,
            "Ask AI tab should appear after launch."
        )
    }

    // MARK: - Production Fallback Behavior

    @MainActor
    func testAskAIExplainsWhenNoVerifiedReferenceMatches() throws {
        let app = XCUIApplication()
        app.launch()

        let askAITab = app.tabBars.buttons["Ask AI"]

        XCTAssertTrue(
            askAITab.waitForExistence(timeout: 5),
            "Ask AI tab should be available."
        )

        askAITab.tap()

        let questionField = app.textFields["assistant.question"]

        XCTAssertTrue(
            questionField.waitForExistence(timeout: 10),
            "Ask AI question field should appear after selecting the Ask AI tab."
        )

        questionField.tap()
        questionField.typeText("unsupported fixture zebra")

        let askButton = app.buttons["Ask"]

        XCTAssertTrue(
            askButton.waitForExistence(timeout: 5),
            "Ask button should appear after entering a question."
        )

        XCTAssertTrue(
            askButton.isEnabled,
            "Ask button should be enabled after entering a question."
        )

        askButton.tap()

        let answer = app.staticTexts["assistant.answer"]

        XCTAssertTrue(
            answer.waitForExistence(timeout: 10),
            "Ask AI should display a controlled response."
        )

        XCTAssertTrue(
            answer.label.contains("verified local reference"),
            "Unsupported questions should explain that no verified local reference was found."
        )
    }

    // MARK: - Integrated Calculator / Reference / Ask AI Flow

    @MainActor
    func testReferenceAndAskAIUseTheSameTestRecord() throws {
        let app = XCUIApplication()

        // Enable Leonel's synthetic Reference-to-Ask-AI integration fixture.
        // This fixture is test-only and does not mark production rigging
        // references as verified.
        app.launchArguments.append("--ui-testing-reference-flow")
        app.launch()

        // ---------------------------------------------------------
        // Calculator
        // ---------------------------------------------------------

        let weight = app.textFields["Enter weight"]

        XCTAssertTrue(
            weight.waitForExistence(timeout: 5),
            "Calculator load-weight field should appear after launch."
        )

        weight.tap()
        weight.typeText("1000")

        let capacity = app.textFields["Enter capacity"]

        XCTAssertTrue(
            capacity.waitForExistence(timeout: 5),
            "Calculator capacity field should appear."
        )

        capacity.tap()
        capacity.typeText("2000")

        // Move the interface so the Calculate button is accessible.
        app.swipeUp()

        let calculateButton = app.buttons["CALCULATE"]

        XCTAssertTrue(
            calculateButton.waitForExistence(timeout: 5),
            "Calculate button should be available."
        )

        calculateButton.tap()

        XCTAssertTrue(
            app.staticTexts["Within Rated Capacity"]
                .waitForExistence(timeout: 10),
            "Valid calculator inputs should produce a within-capacity result."
        )

        XCTAssertTrue(
            app.staticTexts["50% capacity utilization"].exists,
            "1000 lb against 2000 lb capacity should display 50% utilization."
        )

        // ---------------------------------------------------------
        // Reference Library
        // ---------------------------------------------------------

        let referenceTab = app.tabBars.buttons["Reference"]

        XCTAssertTrue(
            referenceTab.waitForExistence(timeout: 5),
            "Reference tab should remain available after calculation."
        )

        referenceTab.tap()

        let search = app.textFields["Search references"]

        XCTAssertTrue(
            search.waitForExistence(timeout: 10),
            "Reference search field should appear after selecting Reference."
        )

        search.tap()
        search.typeText("fixture topic")

        XCTAssertTrue(
            app.staticTexts["Fixture topic alpha"]
                .waitForExistence(timeout: 10),
            "Synthetic verified test record should appear in the Reference Library."
        )

        // ---------------------------------------------------------
        // Keyboard Dismissal
        // ---------------------------------------------------------
        //
        // The Reference search field leaves the software keyboard visible.
        // During automated UI testing the keyboard can interfere with the
        // transition from the Reference tab to the Ask AI tab.
        //
        // Try the keyboard's Return/Search/Done button first. If one is not
        // exposed by the current simulator keyboard, tapping the navigation
        // title gives the field a chance to resign focus.

        dismissKeyboardIfNeeded(in: app)

        // ---------------------------------------------------------
        // Ask AI
        // ---------------------------------------------------------

        let askAITab = app.tabBars.buttons["Ask AI"]

        XCTAssertTrue(
            askAITab.waitForExistence(timeout: 5),
            "Ask AI tab should remain available after Reference navigation."
        )

        askAITab.tap()

        // Verify that the tab transition actually completed before the
        // helper attempts to interact with the question field.
        XCTAssertTrue(
            app.navigationBars["Ask RigAssist AI"]
                .waitForExistence(timeout: 10),
            "Ask AI screen should appear after selecting the Ask AI tab."
        )

        ask("fixture topic", in: app)

        let answer = app.staticTexts["assistant.answer"]

        XCTAssertTrue(
            answer.waitForExistence(timeout: 10),
            "Ask AI should return an answer using the synthetic test reference."
        )

        XCTAssertEqual(
            answer.label,
            "Synthetic fixture context.",
            "Ask AI should return the expected deterministic test-provider response."
        )

        XCTAssertTrue(
            app.staticTexts["REF-900"]
                .waitForExistence(timeout: 5),
            "Ask AI response should cite the synthetic reference ID."
        )

        XCTAssertTrue(
            app.staticTexts["Synthetic test source"].exists,
            "Ask AI response should display the synthetic source."
        )

        XCTAssertTrue(
            app.staticTexts[
                "UI TEST DATA ONLY. Not a rigging reference."
            ].exists,
            "Synthetic content should remain clearly identified as test-only data."
        )
    }

    // MARK: - Calculation Blocking

    @MainActor
    func testCalculationRequestIsBlockedWithTestProviderConfigured() throws {
        let app = XCUIApplication()

        app.launchArguments.append("--ui-testing-reference-flow")
        app.launch()

        let askAITab = app.tabBars.buttons["Ask AI"]

        XCTAssertTrue(
            askAITab.waitForExistence(timeout: 5),
            "Ask AI tab should be available."
        )

        askAITab.tap()

        ask(
            "Calculate fixture topic tension for 5000 lb",
            in: app
        )

        let answer = app.staticTexts["assistant.answer"]

        XCTAssertTrue(
            answer.waitForExistence(timeout: 10),
            "Calculation request should produce a controlled response."
        )

        XCTAssertTrue(
            answer.label.contains("deterministic Calculator"),
            "Ask AI should direct calculation requests to the deterministic Calculator."
        )

        XCTAssertFalse(
            app.staticTexts["REF-900"].exists,
            "Blocked calculation requests should not produce an AI citation."
        )
    }

    // MARK: - Provider Failure Fallback

    @MainActor
    func testProviderFailureShowsCitedLocalFallback() throws {
        let app = XCUIApplication()

        app.launchArguments += [
            "--ui-testing-reference-flow",
            "--ui-testing-provider-failure"
        ]

        app.launch()

        let askAITab = app.tabBars.buttons["Ask AI"]

        XCTAssertTrue(
            askAITab.waitForExistence(timeout: 5),
            "Ask AI tab should be available."
        )

        askAITab.tap()

        ask("fixture topic", in: app)

        let answer = app.staticTexts["assistant.answer"]

        XCTAssertTrue(
            answer.waitForExistence(timeout: 10),
            "Provider failure should produce a local fallback response."
        )

        XCTAssertTrue(
            answer.label.contains("Synthetic fixture summary."),
            "Provider failure should fall back to approved local reference content."
        )

        XCTAssertTrue(
            app.staticTexts["REF-900"]
                .waitForExistence(timeout: 5),
            "Fallback response should retain the reference citation."
        )

        XCTAssertTrue(
            app.staticTexts["Synthetic test source"].exists,
            "Fallback response should display its source."
        )

        XCTAssertTrue(
            app.staticTexts["Why this response was limited"].exists,
            "Fallback response should explain why AI output was limited."
        )
    }

    // MARK: - Ask AI Helper

    /// Enters and submits a question through the Ask AI interface.
    ///
    /// The accessibility identifier is defined in AskAIView.swift as
    /// `assistant.question`.
    @MainActor
    private func ask(
        _ question: String,
        in app: XCUIApplication
    ) {
        let field = app.textFields["assistant.question"]

        XCTAssertTrue(
            field.waitForExistence(timeout: 10),
            "Ask AI question field should appear after selecting the Ask AI tab."
        )

        field.tap()
        field.typeText(question)

        let askButton = app.buttons["Ask"]

        XCTAssertTrue(
            askButton.waitForExistence(timeout: 5),
            "Ask button should appear after entering a question."
        )

        XCTAssertTrue(
            askButton.isEnabled,
            "Ask button should be enabled after entering a question."
        )

        askButton.tap()
    }

    // MARK: - Keyboard Helper

    /// Attempts to dismiss the software keyboard before automated tab
    /// navigation. Different simulator keyboards can expose different
    /// dismissal button labels, so several common labels are supported.
    @MainActor
    private func dismissKeyboardIfNeeded(
        in app: XCUIApplication
    ) {
        let keyboard = app.keyboards.firstMatch

        guard keyboard.exists else {
            return
        }

        let doneButton = keyboard.buttons["Done"]
        let returnButton = keyboard.buttons["Return"]
        let searchButton = keyboard.buttons["Search"]

        if doneButton.exists {
            doneButton.tap()
        } else if returnButton.exists {
            returnButton.tap()
        } else if searchButton.exists {
            searchButton.tap()
        } else {
            // Fallback for simulator keyboards that do not expose a
            // dedicated dismissal key to XCUI.
            app.navigationBars["Reference Library"].tap()
        }

        // Give SwiftUI a brief opportunity to update focus state before
        // the next tab-bar interaction.
        _ = keyboard.waitForNonExistence(timeout: 2)
    }

    // MARK: - Launch Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
