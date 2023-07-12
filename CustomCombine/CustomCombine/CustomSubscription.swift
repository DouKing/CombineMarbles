//===----------------------------------------------------------*- swift -*-===//
//
// Created by Yikai Wu on 2023/7/12.
// Copyright © 2023 Yikai Wu. All rights reserved.
//
//===----------------------------------------------------------------------===//

import Combine

public protocol SubscriptionBehavior: AnyObject, Cancellable, CustomCombineIdentifierConvertible {
    associatedtype Input
    associatedtype Failure: Error
    associatedtype Output
    associatedtype OutputFailure: Error
    
    var demand: Subscribers.Demand { get set }
    var upstream: Subscription? { get set }
    var downstream: AnySubscriber<Output, OutputFailure> { get }
    
    func request(_ d: Subscribers.Demand)
    func receive(_ input: Input) -> Subscribers.Demand
    func receive(completion: Subscribers.Completion<Failure>)
}

public extension SubscriptionBehavior {
    func request(_ d: Subscribers.Demand) {
        self.demand += d
        self.upstream?.request(self.demand)
    }
    
    func cancel() {
        self.upstream?.cancel()
    }
}

public extension SubscriptionBehavior where Input == Output, Failure == OutputFailure {
    func receive(_ input: Input) -> Subscribers.Demand {
        if self.demand > 0 {
            let newDemand = self.downstream.receive(input)
            self.demand = newDemand + self.demand - 1
            return self.demand
        }
        
        return .none
    }
}

public extension SubscriptionBehavior where Failure == OutputFailure {
    func receive(completion: Subscribers.Completion<Failure>) {
        self.downstream.receive(completion: completion)
    }
}

public struct CustomSubscription<Content: SubscriptionBehavior>: Subscriber, Subscription {
    public typealias Input = Content.Input
    public typealias Failure = Content.Failure
    public var combineIdentifier: CombineIdentifier {
        return content.combineIdentifier
    }
    
    let recursiveMutext = NSRecursiveLock()
    let content: Content
    
    init(behavior: Content) {
        self.content = behavior
    }
    
    public func request(_ demand: Subscribers.Demand) {
        recursiveMutext.lock()
        defer { recursiveMutext.unlock() }
        content.request(demand)
    }
    
    public func cancel() {
        recursiveMutext.lock()
        defer { recursiveMutext.unlock() }
        content.cancel()
    }
    
    public func receive(subscription: Subscription) {
        recursiveMutext.lock()
        defer { recursiveMutext.unlock() }
        
        content.upstream = subscription
        content.downstream.receive(subscription: self)
    }
    
    public func receive(_ input: Content.Input) -> Subscribers.Demand {
        recursiveMutext.lock()
        defer { recursiveMutext.unlock() }
        return content.receive(input)
    }
    
    public func receive(completion: Subscribers.Completion<Content.Failure>) {
        recursiveMutext.lock()
        defer { recursiveMutext.unlock() }
        content.receive(completion: completion)
    }
}
