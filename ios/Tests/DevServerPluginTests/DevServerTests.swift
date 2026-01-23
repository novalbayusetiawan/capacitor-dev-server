import XCTest
@testable import DevServerPlugin

class DevServerTests: XCTestCase {
    func testInitialization() {
        let implementation = DevServer()
        XCTAssertNotNil(implementation)
    }
}
