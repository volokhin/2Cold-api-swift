// Delo © 2GIS

import Foundation

/// Логер, который ничего не логирует
class NullLogger: ILogger, ISingleton {

    required init() {}

    func info(
        _ message: String,
        metadata: [String: Any]? = nil,
        source: LogSource = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {
    }

    func warning(
        _ message: String,
        metadata: [String: Any]? = nil,
        source: LogSource = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {
    }

    func error(
        _ message: String,
        metadata: [String: Any]? = nil,
        source: LogSource = .other,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line) {
    }
}
