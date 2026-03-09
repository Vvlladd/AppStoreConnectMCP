import Foundation
import MCP

struct UploadBuildHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }
        guard case .string(let ipaPath) = args["ipa_path"] else {
            throw AppStoreConnectError.invalidArgument("ipa_path is required")
        }
        guard case .string(let versionString) = args["version_string"] else {
            throw AppStoreConnectError.invalidArgument("version_string is required")
        }
        guard case .string(let buildNumber) = args["build_number"] else {
            throw AppStoreConnectError.invalidArgument("build_number is required")
        }

        let platform = stringArg("platform", in: args) ?? "IOS"
        let assetType = stringArg("asset_type", in: args) ?? "ASSET"
        let uti = stringArg("uti", in: args) ?? "com.apple.ipa"

        let fileURL = URL(fileURLWithPath: ipaPath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AppStoreConnectError.invalidArgument("ipa_path does not exist: \(ipaPath)")
        }

        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard resourceValues.isRegularFile == true else {
            throw AppStoreConnectError.invalidArgument("ipa_path is not a file: \(ipaPath)")
        }
        guard let rawFileSize = resourceValues.fileSize else {
            throw AppStoreConnectError.invalidArgument("Could not determine file size for: \(ipaPath)")
        }

        let fileSize = Int64(rawFileSize)
        let fileName = fileURL.lastPathComponent

        let buildUpload = try await createBuildUpload(
            appID: appID,
            versionString: versionString,
            buildNumber: buildNumber,
            platform: platform
        )

        let buildUploadFile = try await createBuildUploadFile(
            buildUploadID: buildUpload.id,
            fileName: fileName,
            fileSize: fileSize,
            assetType: assetType,
            uti: uti
        )

        let uploadOperations = buildUploadFile.attributes?.uploadOperations ?? []
        if uploadOperations.isEmpty {
            throw AppStoreConnectError.apiError("Build upload file response did not include upload operations")
        }

        try await upload(fileURL: fileURL, fileSize: fileSize, using: uploadOperations)
        let committedBuildUploadFile = try await markBuildUploadFileUploaded(buildUploadFileID: buildUploadFile.id)

        let buildState = buildUpload.attributes?.state?.state ?? "created"
        let fileState = committedBuildUploadFile.attributes?.assetDeliveryState?.state ?? "uploaded"
        let output = """
        Uploaded \(fileName) (\(fileSize) bytes)
        Build upload: [\(buildUpload.id)] state=\(buildState)
        Build upload file: [\(buildUploadFile.id)] state=\(fileState) chunks=\(uploadOperations.count)
        Version: \(versionString) build \(buildNumber) on \(platform)
        """

        return CallTool.Result(content: [.text(output)])
    }

    private func createBuildUpload(
        appID: String,
        versionString: String,
        buildNumber: String,
        platform: String
    ) async throws -> BuildUpload {
        let body = CreateBuildUploadRequest(
            data: .init(
                attributes: .init(
                    cfBundleShortVersionString: versionString,
                    cfBundleVersion: buildNumber,
                    platform: platform
                ),
                relationships: .init(
                    app: .init(data: .init(type: "apps", id: appID))
                )
            )
        )

        let response = try await client.post(
            Endpoints.buildUploads(),
            body: body,
            as: APIResponse<BuildUpload>.self
        )
        return response.data
    }

    private func createBuildUploadFile(
        buildUploadID: String,
        fileName: String,
        fileSize: Int64,
        assetType: String,
        uti: String
    ) async throws -> BuildUploadFile {
        let body = CreateBuildUploadFileRequest(
            data: .init(
                attributes: .init(
                    fileName: fileName,
                    fileSize: fileSize,
                    assetType: assetType,
                    uti: uti
                ),
                relationships: .init(
                    buildUpload: .init(data: .init(type: "buildUploads", id: buildUploadID))
                )
            )
        )

        let response = try await client.post(
            Endpoints.buildUploadFiles(),
            body: body,
            as: APIResponse<BuildUploadFile>.self
        )
        return response.data
    }

    private func upload(
        fileURL: URL,
        fileSize: Int64,
        using operations: [BuildUploadFile.Attributes.UploadOperation]
    ) async throws {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? fileHandle.close()
        }

        for operation in operations {
            guard let urlString = operation.url, let url = URL(string: urlString) else {
                throw AppStoreConnectError.apiError("Invalid upload operation URL")
            }
            guard let method = operation.method else {
                throw AppStoreConnectError.apiError("Upload operation missing HTTP method")
            }
            guard let offset = operation.offset, let length = operation.length else {
                throw AppStoreConnectError.apiError("Upload operation missing byte range")
            }

            let end = offset + length
            guard offset >= 0, length >= 0, end <= fileSize else {
                throw AppStoreConnectError.apiError("Upload operation range is outside the IPA size")
            }
            guard let readLength = Int(exactly: length) else {
                throw AppStoreConnectError.apiError("Upload operation length exceeds supported size")
            }

            try fileHandle.seek(toOffset: UInt64(offset))
            guard let chunk = try fileHandle.read(upToCount: readLength), chunk.count == readLength else {
                throw AppStoreConnectError.apiError("Failed to read upload chunk from IPA")
            }
            let headers = Dictionary(
                uniqueKeysWithValues: (operation.requestHeaders ?? []).map { ($0.name, $0.value) }
            )

            try await client.upload(url, method: method, headers: headers, body: chunk)
        }
    }

    private func markBuildUploadFileUploaded(buildUploadFileID: String) async throws -> BuildUploadFile {
        let body = UpdateBuildUploadFileRequest(
            data: .init(
                id: buildUploadFileID,
                attributes: .init(uploaded: true)
            )
        )

        let response = try await client.patch(
            Endpoints.buildUploadFile(id: buildUploadFileID),
            body: body,
            as: APIResponse<BuildUploadFile>.self
        )
        return response.data
    }

    private func stringArg(_ key: String, in args: [String: Value]) -> String? {
        if case .string(let value) = args[key] {
            return value
        }
        return nil
    }
}
