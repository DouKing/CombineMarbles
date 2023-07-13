//===----------------------------------------------------------*- swift -*-===//
//
// Created by Yikai Wu on 2023/7/13.
// Copyright © 2023 Yikai Wu. All rights reserved.
//
//===----------------------------------------------------------------------===//

import Combine

public class MergeInput<I>: Publisher, Cancellable {
    public typealias Output = I
    public typealias Failure = Never
    
    public let subscriptions = AtomicBox(Dictionary<CombineIdentifier, Subscribers.Sink<I, Never>>())
    let subject = PassthroughSubject<I, Never>()
    
    deinit {
        cancel()
    }
    
    public init() {}
    
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, I == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    public func cancel() {
        subscriptions.mutate {
            $0.values.forEach { $0.cancel() }
            $0.removeAll()
        }
    }
}

public extension MergeInput {
    func subscribe<P>(_ publisher: P) where P: Publisher, P.Output == I, P.Failure == Never {
        var identifier: CombineIdentifier?
        
        let sink = Subscribers.Sink<I, P.Failure> { _ in
            self.subscriptions.mutate {
                _ = $0.removeValue(forKey: identifier!)
            }
        } receiveValue: {
            self.subject.send($0)
        }

        identifier = sink.combineIdentifier
        subscriptions.mutate {
            $0[sink.combineIdentifier] = sink
        }
        
        publisher.subscribe(sink)
    }
}

public extension Publisher where Failure == Never {
    func merge(into mergeInput: MergeInput<Output>) {
        mergeInput.subscribe(self)
    }
}
