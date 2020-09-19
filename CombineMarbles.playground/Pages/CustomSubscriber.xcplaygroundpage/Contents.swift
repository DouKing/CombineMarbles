//: [Previous](@previous)

import Combine
import Foundation

[1,2,3,4,5].publisher.sink { (completion: Subscribers.Completion<Never>) in
    print(completion)
} receiveValue: { (value: Int) in
    print(value)
}

//: 自定义

public protocol Resumable {
    func resume()
}

extension Subscribers {
    final public class ResumableSink<Input, Failure> : Subscriber, Cancellable, Resumable where Failure : Error {
        let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
        let receiveValue: (Input) -> Bool
        var subscription: Subscription?
        
        var shouldPullNewValue: Bool = false
        
        init(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void), receiveValue: @escaping ((Input) -> Bool)) {
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
        }
        
        public func receive(subscription: Subscription) {
            self.subscription = subscription
            resume()
        }
        
        public func receive(_ input: Input) -> Subscribers.Demand {
            shouldPullNewValue = receiveValue(input)
            return shouldPullNewValue ? .max(1) : .none
        }
        
        public func receive(completion: Subscribers.Completion<Failure>) {
            receiveCompletion(completion)
            subscription = nil
        }
        
        public func cancel() {
            subscription?.cancel()
            subscription = nil
        }
        
        public func resume() {
            guard !shouldPullNewValue else {
                return
            }
            shouldPullNewValue = true
            subscription?.request(.max(1))
        }
    }
}

extension Publisher {
    public func resumableSink(
        receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void),
        receiveValue: @escaping ((Self.Output) -> Bool)
    ) -> Cancellable & Resumable {
        let sink = Subscribers.ResumableSink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
        subscribe(sink)
        return sink
    }
}

print("========== ResumableSink ==========")

var buffer: [Int] = []

let subscriber = (1...100).publisher //.print()
    .resumableSink { (completion: Subscribers.Completion<Never>) in
        print(completion)
    } receiveValue: { (value: Int) -> Bool in
        print(value)
        buffer.append(value)
        return buffer.count < 5
    }

let cancellable = Timer.publish(every: 1, on: .main, in: .default)
    .autoconnect()
    .sink { _ in
        buffer.removeAll()
        subscriber.resume()
    }

//: [Next](@next)
