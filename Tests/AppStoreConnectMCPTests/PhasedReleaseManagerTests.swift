import XCTest

final class PhasedReleaseManagerTests: XCTestCase {
    func testEnablingWithoutConfigurationCreatesPhasedRelease() throws {
        let action = try PhasedReleaseManager.plannedAction(
            enabled: true,
            existingState: nil,
            confirmImmediateRelease: false
        )

        XCTAssertEqual(action, .create)
    }

    func testEnablingPausedConfigurationResumesPhasedRelease() throws {
        let action = try PhasedReleaseManager.plannedAction(
            enabled: true,
            existingState: .paused,
            confirmImmediateRelease: false
        )

        XCTAssertEqual(action, .update(.active))
    }

    func testDisablingInactiveConfigurationDeletesIt() throws {
        let action = try PhasedReleaseManager.plannedAction(
            enabled: false,
            existingState: .inactive,
            confirmImmediateRelease: false
        )

        XCTAssertEqual(action, .delete)
    }

    func testDisablingActiveConfigurationRequiresConfirmation() {
        XCTAssertThrowsError(
            try PhasedReleaseManager.plannedAction(
                enabled: false,
                existingState: .active,
                confirmImmediateRelease: false
            )
        ) { error in
            XCTAssertTrue(
                error.localizedDescription.contains("confirm_immediate_release must be true")
            )
        }
    }

    func testConfirmedDisableCompletesActiveConfiguration() throws {
        let action = try PhasedReleaseManager.plannedAction(
            enabled: false,
            existingState: .active,
            confirmImmediateRelease: true
        )

        XCTAssertEqual(action, .update(.complete))
    }

    func testCompletedConfigurationCannotBeReenabled() {
        XCTAssertThrowsError(
            try PhasedReleaseManager.plannedAction(
                enabled: true,
                existingState: .complete,
                confirmImmediateRelease: false
            )
        )
    }
}
