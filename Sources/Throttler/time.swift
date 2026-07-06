//
//  time.swift
//  Throttler
//
//  Created by seoksoon jang on 2026-07-06.
//

import Foundation

/// Controls the format used by `time` when reporting elapsed duration.
public enum TimeReportStyle: Sendable {
    /// Human-readable sentence format.
    case compact
    /// Stable key-value format that is easier to scan or parse.
    case verbose
}

/**
 Measures a synchronous operation, reports elapsed time, and returns the operation result unchanged.

 - Parameters:
   - label: An optional name included in the report.
   - style: The report format. `.compact` is the default human-readable format. `.verbose` includes stable key-value fields.
   - report: Receives the formatted report string. Defaults to printing the report.
   - operation: The synchronous throwing operation to measure.

 - Returns: The operation result.
 - Throws: The original operation error.

 - Behavior:
   - Uses `ContinuousClock`, not wall-clock time.
   - Reports elapsed time after success and after failure.
   - Does not change actor context, return value, or thrown error.
 */
@discardableResult
public func time<Value>(
    _ label: String? = nil,
    style: TimeReportStyle = .compact,
    report: (String) -> Void = { print($0) },
    operation: () throws -> Value
) rethrows -> Value {
    let clock = ContinuousClock()
    let start = clock.now

    do {
        let value = try operation()
        report(timeReport(label: label, duration: clock.now - start, style: style, error: nil))
        return value
    } catch {
        report(timeReport(label: label, duration: clock.now - start, style: style, error: error))
        throw error
    }
}

/**
 Measures an async operation, reports elapsed time, and returns the operation result unchanged.

 - Parameters:
   - label: An optional name included in the report.
   - style: The report format. `.compact` is the default human-readable format. `.verbose` includes stable key-value fields.
   - report: Receives the formatted report string. Defaults to printing the report.
   - operation: The async throwing operation to measure.

 - Returns: The operation result.
 - Throws: The original operation error.

 - Behavior:
   - Uses `ContinuousClock`, not wall-clock time.
   - Reports elapsed time after success, failure, or cancellation thrown by the operation.
   - Does not change actor context, return value, or thrown error.
 */
@discardableResult
public func time<Value>(
    _ label: String? = nil,
    style: TimeReportStyle = .compact,
    report: @Sendable (String) -> Void = { print($0) },
    operation: @Sendable () async throws -> Value
) async rethrows -> Value {
    let clock = ContinuousClock()
    let start = clock.now

    do {
        let value = try await operation()
        report(timeReport(label: label, duration: clock.now - start, style: style, error: nil))
        return value
    } catch {
        report(timeReport(label: label, duration: clock.now - start, style: style, error: error))
        throw error
    }
}

private func timeReport(
    label: String?,
    duration: Duration,
    style: TimeReportStyle,
    error: Error?
) -> String {
    switch style {
    case .compact:
        return compactTimeReport(label: label, duration: duration, error: error)
    case .verbose:
        return verboseTimeReport(label: label, duration: duration, error: error)
    }
}

private func compactTimeReport(label: String?, duration: Duration, error: Error?) -> String {
    let prefix = label.map { "[Throttler] \($0)" } ?? "[Throttler]"
    let elapsed = formattedDuration(duration)

    if let error {
        return "\(prefix) failed in \(elapsed): \(error)"
    }

    return "\(prefix) completed in \(elapsed)"
}

private func verboseTimeReport(label: String?, duration: Duration, error: Error?) -> String {
    let labelField = label.map { " label=\"\($0)\"" } ?? ""
    let elapsed = formattedDuration(duration)

    if let error {
        return "[Throttler]\(labelField) result=failure duration=\"\(elapsed)\" error=\"\(error)\""
    }

    return "[Throttler]\(labelField) result=success duration=\"\(elapsed)\""
}

private func formattedDuration(_ duration: Duration) -> String {
    let components = duration.components
    let seconds = Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    let milliseconds = seconds * 1_000

    if milliseconds < 1 {
        return String(format: "%.3f ms", milliseconds)
    }

    if milliseconds < 1_000 {
        return String(format: "%.1f ms", milliseconds)
    }

    return String(format: "%.3f s", seconds)
}
