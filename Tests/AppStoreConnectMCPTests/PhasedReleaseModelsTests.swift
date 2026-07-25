import XCTest
@testable import AppStoreConnectMCP

final class PhasedReleaseModelsTests: XCTestCase {
    func testCreateRequestMatchesJSONAPIShape() throws {
        let request = CreatePhasedReleaseRequest(
            data: .init(
                attributes: .init(phasedReleaseState: .inactive),
                relationships: .init(
                    appStoreVersion: .init(
                        data: .init(type: "appStoreVersions", id: "version-id")
                    )
                )
            )
        )

        let encoded = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        let data = try XCTUnwrap(object["data"] as? [String: Any])
        let attributes = try XCTUnwrap(data["attributes"] as? [String: Any])
        let relationships = try XCTUnwrap(data["relationships"] as? [String: Any])
        let appStoreVersion = try XCTUnwrap(
            relationships["appStoreVersion"] as? [String: Any]
        )
        let relationshipData = try XCTUnwrap(
            appStoreVersion["data"] as? [String: Any]
        )

        XCTAssertEqual(data["type"] as? String, "appStoreVersionPhasedReleases")
        XCTAssertEqual(attributes["phasedReleaseState"] as? String, "INACTIVE")
        XCTAssertEqual(relationshipData["type"] as? String, "appStoreVersions")
        XCTAssertEqual(relationshipData["id"] as? String, "version-id")
    }

    func testUpdateRequestMatchesJSONAPIShape() throws {
        let request = UpdatePhasedReleaseRequest(
            data: .init(
                id: "phased-release-id",
                attributes: .init(phasedReleaseState: .complete)
            )
        )

        let encoded = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        let data = try XCTUnwrap(object["data"] as? [String: Any])
        let attributes = try XCTUnwrap(data["attributes"] as? [String: Any])

        XCTAssertEqual(data["type"] as? String, "appStoreVersionPhasedReleases")
        XCTAssertEqual(data["id"] as? String, "phased-release-id")
        XCTAssertEqual(attributes["phasedReleaseState"] as? String, "COMPLETE")
    }

    func testRelationshipResponseDecodesResourceIdentifier() throws {
        let json = """
        {
          "data": {
            "type": "appStoreVersionPhasedReleases",
            "id": "phased-release-id"
          }
        }
        """

        let response = try JSONDecoder().decode(
            ResourceIdentifierResponse.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(response.data.type, "appStoreVersionPhasedReleases")
        XCTAssertEqual(response.data.id, "phased-release-id")
    }
}
