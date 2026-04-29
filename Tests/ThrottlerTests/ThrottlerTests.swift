import XCTest
@testable import Throttler

actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }

    func currentValue() -> Int {
        value
    }
}

final class ThrottlerTests: XCTestCase {
    func testDelayExecutesOperation() async {
        let counter = Counter()

        delay(.milliseconds(20), by: .mainActor) {
            Task {
                await counter.increment()
            }
        }

        try? await Task.sleep(for: .milliseconds(120))
        let count = await counter.currentValue()
        XCTAssertEqual(count, 1)
    }

    func testDebounceCoalescesRapidCalls() async {
        let counter = Counter()
        let identifier = "debounce-test"

        for _ in 0..<5 {
            debounce(.milliseconds(40), identifier: identifier, by: .mainActor) {
                Task {
                    await counter.increment()
                }
            }
        }

        try? await Task.sleep(for: .milliseconds(180))
        let count = await counter.currentValue()
        XCTAssertEqual(count, 1)
    }

    func testThrottleEnsureLastExecutesAtLeastOnceForBurst() async {
        let counter = Counter()
        let identifier = "throttle-ensure-last-test"

        for _ in 0..<5 {
            throttle(.milliseconds(40), identifier: identifier, by: .mainActor, option: .ensureLast) {
                Task {
                    await counter.increment()
                }
            }
        }

        try? await Task.sleep(for: .milliseconds(250))
        let count = await counter.currentValue()
        XCTAssertGreaterThanOrEqual(count, 1)
    }
}
