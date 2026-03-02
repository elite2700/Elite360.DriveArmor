// CommandServiceTests.swift
// DriveArmorTests
//
// Unit tests for CommandModel serialisation and logic.

import XCTest
@testable import DriveArmor

final class CommandServiceTests: XCTestCase {

    // MARK: - CommandModel

    func testCommandModelToDictionary() {
        let cmd = CommandModel(
            id: "cmd-001",
            type: .enableSafeMode,
            status: .pending,
            targetChildId: "child-1",
            issuedBy: "parent-1",
            params: CommandParams(durationMinutes: 30, reason: "School zone")
        )
        let dict = cmd.asDictionary

        XCTAssertEqual(dict["type"] as? String, "enableSafeMode")
        XCTAssertEqual(dict["status"] as? String, "pending")
        XCTAssertEqual(dict["targetChildId"] as? String, "child-1")

        let params = dict["params"] as? [String: Any]
        XCTAssertEqual(params?["durationMinutes"] as? Int, 30)
        XCTAssertEqual(params?["reason"] as? String, "School zone")
    }

    func testCommandModelFromDictionary() {
        let dict: [String: Any] = [
            "type": "disableSafeMode",
            "status": "completed",
            "targetChildId": "child-2",
            "issuedBy": "parent-1",
            "createdAt": Date(),
            "updatedAt": Date()
        ]
        let cmd = CommandModel.from(dictionary: dict, id: "cmd-002")

        XCTAssertNotNil(cmd)
        XCTAssertEqual(cmd?.type, .disableSafeMode)
        XCTAssertEqual(cmd?.status, .completed)
    }

    func testCommandModelFromDictionaryInvalidType() {
        let dict: [String: Any] = [
            "type": "invalidCommand",
            "status": "pending",
            "targetChildId": "child-3",
            "issuedBy": "parent-1"
        ]
        let cmd = CommandModel.from(dictionary: dict, id: "cmd-003")
        XCTAssertNil(cmd, "Should return nil for unrecognised command type")
    }

    // MARK: - FamilyModel

    func testFamilyPairingCodeGeneration() {
        let code = FamilyModel.generatePairingCode()
        XCTAssertEqual(code.count, 6)
        // Code should be uppercase alphanumeric (excluding confusable chars)
        let allowed = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        for char in code.unicodeScalars {
            XCTAssertTrue(allowed.contains(char), "Unexpected character: \(char)")
        }
    }

    func testFamilyModelToDictionary() {
        let family = FamilyModel(
            id: "fam-001",
            name: "Test Family",
            parentId: "parent-1",
            childIds: ["child-1", "child-2"],
            pairingCode: "AB3CD4"
        )
        let dict = family.asDictionary

        XCTAssertEqual(dict["name"] as? String, "Test Family")
        XCTAssertEqual(dict["parentId"] as? String, "parent-1")
        XCTAssertEqual((dict["childIds"] as? [String])?.count, 2)
    }
}
