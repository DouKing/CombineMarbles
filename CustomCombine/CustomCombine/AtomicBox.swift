//===----------------------------------------------------------*- swift -*-===//
//
// Created by Yikai Wu on 2023/7/11.
// Copyright © 2023 Yikai Wu. All rights reserved.
//
//===----------------------------------------------------------------------===//

import Foundation

public final class AtomicBox<T> {
    @usableFromInline var mutex = os_unfair_lock()
    @usableFromInline var unboxed: T
    
    init(_ unboxed: T) {
        self.unboxed = unboxed
    }
    
    @discardableResult @inlinable
    public func mutate<U>(_ fn: (inout T) throws -> U) rethrows -> U {
        os_unfair_lock_lock(&mutex)
        defer { os_unfair_lock_unlock(&mutex) }
        
        return try fn(&unboxed)
    }
    
    @inlinable public var value: T {
        os_unfair_lock_lock(&mutex)
        defer { os_unfair_lock_unlock(&mutex) }
        
        return unboxed
    }
    
    public var isMutating: Bool {
        if os_unfair_lock_trylock(&mutex) {
            os_unfair_lock_unlock(&mutex)
            return false
        }
        return true
    }
}

@propertyWrapper
public class Atomic<T> {
    let boxed: AtomicBox<T>
    
    public init(wrappedValue: T) {
        self.boxed = AtomicBox<T>(wrappedValue)
    }
    
    public var wrappedValue: T {
        return self.boxed.value
    }
    
    public var protectedValue: AtomicBox<T> {
        return self.boxed
    }
}
