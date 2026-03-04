import Foundation

enum AppStoreConnectError: Error, LocalizedError {
    case configuration(String)
    case privateKey(String)
    case jwt(String)
    case httpError(statusCode: Int, body: String)
    case apiError(String)
    case decoding(String)
    case invalidArgument(String)

    var errorDescription: String? {
        switch self {
        case .configuration(let msg): return "Configuration error: \(msg)"
        case .privateKey(let msg): return "Private key error: \(msg)"
        case .jwt(let msg): return "JWT error: \(msg)"
        case .httpError(let code, let body): return "HTTP \(code): \(body)"
        case .apiError(let msg): return "API error: \(msg)"
        case .decoding(let msg): return "Decoding error: \(msg)"
        case .invalidArgument(let msg): return "Invalid argument: \(msg)"
        }
    }
}
