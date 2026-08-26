import XCTest
@testable import ProductivityOS

final class KeychainManagerTests: XCTestCase {
    
    func testKeychainSaveReadDelete() {
        let keychain = KeychainManager(serviceName: "com.productivityos.test")
        let testKey = "test_auth_token"
        let testValue = "jwt.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test"
        
        // Save
        let saved = keychain.save(key: testKey, string: testValue)
        XCTAssertTrue(saved)
        
        // Read
        let retrieved = keychain.readString(key: testKey)
        XCTAssertEqual(retrieved, testValue)
        
        // Delete
        let deleted = keychain.delete(key: testKey)
        XCTAssertTrue(deleted)
        
        // Verify deleted
        let afterDelete = keychain.readString(key: testKey)
        XCTAssertNil(afterDelete)
    }
}
