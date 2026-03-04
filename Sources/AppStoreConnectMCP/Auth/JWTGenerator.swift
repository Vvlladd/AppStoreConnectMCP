import Foundation
import CryptoKit

actor JWTGenerator {
    private static let tokenLifetime: TimeInterval = 20 * 60

    private let authMode: AuthMode
    private let keyID: String
    private let issuerID: String?
    private let privateKey: P256.Signing.PrivateKey

    private var cachedToken: String?
    private var tokenExpiry: Date?

    init(configuration: Configuration) throws {
        self.authMode = configuration.authMode
        self.keyID = configuration.keyID
        self.issuerID = configuration.issuerID

        let keyData = try Self.loadPrivateKey(at: configuration.privateKeyPath)
        self.privateKey = try P256.Signing.PrivateKey(derRepresentation: keyData)
    }

    func token() throws -> String {
        if let cached = cachedToken, let expiry = tokenExpiry, Date() < expiry.addingTimeInterval(-60) {
            return cached
        }
        let newToken = try generateToken()
        cachedToken = newToken
        tokenExpiry = Date().addingTimeInterval(Self.tokenLifetime)
        return newToken
    }

    func forceRefresh() throws -> String {
        cachedToken = nil
        tokenExpiry = nil
        return try token()
    }

    private func generateToken() throws -> String {
        let header = #"{"alg":"ES256","kid":"\#(keyID)","typ":"JWT"}"#

        let now = Int(Date().timeIntervalSince1970)
        let exp = now + Int(Self.tokenLifetime)
        let claims: String
        switch authMode {
        case .team:
            guard let issuerID else {
                throw AppStoreConnectError.jwt("Missing issuer for team auth mode")
            }
            claims = #"{"iss":"\#(issuerID)","iat":\#(now),"exp":\#(exp),"aud":"appstoreconnect-v1"}"#
        case .individual:
            claims = #"{"sub":"user","iat":\#(now),"exp":\#(exp),"aud":"appstoreconnect-v1"}"#
        }

        let headerEncoded = Self.base64URLEncode(Data(header.utf8))
        let claimsEncoded = Self.base64URLEncode(Data(claims.utf8))
        let signingInput = "\(headerEncoded).\(claimsEncoded)"

        let signature = try privateKey.signature(for: Data(signingInput.utf8))
        let signatureEncoded = Self.base64URLEncode(signature.rawRepresentation)

        return "\(signingInput).\(signatureEncoded)"
    }

    private static func loadPrivateKey(at path: String) throws -> Data {
        let content: String
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw AppStoreConnectError.privateKey("Cannot read key file at \(path): \(error.localizedDescription)")
        }

        let stripped = content
            .split(separator: "\n")
            .filter { !$0.hasPrefix("-----") }
            .joined()
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let data = Data(base64Encoded: stripped) else {
            throw AppStoreConnectError.privateKey("Failed to base64-decode private key")
        }
        return data
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
