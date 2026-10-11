import Foundation
import MCP

enum MetadataArguments {
    static func requiredID(_ key: String, in params: CallTool.Parameters) throws -> String {
        guard let value = params.arguments?[key]?.stringValue, !value.isEmpty,
              value.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" }) else {
            throw AppStoreConnectError.invalidArgument("\(key) must be a non-empty resource ID")
        }
        return value
    }

    static func locale(in params: CallTool.Parameters) throws -> String? {
        guard let value = params.arguments?["locale"] else { return nil }
        guard let locale = value.stringValue,
              !locale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppStoreConnectError.invalidArgument("locale must be a non-empty string")
        }
        return locale
    }

    static func optionalString(_ key: String, in params: CallTool.Parameters) throws -> String? {
        guard let value = params.arguments?[key] else { return nil }
        guard let string = value.stringValue else {
            throw AppStoreConnectError.invalidArgument("\(key) must be a string")
        }
        return string
    }
}
