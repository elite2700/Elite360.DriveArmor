// AuthServiceTests.swift
// DriveArmorTests
//
// Unit tests for AuthService. Uses Firebase Auth emulator when available,
// otherwise verifies model serialisation and validation logic.

import XCTest
@testable import DriveArmor

final class AuthServiceTests: XCTestCase {

    // MARK: - UserModel Tests

    func testUserModelToDictionary() {
        let user = UserModel(
            uid: "uid-123",
            email: "parent@test.com",
            displayName: "Test Parent",
            role: .parent,
            familyId: "fam-abc"
        )
        let dict = user.asDictionary

        XCTAssertEqual(dict["uid"] as? String, "uid-123")
        XCTAssertEqual(dict["email"] as? String, "parent@test.com")
        XCTAssertEqual(dict["displayName"] as? String, "Test Parent")
        XCTAssertEqual(dict["role"] as? String, "parent")
        XCTAssertEqual(dict["familyId"] as? String, "fam-abc")
    }

    func testUserModelFromDictionary() {
        let dict: [String: Any] = [
            "email": "child@test.com",
            "displayName": "Test Child",
            "role": "child",
            "familyId": "fam-xyz"
        ]
        let user = UserModel.from(dictionary: dict, uid: "uid-456")

        XCTAssertNotNil(user)
        XCTAssertEqual(user?.uid, "uid-456")
        XCTAssertEqual(user?.role, .child)
        XCTAssertEqual(user?.familyId, "fam-xyz")
    }

    func testUserModelFromDictionaryMissingEmail() {
        let dict: [String: Any] = ["displayName": "No Email"]
        let user = UserModel.from(dictionary: dict, uid: "uid-789")
        XCTAssertNil(user, "Should return nil when email is missing")
    }

    // MARK: - Role Encoding

    func testUserRoleRawValues() {
        XCTAssertEqual(UserRole.parent.rawValue, "parent")
        XCTAssertEqual(UserRole.child.rawValue, "child")
    }
}
