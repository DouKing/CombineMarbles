//===----------------------------------------------------------*- swift -*-===//
//
// Created by Yikai Wu on 2023/7/10.
// Copyright © 2023 Yikai Wu. All rights reserved.
//
//===----------------------------------------------------------------------===//

import Combine

public extension Subject {
    func send<S: Sequence>(
        sequence: S,
        completion: Subscribers.Completion<Self.Failure>? = nil
    ) where S.Element == Self.Output {
        for value in sequence {
            send(value)
        }
        
        if let completion {
            send(completion: completion)
        }
    }
}

public extension Publisher {
    func sink(event: @escaping ((Subscribers.Event<Self.Output, Self.Failure>) -> Void)) -> AnyCancellable {
        self.sink {
            event(.completion($0))
        } receiveValue: {
            event(.value($0))
        }
    }
}
