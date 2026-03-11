import Foundation

struct BuildUpload: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes?
    let relationships: Relationships?

    struct Attributes: Decodable, Sendable {
        let cfBundleShortVersionString: String?
        let cfBundleVersion: String?
        let platform: String?
        let createdDate: String?
        let uploadedDate: String?
        let state: State?

        struct State: Decodable, Sendable {
            let errors: [Message]
            let warnings: [Message]
            let infos: [Message]
            let state: String

            private enum CodingKeys: String, CodingKey {
                case errors
                case warnings
                case infos
                case state
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.errors = try container.decodeIfPresent([Message].self, forKey: .errors) ?? []
                self.warnings = try container.decodeIfPresent([Message].self, forKey: .warnings) ?? []
                self.infos = try container.decodeIfPresent([Message].self, forKey: .infos) ?? []
                self.state = try container.decode(String.self, forKey: .state)
            }

            struct Message: Decodable, Sendable {
                let code: String?
                let detail: String?
                let title: String?
            }
        }
    }

    struct Relationships: Decodable, Sendable {
        let buildUploadFiles: RelatedLink?

        struct RelatedLink: Decodable, Sendable {
            let links: Links

            struct Links: Decodable, Sendable {
                let `self`: String?
                let related: String?
            }
        }
    }
}

struct CreateBuildUploadRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "buildUploads"
        let attributes: Attributes
        let relationships: Relationships

        struct Attributes: Encodable, Sendable {
            let cfBundleShortVersionString: String
            let cfBundleVersion: String
            let platform: String
        }

        struct Relationships: Encodable, Sendable {
            let app: RelationshipData
        }
    }
}

struct BuildUploadFile: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes?

    struct Attributes: Decodable, Sendable {
        let fileName: String?
        let fileSize: Int64?
        let assetType: String?
        let uti: String?
        let uploaded: Bool?
        let assetToken: String?
        let assetDeliveryState: AssetDeliveryState?
        let sourceFileChecksums: SourceFileChecksums?
        let uploadOperations: [UploadOperation]?

        struct AssetDeliveryState: Decodable, Sendable {
            let errors: [Message]
            let warnings: [Message]
            let state: String

            private enum CodingKeys: String, CodingKey {
                case errors
                case warnings
                case state
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.errors = try container.decodeIfPresent([Message].self, forKey: .errors) ?? []
                self.warnings = try container.decodeIfPresent([Message].self, forKey: .warnings) ?? []
                self.state = try container.decode(String.self, forKey: .state)
            }

            struct Message: Decodable, Sendable {
                let code: String?
                let detail: String?
                let title: String?
            }
        }

        struct SourceFileChecksums: Decodable, Sendable {
            let file: Checksum?
            let composite: Checksum?

            struct Checksum: Decodable, Sendable {
                let hash: String?
                let algorithm: String?
            }
        }

        struct UploadOperation: Decodable, Sendable {
            let method: String?
            let url: String?
            let offset: Int64?
            let length: Int64?
            let expiration: String?
            let partNumber: Int?
            let entityTag: String?
            let requestHeaders: [RequestHeader]?

            struct RequestHeader: Decodable, Sendable {
                let name: String
                let value: String
            }
        }
    }
}

struct CreateBuildUploadFileRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "buildUploadFiles"
        let attributes: Attributes
        let relationships: Relationships

        struct Attributes: Encodable, Sendable {
            let fileName: String
            let fileSize: Int64
            let assetType: String
            let uti: String
        }

        struct Relationships: Encodable, Sendable {
            let buildUpload: RelationshipData
        }
    }
}

struct UpdateBuildUploadFileRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "buildUploadFiles"
        let id: String
        let attributes: Attributes

        struct Attributes: Encodable, Sendable {
            let uploaded: Bool
        }
    }
}
