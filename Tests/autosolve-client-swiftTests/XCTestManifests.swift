import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(autosolve_client_swiftTests.allTests),
    ]
}
#endif
