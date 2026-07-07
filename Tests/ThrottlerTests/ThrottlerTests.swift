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

final class ReportRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedReports: [String] = []

    func append(_ report: String) {
        lock.lock()
        defer { lock.unlock() }
        recordedReports.append(report)
    }

    func reports() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return recordedReports
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

actor RetryCounter {
    private var attempts = 0

    func succeed(on successAttempt: Int) throws -> Int {
        attempts += 1

        if attempts < successAttempt {
            throw ThrottlerTestError.expected
        }

        return attempts
    }

    func alwaysFail() throws -> Int {
        attempts += 1
        throw ThrottlerTestError.expected
    }

    func cancel() throws -> Int {
        attempts += 1
        throw CancellationError()
    }

    func value() -> Int {
        attempts
    }
}

actor OverlapRecorder {
    private var running = 0
    private var maximumRunning = 0

    func start() {
        running += 1
        maximumRunning = max(maximumRunning, running)
    }

    func finish() {
        running -= 1
    }

    func maximum() -> Int {
        maximumRunning
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

    func testOwnedActorSerializesSynchronousOperations() async {
        final class Counter: @unchecked Sendable {
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

    func testMainActorRunsSynchronousOperationOnMainThread() async {
        let expectation = expectation(description: "main actor operation")

        delay(.milliseconds(10), by: .mainActor) {
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testSynchronousDelayStillExecutesOperation() async {
        let recorder = Recorder()

        delay(.milliseconds(20), by: .taskContext) {
            Task {
                await recorder.append(1)
            }
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testSynchronousDebounceStillExecutesOperation() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        debounce(.milliseconds(20), identifier: identifier, by: .taskContext) {
            Task {
                await recorder.append(1)
            }
        }

        try? await Task.sleep(for: .milliseconds(120))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testSynchronousThrottleStillExecutesOperation() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        throttle(.milliseconds(20), identifier: identifier, by: .taskContext) {
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

    func testRepeatDoesNotRunForNonPositiveIntervalOrLimit() async {
        let recorder = Recorder()

        let zeroIntervalTask = `repeat`(every: .milliseconds(0), times: 1, by: .taskContext) {
            await recorder.append(1)
        }

        let zeroLimitTask = `repeat`(every: .milliseconds(10), times: 0, by: .taskContext) {
            await recorder.append(2)
        }

        await zeroIntervalTask.value
        await zeroLimitTask.value

        let values = await recorder.values()
        XCTAssertEqual(values, [])
    }

    func testRepeatIterationsDoNotOverlap() async {
        let recorder = OverlapRecorder()

        let task = `repeat`(
            every: .milliseconds(1),
            times: 3,
            startingImmediately: true,
            by: .taskContext
        ) {
            await recorder.start()
            try await Task.sleep(for: .milliseconds(20))
            await recorder.finish()
        }

        await task.value

        let maximum = await recorder.maximum()
        XCTAssertEqual(maximum, 1)
    }

    func testRepeatCancellationErrorDoesNotCallErrorHandler() async {
        let recorder = Recorder()

        let task = `repeat`(
            every: .milliseconds(10),
            times: 2,
            startingImmediately: true,
            by: .taskContext,
            onError: { _ in
                Task {
                    await recorder.append(1)
                }
            }
        ) {
            throw CancellationError()
        }

        await task.value
        try? await Task.sleep(for: .milliseconds(50))

        let values = await recorder.values()
        XCTAssertEqual(values, [])
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

    func testTimeoutNonPositiveDurationThrowsImmediatelyWithoutRunningOperation() async {
        let recorder = Recorder()

        do {
            _ = try await timeout(.milliseconds(0)) {
                await recorder.append(1)
                return 1
            }
            XCTFail("Expected timeout to throw")
        } catch TimeoutError.timedOut(let duration) {
            XCTAssertEqual(duration, .milliseconds(0))
        } catch {
            XCTFail("Expected TimeoutError, got \(error)")
        }

        let values = await recorder.values()
        XCTAssertEqual(values, [])
    }

    func testTimeSyncReturnsValueAndReportsCompactSuccess() {
        let recorder = ReportRecorder()

        let value = time("sync work", report: { recorder.append($0) }) {
            7
        }

        let reports = recorder.reports()
        XCTAssertEqual(value, 7)
        XCTAssertEqual(reports.count, 1)
        XCTAssertTrue(reports[0].hasPrefix("[Throttler] sync work completed in "))
    }

    func testTimeSyncReportsFailureAndRethrowsOriginalError() {
        let recorder = ReportRecorder()

        do {
            _ = try time("sync failure", report: { recorder.append($0) }) {
                throw ThrottlerTestError.expected
            }
            XCTFail("Expected operation error to throw")
        } catch ThrottlerTestError.expected {
        } catch {
            XCTFail("Expected original operation error, got \(error)")
        }

        let reports = recorder.reports()
        XCTAssertEqual(reports.count, 1)
        XCTAssertTrue(reports[0].hasPrefix("[Throttler] sync failure failed in "))
        XCTAssertTrue(reports[0].contains("expected"))
    }

    func testTimeAsyncVoidReportsVerboseSuccess() async {
        let recorder = Recorder()
        let reportRecorder = ReportRecorder()

        await time("async void", style: .verbose, report: { reportRecorder.append($0) }) {
            await recorder.append(1)
        }

        let values = await recorder.values()
        let reports = reportRecorder.reports()
        XCTAssertEqual(values, [1])
        XCTAssertEqual(reports.count, 1)
        XCTAssertTrue(reports[0].hasPrefix("[Throttler] label=\"async void\" result=success duration=\""))
    }

    func testTimeAsyncReportsFailureAndRethrowsOriginalError() async {
        let recorder = ReportRecorder()

        do {
            _ = try await time("async failure", report: { recorder.append($0) }) {
                await Task.yield()
                throw ThrottlerTestError.expected
            }
            XCTFail("Expected operation error to throw")
        } catch ThrottlerTestError.expected {
        } catch {
            XCTFail("Expected original operation error, got \(error)")
        }

        let reports = recorder.reports()
        XCTAssertEqual(reports.count, 1)
        XCTAssertTrue(reports[0].hasPrefix("[Throttler] async failure failed in "))
        XCTAssertTrue(reports[0].contains("expected"))
    }

    func testRetryReturnsFirstSuccess() async throws {
        let counter = RetryCounter()

        let value = try await retry(3, every: .milliseconds(5)) {
            try await counter.succeed(on: 3)
        }

        let attempts = await counter.value()
        XCTAssertEqual(value, 3)
        XCTAssertEqual(attempts, 3)
    }

    func testRetryThrowsLastErrorAfterMaxAttempts() async {
        let counter = RetryCounter()

        do {
            _ = try await retry(3, every: .milliseconds(0)) {
                try await counter.alwaysFail()
            }
            XCTFail("Expected retry to throw")
        } catch ThrottlerTestError.expected {
        } catch {
            XCTFail("Expected last operation error, got \(error)")
        }

        let attempts = await counter.value()
        XCTAssertEqual(attempts, 3)
    }

    func testRetryRejectsInvalidAttemptCount() async {
        do {
            _ = try await retry(0, every: .milliseconds(1)) {
                1
            }
            XCTFail("Expected invalid attempt count")
        } catch RetryError.invalidAttemptCount(let count) {
            XCTAssertEqual(count, 0)
        } catch {
            XCTFail("Expected RetryError, got \(error)")
        }
    }

    func testRetryDoesNotRetryCancellation() async {
        let counter = RetryCounter()

        do {
            _ = try await retry(3, every: .milliseconds(1)) {
                try await counter.cancel()
            }
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }

        let attempts = await counter.value()
        XCTAssertEqual(attempts, 1)
    }

    func testRetryWaitsBetweenFailedAttempts() async throws {
        let counter = RetryCounter()
        let clock = ContinuousClock()
        let start = clock.now

        let value = try await retry(2, every: .milliseconds(25)) {
            try await counter.succeed(on: 2)
        }

        let elapsed = clock.now - start
        XCTAssertEqual(value, 2)
        XCTAssertGreaterThanOrEqual(elapsed, .milliseconds(20))
    }

    func testRetryNonPositiveDelayRetriesImmediately() async throws {
        let counter = RetryCounter()

        let value = try await retry(2, every: .milliseconds(0)) {
            try await counter.succeed(on: 2)
        }

        let attempts = await counter.value()
        XCTAssertEqual(value, 2)
        XCTAssertEqual(attempts, 2)
    }

    func testRetryStopsWhenParentTaskIsCancelledDuringDelay() async {
        let counter = RetryCounter()
        let task = Task {
            try await retry(2, every: .seconds(1)) {
                try await counter.alwaysFail()
            }
        }

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }

        let attempts = await counter.value()
        XCTAssertEqual(attempts, 1)
    }

    func testDebounceDefaultIdentifierCoalescesCallsFromSameCallSite() async {
        let recorder = Recorder()

        for value in 1...5 {
            debounce(.milliseconds(100)) {
                Task {
                    await recorder.append(value)
                }
            }
        }

        try? await Task.sleep(for: .milliseconds(400))

        let count = await recorder.count()
        XCTAssertEqual(count, 1)
    }

    func testAsyncDebounceDefaultIdentifierCoalescesCallsFromSameCallSite() async {
        let recorder = Recorder()

        for value in 1...5 {
            let task = debounce(.milliseconds(100), by: .taskContext) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(400))

        let values = await recorder.values()
        XCTAssertEqual(values, [5])
    }

    func testDebounceDefaultIdentifierSeparatesDifferentCallSites() async {
        let recorder = Recorder()

        debounce(.milliseconds(50)) {
            Task {
                await recorder.append(1)
            }
        }
        debounce(.milliseconds(50)) {
            Task {
                await recorder.append(2)
            }
        }

        try? await Task.sleep(for: .milliseconds(300))

        let values = await recorder.values()
        XCTAssertEqual(values.sorted(), [1, 2])
    }

    func testThrottleDefaultIdentifierThrottlesBurstFromSameCallSite() async {
        let recorder = Recorder()

        for value in 1...5 {
            throttle(.milliseconds(100)) {
                Task {
                    await recorder.append(value)
                }
            }
        }

        try? await Task.sleep(for: .milliseconds(300))

        let count = await recorder.count()
        XCTAssertEqual(count, 1)
    }

    func testAsyncThrottleDefaultIdentifierThrottlesBurstFromSameCallSite() async {
        let recorder = Recorder()

        for value in 1...5 {
            let task = throttle(.milliseconds(100), by: .taskContext) {
                await recorder.append(value)
            }
            await task.value
        }

        try? await Task.sleep(for: .milliseconds(300))

        let values = await recorder.values()
        XCTAssertEqual(values, [1])
    }

    func testDebounceAndThrottleStateAreIndependentForSameIdentifier() async {
        let recorder = Recorder()
        let identifier = UUID().uuidString

        let throttleTask = throttle(.milliseconds(80), identifier: identifier, by: .taskContext) {
            await recorder.append(1)
        }
        await throttleTask.value

        let debounceTask = debounce(.milliseconds(80), identifier: identifier, by: .taskContext, option: .runFirst) {
            await recorder.append(2)
        }
        await debounceTask.value

        let immediateValues = await recorder.values()
        XCTAssertEqual(immediateValues, [1, 2])

        try? await Task.sleep(for: .milliseconds(200))

        let finalValues = await recorder.values()
        XCTAssertEqual(finalValues, [1, 2])
    }
}
