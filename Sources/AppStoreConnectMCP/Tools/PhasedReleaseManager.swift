import Foundation

struct PhasedReleaseManager: Sendable {
    let client: AppStoreConnectClient

    func setEnabled(
        _ enabled: Bool,
        forVersionID versionID: String,
        confirmImmediateRelease: Bool = false
    ) async throws -> Result {
        let existing = try await currentPhasedRelease(forVersionID: versionID)
        if let existing, existing.attributes.phasedReleaseState == nil {
            throw AppStoreConnectError.decoding(
                "Phased release [\(existing.id)] did not include phasedReleaseState"
            )
        }

        let action = try Self.plannedAction(
            enabled: enabled,
            existingState: existing?.attributes.phasedReleaseState,
            confirmImmediateRelease: confirmImmediateRelease
        )

        return try await perform(
            action,
            enabled: enabled,
            existing: existing,
            versionID: versionID
        )
    }

    func currentPhasedRelease(forVersionID versionID: String) async throws -> AppStoreVersionPhasedRelease? {
        let relationship: ResourceIdentifierResponse
        do {
            relationship = try await client.get(
                Endpoints.appStoreVersionPhasedReleaseRelationship(versionID: versionID),
                as: ResourceIdentifierResponse.self
            )
        } catch let error as AppStoreConnectError {
            guard case .httpError(statusCode: 404, _) = error else { throw error }

            // A 404 can mean either that the version does not exist or that it has
            // no phased-release relationship. Verify the parent before treating it
            // as an instant rollout.
            _ = try await client.get(
                Endpoints.appStoreVersion(id: versionID),
                as: APIResponse<AppStoreVersion>.self
            )
            return nil
        }

        let response = try await client.get(
            Endpoints.appStoreVersionPhasedRelease(id: relationship.data.id),
            as: APIResponse<AppStoreVersionPhasedRelease>.self
        )
        return response.data
    }

    static func plannedAction(
        enabled: Bool,
        existingState: PhasedReleaseState?,
        confirmImmediateRelease: Bool
    ) throws -> Action {
        if enabled {
            switch existingState {
            case nil:
                return .create
            case .inactive, .active:
                return .keep
            case .paused:
                return .update(.active)
            case .complete:
                throw AppStoreConnectError.invalidArgument(
                    "Phased release cannot be enabled because rollout for this version is already complete"
                )
            }
        }

        switch existingState {
        case nil, .complete:
            return .keep
        case .inactive:
            return .delete
        case .active, .paused:
            guard confirmImmediateRelease else {
                throw AppStoreConnectError.invalidArgument(
                    "confirm_immediate_release must be true because disabling an active or paused phased release immediately releases the version to all users"
                )
            }
            return .update(.complete)
        }
    }

    private func perform(
        _ action: Action,
        enabled: Bool,
        existing: AppStoreVersionPhasedRelease?,
        versionID: String
    ) async throws -> Result {
        switch action {
        case .keep:
            return Result(
                mode: enabled ? .phased : .instant,
                state: existing?.attributes.phasedReleaseState,
                changed: false
            )
        case .create:
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
        case .update(let targetState):
            guard let existing else {
                throw AppStoreConnectError.decoding(
                    "Cannot update phased release because its resource is missing"
                )
            }
            let body = UpdatePhasedReleaseRequest(
                data: .init(
                    id: existing.id,
                    attributes: .init(phasedReleaseState: targetState)
                )
            )
            let response = try await client.patch(
                Endpoints.appStoreVersionPhasedRelease(id: existing.id),
                body: body,
                as: APIResponse<AppStoreVersionPhasedRelease>.self
            )
            return Result(
                mode: enabled ? .phased : .instant,
                state: response.data.attributes.phasedReleaseState ?? targetState,
                changed: true
            )
        case .delete:
            guard let existing else {
                throw AppStoreConnectError.decoding(
                    "Cannot delete phased release because its resource is missing"
                )
            }
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

    enum Action: Equatable, Sendable {
        case create
        case keep
        case update(PhasedReleaseState)
        case delete
    }
}
