import XCTest

final class StillUITests: XCTestCase {
    func testLaunchAndNavigateTabs() {
        let app = XCUIApplication()
        app.launch()

        if waitForAnyStaticText(app, [
            "You're here. We can start anywhere.",
            "你在这里。我们可以从任何地方开始。"
        ], timeout: 2) {
            let closeButton = app.buttons["firstRunClose"]
            if closeButton.exists {
                closeButton.tap()
            }
        }

        XCTAssertTrue(app.staticTexts["homeTitle"].waitForExistence(timeout: 2))

        tapTabButton(in: app, candidates: ["Memory", "记忆", "square.stack"])
        XCTAssertTrue(app.staticTexts["memorySectionkept"].waitForExistence(timeout: 2))

        tapTabButton(in: app, candidates: ["Settings", "设置", "gearshape"])
        XCTAssertTrue(app.switches["settingsProactivityToggle"].waitForExistence(timeout: 2))
    }

    private func tapTabButton(in app: XCUIApplication, candidates: [String]) {
        for candidate in candidates {
            let button = app.tabBars.buttons[candidate]
            if button.exists {
                button.tap()
                return
            }
        }
        XCTFail("No tab button found for candidates: \(candidates)")
    }

    private func waitForAnyStaticText(_ app: XCUIApplication, _ labels: [String], timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for label in labels {
                if app.staticTexts[label].exists {
                    return true
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }
}
