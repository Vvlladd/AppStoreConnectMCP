import Foundation
import Logging

struct StderrLogHandler: LogHandler {
    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .info

    private let label: String

    init(label: String) {
        self.label = label
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let timestamp = Self.formatTimestamp()
        let merged = self.metadata.merging(metadata ?? [:]) { _, new in new }
        let kvPairs = merged.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        let kvSuffix = kvPairs.isEmpty ? "" : " \(kvPairs)"

        let output = "[\(timestamp)] [\(level)] [\(label)] \(message)\(kvSuffix)\n"

        FileHandle.standardError.write(Data(output.utf8))
    }

    private static func formatTimestamp() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: now
        )
        return String(
            format: "%04d-%02d-%02d %02d:%02d:%02d",
            components.year!, components.month!, components.day!,
            components.hour!, components.minute!, components.second!
        )
    }
}
