//
//  DependencyValuesTests.swift
//  Linktape
//
//  Created by Daiki Fujimori on 2025/06/29
//

import XCTest
@testable import Linktape
import Testing

struct DependencyValuesTests {
    
    @Test
    func testDefaultDependencyValue() {
        
        let object = TestObject()
        XCTAssertNotEqual(object.testValue, "default")
        XCTAssertEqual(object.anotherTestValue, 0)
    }

    @Test
    func testWithDependencySync() {
        
        let result = DependencyValues.withDependency { values in
            
            values.testValue = "modified"
            values.anotherTestValue = 123
        } operation: {
            
            let object = TestObject()
            return (object.testValue, object.anotherTestValue)
        }
        
        XCTAssertEqual(result.0, "modified")
        XCTAssertEqual(result.1, 123)

        // デフォルト値に戻っていることを確認
        let object = TestObject()
        XCTAssertEqual(object.testValue, "default")
        XCTAssertEqual(object.anotherTestValue, 0)
    }

    @Test
    func testWithDependencyAsync() async {
        
        let result = await DependencyValues.withDependency({ values in
            
            values.testValue = "async modified"
            values.anotherTestValue = 999
        }, operation: {
            
            await asyncTestObjectValues()
        })
        
        XCTAssertEqual(result.0, "async modified")
        XCTAssertEqual(result.1, 999)

        // デフォルト値に戻っていることを確認
        let object = TestObject()
        XCTAssertEqual(object.testValue, "default")
        XCTAssertEqual(object.anotherTestValue, 0)
    }

    // 非同期で値を返すダミー関数
    private func asyncTestObjectValues() async -> (String, Int) {
        
        try! await Task.sleep(nanoseconds: UInt64(10_000))
        let object = TestObject()
        return (object.testValue, object.anotherTestValue)
    }
}

// MARK: - test data

private struct TestKey: DependencyKey {
    
    static var liveValue = "default"
}

private struct AnotherTestKey: DependencyKey {
    
    static var liveValue = 0
}

private struct TestObject {
    
    @Dependency(\.testValue) var testValue
    @Dependency(\.anotherTestValue) var anotherTestValue
}

private extension DependencyValues {
    
    var testValue: String {
        get {
            self[TestKey.self]
        }
        
        set {
            self[TestKey.self] = newValue
        }
    }
    
    var anotherTestValue: Int {
        
        get {
            self[AnotherTestKey.self]
        }
        
        set {
            self[AnotherTestKey.self] = newValue
        }
    }
}
