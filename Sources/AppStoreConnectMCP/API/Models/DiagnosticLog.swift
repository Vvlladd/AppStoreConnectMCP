import Foundation

// The /v1/diagnosticSignatures/{id}/logs endpoint returns custom JSON, not JSON:API.
// Structure: { productData: [{ signatureId, diagnosticLogs: [{ diagnosticMetaData, callStackTree }] }] }

struct DiagnosticLogsResponse: Decodable, Sendable {
    let productData: [ProductData]?

    struct ProductData: Decodable, Sendable {
        let signatureId: String?
        let diagnosticLogs: [DiagnosticLogEntry]?
    }
}

struct DiagnosticLogEntry: Decodable, Sendable {
    let diagnosticMetaData: DiagnosticMetadata?
    let callStackTree: [CallStackTree]?
}

struct DiagnosticMetadata: Decodable, Sendable {
    let appVersion: String?
    let buildVersion: String?
    let bundleId: String?
    let deviceType: String?
    let osVersion: String?
    let platformArchitecture: String?
    let event: String?
    let eventDetail: String?
    let writesCaused: String?
}

struct CallStackTree: Decodable, Sendable {
    let callStackRootFrames: [DiagnosticLogCallStackNode]?
    let callStackPerThread: Bool?
}

struct DiagnosticLogCallStackNode: Decodable, Sendable {
    let symbolName: String?
    let fileName: String?
    let lineNumber: Int?
    let binaryName: String?
    let binaryUUID: String?
    let address: Int?
    let sampleCount: Int?
    let isBlameFrame: Bool?
    let subFrames: [DiagnosticLogCallStackNode]?
}
