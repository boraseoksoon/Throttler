import XCTest
@testable import Throttler

actor Recorder {
    private var recordedValues: [Int] = []

    func append(_ value: Int) {
        recordedValues.append(value)
    }

    func values() -> [Int] {
        recordedValues
    }

    func count() -> Int {
        recordedValues.count
    }
}

enum ThrottlerTestError: Error {
    case expected
}

actor ThrowingCounter {
    private var count = 0

    func next() throws -> Int {
        count += 1

        if count == 2 {
            throw ThrottlerTestError.expected
        }

        return count
    }

    func value() -> Int {
        count
    }
}

final class ThrottlerTests: XCTestCase {
    func testDebounceCoalescesRapidAsyncCalls() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        for value in 1...5 {
            let task = debounce(.milliseconds(20), identifier: identifier, by: .taskContext) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [5])
    }

    func testDebounceRunFirstDoesNotScheduleDuplicateTrailingCall() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        let task = debounce(.milliseconds(30), identifier: identifier, by: .taskContext, option: .runFirst) {
            await recorder.append(1)
        }
        await task.value

        try? await Task.sleep(for: .milliseconds(100))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testDebounceRunFirstSchedulesLatestTrailingCallDuringWindow() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        let firstTask = debounce(.milliseconds(40), identifier: identifier, by: .taskContext, option: .runFirst) {
            await recorder.append(1)
        }
        await firstTask.value

        try? await Task.sleep(for: .milliseconds(10))

        for value in 2...3 {
            let task = debounce(.milliseconds(40), identifier: identifier, by: .taskContext, option: .runFirst) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [1, 3])
    }

    func testDebounceDoesNotCancelAlreadyRunningOperation() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        let firstTask = debounce(.milliseconds(20), identifier: identifier, by: .taskContext) {
            do {
                try await Task.sleep(for: .milliseconds(80))
                await recorder.append(1)
            } catch {
                await recorder.append(-1)
            }
        }
        await firstTask.value

        try? await Task.sleep(for: .milliseconds(40))

        let secondTask = debounce(.milliseconds(20), identifier: identifier, by: .taskContext) {
            await recorder.append(2)
        }
        await secondTask.value

        try? await Task.sleep(for: .milliseconds(160))

        let values = await recorder.values()
        XCTAssertEqual(values, [2, 1])
    }

    func testDelayTaskCanBeCancelled() async {
        let recorder = Recorder()

        let task = delay(.milliseconds(60), by: .taskContext) {
            await recorder.append(1)
        }

        task.cancel()
        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [])
    }

    func testZeroDurationRunsImmediately() async {
        let recorder = Recorder()
        let debounceIdentifier = UUID().uuidString
        let throttleIdentifier = UUID().uuidString

        let debounceTask = debounce(.milliseconds(0), identifier: debounceIdentifier, by: .taskContext) {
            await recorder.append(1)
        }
        let throttleTask = throttle(.milliseconds(0), identifier: throttleIdentifier, by: .taskContext) {
            await recorder.append(2)
        }
        let delayTask = delay(.milliseconds(0), by: .taskContext) {
            await recorder.append(3)
        }

        await debounceTask.value
        await throttleTask.value
        await delayTask.value

        let values = await recorder.values()
        XCTAssertEqual(values.sorted(), [1, 2, 3])
    }

    func testExecuteTaskCanBeCancelled() async {
        let recorder = Recorder()

        let task = execute(with: .milliseconds(60), on: .taskContext) {
            await recorder.append(1)
        }

        task.cancel()
        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [])
    }

    func testAsyncThrowingOverloadCallsErrorHandler() async {
        enum TestError: Error {
            case expected
        }

        let expectation = expectation(description: "error handler called")

        let task = delay(.milliseconds(10), by: .taskContext, onError: { _ in
            expectation.fulfill()
        }) {
            throw TestError.expected
        }

        await task.value
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testOwnedActorSerializesLegacyOperations() async {
        final class Counter {
            var value = 0
        }

        let counter = Counter()

        for _ in 0..<500 {
            delay(.milliseconds(0), by: .ownedActor) {
                counter.value += 1
            }
        }

        try? await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(counter.value, 500)
    }

    func testMainActorRunsLegacyOperationOnMainThread() async {
        let expectation = expectation(description: "main actor operation")

        delay(.milliseconds(10), by: .mainActor) {
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testLegacyDelayStillExecutesOperation() async {
        let recorder = Recorder()

        delay(.milliseconds(20), by: .currentActor) {
            Task {
                await recorder.append(1)
            }
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testLegacyDebounceStillExecutesOperation() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        debounce(.milliseconds(20), identifier: identifier, by: .currentActor) {
            Task {
                await recorder.append(1)
            }
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testLegacyThrottleStillExecutesOperation() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        throttle(.milliseconds(20), identifier: identifier, by: .currentActor) {
            Task {
                await recorder.append(1)
            }
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testHighVolumeDebounceBurstCoalescesToLatestCall() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        for value in 0..<1_000 {
            let task = debounce(.milliseconds(20), identifier: identifier, by: .taskContext) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [999])
    }

    func testThrottleDefaultRunsFirstCallImmediatelyAndSuppressesBurst() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        for value in 1...5 {
            let task = throttle(.milliseconds(80), identifier: identifier, by: .taskContext) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(40))

        let immediateValues = await recorder.values()
        XCTAssertEqual(immediateValues.count, 1)

        try? await Task.sleep(for: .milliseconds(120))

        let finalValues = await recorder.values()
        XCTAssertEqual(finalValues.count, 1)
    }

    func testThrottleEnsureLastRunsLatestTrailingCall() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        let firstTask = throttle(.milliseconds(80), identifier: identifier, by: .taskContext, option: .ensureLast) {
            await recorder.append(1)
        }
        await firstTask.value

        try? await Task.sleep(for: .milliseconds(20))

        for value in 2...5 {
            let task = throttle(.milliseconds(80), identifier: identifier, by: .taskContext, option: .ensureLast) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(160))

        let values = await recorder.values()
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values.first, 1)
        XCTAssertEqual(values.last, 5)
    }

    func testHighVolumeThrottleEnsureLastKeepsLatestSuppressedCall() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        let firstTask = throttle(.milliseconds(100), identifier: identifier, by: .taskContext, option: .ensureLast) {
            await recorder.append(0)
        }
        await firstTask.value

        for value in 1...1_000 {
            let task = throttle(.milliseconds(100), identifier: identifier, by: .taskContext, option: .ensureLast) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(220))

        let values = await recorder.values()
        XCTAssertLessThanOrEqual(values.count, 3)
        XCTAssertEqual(values.first, 0)
        XCTAssertEqual(values.last, 1_000)
    }

    func testSleepAndExecuteHelpers() async {
        let recorder = Recorder()

        execute(with: .milliseconds(20), on: .ownedActor) {
            await recorder.append(1)
        }

        await sleep(.milliseconds(80))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testRepeatRunsRequestedNumberOfTimes() async {
        let recorder = Recorder()

        let task = `repeat`(every: .milliseconds(10), times: 3, by: .taskContext) {
            await recorder.append(1)
        }

        await task.value

        let count = await recorder.count()
        XCTAssertEqual(count, 3)
    }

    func testRepeatCanStartImmediately() async {
        let recorder = Recorder()

        let task = `repeat`(
            every: .seconds(1),
            times: 1,
            startingImmediately: true,
            by: .taskContext
        ) {
            await recorder.append(1)
        }

        await task.value

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testRepeatTaskCanBeCancelledBeforeFirstRun() async {
        let recorder = Recorder()

        let task = `repeat`(every: .milliseconds(100), by: .taskContext) {
            await recorder.append(1)
        }

        task.cancel()
        await task.value
        try? await Task.sleep(for: .milliseconds(140))

        let values = await recorder.values()
        XCTAssertEqual(values, [])
    }

    func testRepeatStopsAndCallsErrorHandlerWhenIterationThrows() async {
        let recorder = Recorder()
        let counter = ThrowingCounter()
        let expectation = expectation(description: "repeat error handler called")

        let task = `repeat`(
            every: .milliseconds(10),
            times: 5,
            startingImmediately: true,
            by: .taskContext,
            onError: { error in
                if error is ThrottlerTestError {
                    expectation.fulfill()
                }
            }
        ) {
            let value = try await counter.next()
            await recorder.append(value)
        }

        await task.value
        await fulfillment(of: [expectation], timeout: 1.0)

        let values = await recorder.values()
        let attempts = await counter.value()
        XCTAssertEqual(values, [1])
        XCTAssertEqual(attempts, 2)
    }

    func testTimeoutReturnsOperationValueBeforeDeadline() async throws {
        let value = try await timeout(.milliseconds(100)) {
            42
        }

        XCTAssertEqual(value, 42)
    }

    func testTimeoutThrowsWhenDeadlineWinsAndCancelsOperation() async {
        let recorder = Recorder()

        do {
            _ = try await timeout(.milliseconds(30)) {
                do {
                    try await Task.sleep(for: .milliseconds(200))
                    await recorder.append(1)
                    return 1
                } catch {
                    await recorder.append(-1)
                    throw error
                }
            }
            XCTFail("Expected timeout to throw")
        } catch TimeoutError.timedOut(let duration) {
            XCTAssertEqual(duration, .milliseconds(30))
        } catch {
            XCTFail("Expected TimeoutError, got \(error)")
        }

        let values = await recorder.values()
        XCTAssertEqual(values, [-1])
    }

    func testTimeoutPropagatesOperationErrorBeforeDeadline() async {
        do {
            _ = try await timeout(.milliseconds(100)) {
                throw ThrottlerTestError.expected
            }
            XCTFail("Expected operation error to throw")
        } catch ThrottlerTestError.expected {
        } catch {
            XCTFail("Expected operation error, got \(error)")
        }
    }
}
