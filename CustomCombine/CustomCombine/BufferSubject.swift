//===----------------------------------------------------------*- swift -*-===//
//
// Created by Yikai Wu on 2023/7/11.
// Copyright © 2023 Yikai Wu. All rights reserved.
//
//===----------------------------------------------------------------------===//

import Combine

public struct Buffer<Output, Failure: Error> {
    var values: [Output] = []
    var completion: Subscribers.Completion<Failure>? = nil
    let limit: Int
    let strategy: Publishers.BufferingStrategy<Failure>
    
    var isEmpty: Bool {
        return values.isEmpty && completion == nil
    }
    
    mutating func push(_ value: Output) {
        guard completion == nil else { return }
        guard values.count < limit else {
            switch strategy {
            case .dropNewest:
                values.removeLast()
                values.append(value)
            case .dropOldest:
                values.removeFirst()
                values.append(value)
            case .customError(let errFn):
                completion = .failure(errFn())
            @unknown default:
                fatalError()
            }
            return
        }
        
        values.append(value)
    }
    
    mutating func push(completion: Subscribers.Completion<Failure>) {
        guard self.completion == nil else { return }
        self.completion = completion
    }
    
    mutating func fetch() -> Subscribers.Event<Output, Failure>? {
        if values.count > 0 {
            return .value(values.removeFirst())
        }
        else if let completion = self.completion {
            values = []
            self.completion = nil
            return .completion(completion)
        }
        
        return nil
    }
}

public class BufferSubject<Output, Failure: Error>: Subject {
    class Behavior: SubscriptionBehavior {
        typealias Input = Output

        var upstream: Subscription? = nil
        let downstream: AnySubscriber<Input, Failure>
        let subject: BufferSubject<Output, Failure>
        var demand: Subscribers.Demand = .none
        var buffer: Buffer<Output, Failure>
        
        init(
            subject: BufferSubject<Output, Failure>,
            downstream: AnySubscriber<Input, Failure>,
            buffer: Buffer<Output, Failure>
        ) {
            self.downstream = downstream
            self.subject = subject
            self.buffer = buffer
        }
        
        func request(_ d: Subscribers.Demand) {
            self.demand += d
            
            while self.demand > 0, let next = buffer.fetch() {
                self.demand -= 1
                
                switch next {
                case .value(let value):
                    let newDemand = self.downstream.receive(value)
                    self.demand += newDemand
                case .completion(let completion):
                    self.downstream.receive(completion: completion)
                }
            }
        }
        
        func receive(_ input: Output) -> Subscribers.Demand {
            if self.demand > 0 && self.buffer.isEmpty {
                let newDemand = self.downstream.receive(input)
                self.demand = newDemand + self.demand - 1
            } else {
                self.buffer.push(input)
            }
            return .unlimited
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            if self.buffer.isEmpty {
                self.downstream.receive(completion: completion)
            } else {
                self.buffer.push(completion: completion)
            }
        }
        
        func cancel() {
            self.subject.subscribers.mutate {
                $0.removeValue(forKey: self.combineIdentifier)
            }
        }
    }
    
    typealias SubscriberRecords = Dictionary<CombineIdentifier, CustomSubscription<Behavior>>
    let subscribers = AtomicBox<SubscriberRecords>([:])
    let buffer: AtomicBox<Buffer<Output, Failure>>
    
    public init(
        limit: Int = 1,
        whenFull strategy: Publishers.BufferingStrategy<Failure> = .dropOldest
    ) {
        precondition(limit >= 0)
        self.buffer = AtomicBox(Buffer(limit: limit, strategy: strategy))
    }
    
    public func send(subscription: Subscription) {
        subscription.request(.unlimited)
    }
    
    public func send(_ value: Output) {
        self.buffer.mutate {
            $0.push(value)
        }
        
        for (_, sub) in subscribers.value {
            _ = sub.receive(value)
        }
    }
    
    public func send(completion: Subscribers.Completion<Failure>) {
        self.buffer.mutate {
            $0.push(completion: completion)
        }
        
        for (_, sub) in subscribers.value {
            sub.receive(completion: completion)
        }
        
        self.subscribers.mutate {
            $0.removeAll()
        }
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let behavior = Behavior(
            subject: self,
            downstream: AnySubscriber(subscriber),
            buffer: self.buffer.value
        )
        let subscription = CustomSubscription(behavior: behavior)
        self.subscribers.mutate {
            $0[subscription.combineIdentifier] = subscription
        }
        
        subscription.receive(subscription: Subscriptions.empty)
    }
}
