/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let mozDeveloperWebsite = "https://developer.mozilla.org/en-US"
let searchFieldPlaceholder = "Search MDN"
class ThirdPartySearchTest: BaseTestCase {
    fileprivate func dismissKeyboardAssistant(forApp app: XCUIApplication) {
        app.buttons["Done"].tap()
    }

    func testCustomSearchEngines() {
        // Visit MDN to add a custom search engine
        loadWebPage(mozDeveloperWebsite, waitForLoadToFinish: true)
        addSearchProvider()

        if !isTablet {
            dismissKeyboardAssistant(forApp: app)
        }

        // Perform a search using a custom search engine
        tabTrayButton(forApp: app).tap()
        app.buttons["TabTrayController.addTabButton"].tap()
        waitForExistence(app.textFields["url"], timeout: 3)
        app.textFields["url"].tap()
        waitForExistence(app.buttons["urlBar-cancel"])
        app.typeText("window")
        app.scrollViews.otherElements.buttons["developer.mozilla.org search"].tap()

        var url = app.textFields["url"].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineAsDefault() {
        // Visit MDN to add a custom search engine
        loadWebPage(mozDeveloperWebsite, waitForLoadToFinish: true)
        addSearchProvider()

        if !isTablet {
            dismissKeyboardAssistant(forApp: app)
        }

        // Go to settings and set MDN as the default
        navigator.goto(SearchSettings)
        app.tables.cells.element(boundBy: 0).tap()
        app.tables.staticTexts["developer.mozilla.org"].tap()
        navigator.goto(BrowserTab)

        // Perform a search to check
        navigator.openNewURL(urlString:"window")

        // Ensure that the default search is MDN
        var url = app.textFields["url"].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US/search"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineDeletion() {
        // Visit MDN to add a custom search engine
        loadWebPage(mozDeveloperWebsite, waitForLoadToFinish: true)
        addSearchProvider()

        if !isTablet {
            dismissKeyboardAssistant(forApp: app)
        }

        let tabTrayButton = self.tabTrayButton(forApp: app)
        tabTrayButton.tap()
        app.buttons["TabTrayController.addTabButton"].tap()
        waitForExistence(app.textFields["url"], timeout: 3)
        app.textFields["url"].tap()
        waitForExistence(app.buttons["urlBar-cancel"])
        app.typeText("window")

        // For timing issue, we need a wait statement
        waitForExistence(app.scrollViews.otherElements.buttons["developer.mozilla.org search"])
        XCTAssert(app.scrollViews.otherElements.buttons["developer.mozilla.org search"].exists)
        app.typeText("\r")

        // Go to settings and set MDN as the default
        waitUntilPageLoad()
        navigator.goto(SearchSettings)

        app.navigationBars["Search"].buttons["Edit"].tap()
        app.tables.buttons["Delete developer.mozilla.org"].tap()
        app.tables.buttons["Delete"].tap()

        navigator.goto(BrowserTab)

        // Perform a search to check
        tabTrayButton.tap(force: true)
        app.buttons["TabTrayController.addTabButton"].tap()
        waitForExistence(app.textFields["url"], timeout: 3)
        app.textFields["url"].tap()
        waitForExistence(app.buttons["urlBar-cancel"])
        app.typeText("window")
        waitForNoExistence(app.scrollViews.otherElements.buttons["developer.mozilla.org search"])
        XCTAssertFalse(app.scrollViews.otherElements.buttons["developer.mozilla.org search"].exists)
    }

    private func addSearchProvider() {
        // Tap on the search field
        app.webViews.searchFields.element(boundBy: 0).tap()
        // Workaround due to issue #5442
        if isTablet {
            app.buttons["Reload"].tap()
            waitUntilPageLoad()
            app.webViews.searchFields.element(boundBy: 0).tap()
        }
        app.buttons["AddSearch"].tap()
        app.alerts["Add Search Provider?"].buttons["OK"].tap()
        XCTAssertFalse(app.buttons["AddSearch"].isEnabled)
    }

    func testCustomEngineFromCorrectTemplate() {
        navigator.goto(SearchSettings)
        app.tables.cells["customEngineViewButton"].tap()

        app.textViews["customEngineTitle"].tap()
        app.typeText("Ask")
        app.textViews["customEngineUrl"].tap()
        app.typeText("http://www.ask.com/web?q=%s")
        app.navigationBars.buttons["customEngineSaveButton"].tap()

        // Perform a search using a custom search engine
        waitForExistence(app.tables.staticTexts["Ask"])
        navigator.goto(HomePanelsScreen)
        app.textFields["url"].tap()
        app.typeText("strange charm")
        app.scrollViews.otherElements.buttons["Ask search"].tap()

        // Ensure that correct search is done
        let url = app.textFields["url"].value as! String
        XCTAssert(url.hasPrefix("www.ask.com"), "The URL should indicate that the search was performed using ask")
    }

    func testCustomEngineFromIncorrectTemplate() {
        navigator.goto(SearchSettings)
        app.tables.cells["customEngineViewButton"].tap()
        app.textViews["customEngineTitle"].tap()
        app.typeText("Feeling Lucky")
        app.textViews["customEngineUrl"].tap()
        app.typeText("http://www.google.com/search?q=&btnI") //Occurunces of %s != 1

        app.navigationBars.buttons["customEngineSaveButton"].tap()

        waitForExistence(app.alerts.element(boundBy: 0))
        XCTAssert(app.alerts.element(boundBy: 0).label == "Failed")
    }
}
