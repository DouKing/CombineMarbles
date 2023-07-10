//===----------------------------------------------------------*- swift -*-===//
//
// Created by Yikai Wu on 2023/7/10.
// Copyright © 2023 Yikai Wu. All rights reserved.
//
//===----------------------------------------------------------------------===//

import Combine

public extension Subscribers {
    enum Event<Value, Failure: Error> {
        case value(Value)
        case completion(Subscribers.Completion<Failure>)
    }
}

extension Subscribers.Event: Equatable where Value: Equatable, Failure: Equatable {
    
}

public extension Sequence {
    func asEvent<Failure>(
        failure: Failure.Type,
        completion: Subscribers.Completion<Failure>? = nil
    ) -> [Subscribers.Event<Element, Failure>] {
        let values = map(Subscribers.Event<Element, Failure>.value) //这里能直接传 enum case :)
        guard let completion else {
            return values
        }
        
        return values + [Subscribers.Event.completion(completion)]
    }
    
    func asEvent(
        completion: Subscribers.Completion<Never>? = nil
    ) -> [Subscribers.Event<Element, Never>] {
        asEvent(failure: Never.self, completion: completion)
    }
}
