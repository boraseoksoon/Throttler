import XCTest
@testable import Throttler

final class ThrottlerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Throttler().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
