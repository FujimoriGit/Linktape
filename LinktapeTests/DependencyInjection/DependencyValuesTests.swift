//
//  DependencyValuesTests.swift
//  Linktape
//
//  Created by Daiki Fujimori on 2025/06/29
//

import XCTest
@testable import Linktape
import Testing

// MARK: - test case

struct DependencyValuesTests {

    @Test("デフォルト値が返ることを確認")
    func defaults() {

        #expect(StringWrapper().value == "default")
        #expect(IntWrapper().value == 42)
        #expect(StructWrapper().value == SimpleStruct(value: 1))
        #expect(EnumWrapper().value == .case1)
        #expect(ClassWrapper().value == SampleClass(id: 0))
    }

    @Test("withDependency スコープ内でのみ上書きが有効 (同期)")
    func overridesSync() {

        let overridden = DependencyValues.withDependency { value in

            value.testString = "override"
            value.testInt = 99
        } operation: {

            (StringWrapper().value, IntWrapper().value)
        }
        
        #expect(overridden.0 == "override")
        #expect(overridden.1 == 99)
        #expect(StringWrapper().value == "default")
        #expect(IntWrapper().value == 42)
    }

    @Test("並列パラメタライズテストが正しく動作する")
    func parallelOverrides() {

        let cases: [(String?, Int?)] = [

            (nil, nil),
            ("foo", 1),
            ("bar", 2)
        ]
        
        DispatchQueue.concurrentPerform(iterations: cases.count) { i in

            let (s, n) = cases[i]
            let (gotS, gotN) = DependencyValues.withDependency { value in

                if let s = s { value.testString = s }
                if let n = n { value.testInt = n }
            } operation: {

                (StringWrapper().value, IntWrapper().value)
            }
            
            #expect(gotS == s ?? "default")
            #expect(gotN == n ?? 42)
        }
    }

    @Test("MainActor コンテキストでの上書きテスト")
    func mainActorOverride() async {

        let result = await MainActor.run {

            DependencyValues.withDependency { value in

                value.testString = "main"
            } operation: {

                StringWrapper().value
            }
        }
        
        #expect(result == "main")
    }

    @Test("actor メソッド内での上書きテスト")
    func actorOverride() async {

        let actor = SampleDependencyActor()
        let str = await actor.read()
        #expect(str == "actor")
    }

    @Test("global actor コンテキストでの上書きテスト")
    func globalActorOverride() async {

        let str = await GlobalDependency.shared.read()
        #expect(str == "global")
    }
}

// MARK: - test data

actor SampleDependencyActor {

    func read() -> String {

        DependencyValues.withDependency { value in

            value.testString = "actor"
        } operation: {

            StringWrapper().value
        }
    }
}

@globalActor
struct GlobalDependency {

    static let shared = GlobalDependencyActor()
}

actor GlobalDependencyActor {

    func read() -> String {

        DependencyValues.withDependency { value in

            value.testString = "global"
        } operation: {

            StringWrapper().value
        }
    }
}

private enum TestStringKey: DependencyKey {

    static let liveValue = "default"
}

private enum TestIntKey: DependencyKey {

    static let liveValue = 42
}

private struct SimpleStruct: Equatable {

    let value: Int
}

private enum SampleEnum: Equatable {

    case case1
    case case2
}

private final class SampleClass: Equatable {

    let id: Int
    init(id: Int) {

        self.id = id
    }
    static func ==(l: SampleClass, r: SampleClass) -> Bool {

        l.id == r.id
    }
}

private enum TestStructKey: DependencyKey {

    static let liveValue = SimpleStruct(value: 1)
}

private enum TestEnumKey: DependencyKey {

    static let liveValue: SampleEnum = .case1
}

private enum TestClassKey: DependencyKey {

    static let liveValue = SampleClass(id: 0)
}

private extension DependencyValues {

    var testString: String {

        get { self[TestStringKey.self] }
        set { self[TestStringKey.self] = newValue }
    }
    
    var testInt: Int {

        get { self[TestIntKey.self] }
        set { self[TestIntKey.self] = newValue }
    }
    
    var testStruct: SimpleStruct {

        get { self[TestStructKey.self] }
        set { self[TestStructKey.self] = newValue }
    }
    
    var testEnum: SampleEnum {

        get { self[TestEnumKey.self] }
        set { self[TestEnumKey.self] = newValue }
    }
    
    var testClass: SampleClass {

        get { self[TestClassKey.self] }
        set { self[TestClassKey.self] = newValue }
    }
}

private struct StringWrapper {

    @Dependency(\.testString) var value: String
}

private struct IntWrapper {

    @Dependency(\.testInt) var value: Int
}

private struct StructWrapper {

    @Dependency(\.testStruct) var value: SimpleStruct
}

private struct EnumWrapper {

    @Dependency(\.testEnum) var value: SampleEnum
}

private struct ClassWrapper {

    @Dependency(\.testClass) var value: SampleClass
}
