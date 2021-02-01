import XCTest
@testable import ProcoCalendar

final class ProcoCalendarTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ProcoCalendar().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
