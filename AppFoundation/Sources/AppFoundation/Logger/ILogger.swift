// Delo © 2GIS

import Foundation

/// Логер :)
public protocol ILogger {
    func info(
        _ message: String,
        metadata: [String: Any]?,
        source: LogSource,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
    func warning(
        _ message: String,
        metadata: [String: Any]?,
        source: LogSource,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
    func error(
        _ message: String,
        metadata: [String: Any]?,
        source: LogSource,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}

// MARK: - LogSource

public enum LogSource: String, CaseIterable {
    case network
    case analytics
    case other
}

// MARK: - ILogger Extensions

public extension ILogger {

    func info(
        _ message: String,
        metadata: [String: Any]? = nil,
        source: LogSource = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {

        info(message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        metadata: [String: Any]? = nil,
        source: LogSource = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {

        warning(message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        metadata: [String: Any]? = nil,
        source: LogSource = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {

        error(message, metadata: metadata, source: source, file: file, function: function, line: line)
    }

    func network(
        _ message: String,
        metadata: [String: Any]? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {

        info(message, metadata: metadata, source: .network, file: file, function: function, line: line)
    }

    func analytics(
        _ message: String,
        metadata: [String: Any]? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {

        info(message, metadata: metadata, source: .analytics, file: file, function: function, line: line)
    }
}
