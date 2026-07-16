import Foundation

struct PhasedReleaseManager: Sendable {
    let client: AppStoreConnectClient

    func setEnabled(_ enabled: Bool, forVersionID versionID: String) async throws -> Result {
        let existing = try await currentPhasedRelease(forVersionID: versionID)

        if enabled {
            return try await enable(existing: existing, versionID: versionID)
        }

        return try await disable(existing: existing)
    }

    func currentPhasedRelease(forVersionID versionID: String) async throws -> AppStoreVersionPhasedRelease? {
        let relationship = try await client.get(
            Endpoints.appStoreVersionPhasedReleaseRelationship(versionID: versionID),
            as: OptionalResourceIdentifierResponse.self
        )
        guard let phasedReleaseID = relationship.data?.id else { return nil }

        let response = try await client.get(
            Endpoints.appStoreVersionPhasedRelease(id: phasedReleaseID),
            as: APIResponse<AppStoreVersionPhasedRelease>.self
        )
        return response.data
    }

    private func enable(
        existing: AppStoreVersionPhasedRelease?,
        versionID: String
    ) async throws -> Result {
        if let existing {
            guard existing.attributes.phasedReleaseState != .complete else {
                throw AppStoreConnectError.invalidArgument(
                    "Phased release cannot be enabled because rollout for this version is already complete"
                )
            }
            return Result(
                mode: .phased,
                state: existing.attributes.phasedReleaseState,
                changed: false
            )
        }

        let body = CreatePhasedReleaseRequest(
            data: .init(
                attributes: .init(phasedReleaseState: .inactive),
                relationships: .init(
                    appStoreVersion: .init(
                        data: .init(type: "appStoreVersions", id: versionID)
                    )
                )
            )
        )
        let response = try await client.post(
            Endpoints.appStoreVersionPhasedReleases(),
            body: body,
            as: APIResponse<AppStoreVersionPhasedRelease>.self
        )
        return Result(
            mode: .phased,
            state: response.data.attributes.phasedReleaseState ?? .inactive,
            changed: true
        )
    }

    private func disable(existing: AppStoreVersionPhasedRelease?) async throws -> Result {
        guard let existing else {
            return Result(mode: .instant, state: nil, changed: false)
        }

        switch existing.attributes.phasedReleaseState {
        case .active, .paused:
            let body = UpdatePhasedReleaseRequest(
                data: .init(
                    id: existing.id,
                    attributes: .init(phasedReleaseState: .complete)
                )
            )
            _ = try await client.patch(
                Endpoints.appStoreVersionPhasedRelease(id: existing.id),
                body: body,
                as: APIResponse<AppStoreVersionPhasedRelease>.self
            )
            return Result(mode: .instant, state: .complete, changed: true)
        case .complete:
            return Result(mode: .instant, state: .complete, changed: false)
        case .inactive, nil:
            try await client.delete(Endpoints.appStoreVersionPhasedRelease(id: existing.id))
            return Result(mode: .instant, state: nil, changed: true)
        }
    }

    struct Result: Sendable {
        let mode: Mode
        let state: PhasedReleaseState?
        let changed: Bool

        var description: String {
            switch mode {
            case .phased:
                return "phased rollout (state: \(state?.rawValue ?? "INACTIVE"))"
            case .instant:
                return "instant rollout to all users"
            }
        }
    }

    enum Mode: Sendable {
        case phased
        case instant
    }
}
