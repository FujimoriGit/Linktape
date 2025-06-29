//
//  DependencyValues.swift
//  Linktape
//  
//  Created by Daiki Fujimori on 2025/06/29
//  

protocol DependencyKey {
    
    associatedtype Value: Sendable
    static var liveValue: Value { get }
}

struct DependencyValues: Sendable {
    
    @TaskLocal static fileprivate var current = Self()
    private var storage: [ObjectIdentifier: any Sendable] = [:]
    
    subscript<K>(key: K.Type) -> K.Value where K : DependencyKey {
        
        get {
            
            guard let base = storage[ObjectIdentifier(key)],
                  let dependency = base as? K.Value else {
                
                return key.liveValue
            }
            return dependency
        }
        
        set {
            
            storage[ObjectIdentifier(key)] = newValue
        }
    }
}

extension DependencyValues {
    
    static func withDependency<R>(_ setDependency: (inout DependencyValues) -> Void, operation: () -> R) -> R {
        
        var currentDependencyValue = DependencyValues.current
        setDependency(&currentDependencyValue)
        
        return DependencyValues.$current.withValue(currentDependencyValue) { operation() }
    }
    
    static func withDependency<R>(_ setDependency: (inout DependencyValues) -> Void, operation: () async -> R) async -> R {
        
        var currentDependencyValue = DependencyValues.current
        setDependency(&currentDependencyValue)
        
        return await DependencyValues.$current.withValue(currentDependencyValue) { await operation() }
    }
}

@propertyWrapper
struct Dependency<Value> {
    
    private let keyPath: KeyPath<DependencyValues, Value> & Sendable

    init(_ keyPath: KeyPath<DependencyValues, Value> & Sendable) {
        
        self.keyPath = keyPath
    }

    var wrappedValue: Value { DependencyValues.current[keyPath: self.keyPath] }
}
