//: [Previous](@previous)

import Foundation
import Combine

extension Publishers {
    public struct ZipAll<Collection: Swift.Collection>: Publisher where Collection.Element: Publisher {
        public typealias Output = [Collection.Element.Output]
        public typealias Failure = Collection.Element.Failure
        
        private var publishers: Collection
        
        init(_ publishers: Collection) {
            self.publishers = publishers
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let subscription = ZipAllSubscription(
                subscriber: subscriber,
                publishers: publishers.map { $0.eraseToAnyPublisher() }
            )
            subscriber.receive(subscription: subscription)
            subscription.startSubscribing()
        }
    }
    
    private class ZipAllSubscription<Output, Failure: Error>: Subscription {
        private var leftDemand: Subscribers.Demand = .none
        private var subscriber: AnySubscriber<[Output], Failure>? = nil
        private var buffer: [[Output]]
        private let publishers: [AnyPublisher<Output, Failure>]
        private var childSubscriptions: [AnyCancellable] = []
        
        private var finishedCount = 0
        private let lock = NSRecursiveLock()
        
        init<S: Subscriber>(subscriber: S, publishers: [AnyPublisher<Output, Failure>]) where Failure == S.Failure, [Output] == S.Input {
            self.subscriber = AnySubscriber<[Output], Failure>(subscriber)
            self.publishers = publishers
            self.buffer = Array(repeating: [], count: publishers.count)
        }
        
        func startSubscribing() {
            for (i, publisher) in publishers.enumerated() {
                publisher.sink { [weak self] (completion: Subscribers.Completion<Failure>) in
                    self?.receiveCompletion(completion, at: i)
                } receiveValue: { [weak self] (value: Output) in
                    self?.receiveValue(value, at: i)
                }
                .store(in: &childSubscriptions)
            }
        }
        
        func receiveValue(_ value: Output, at index: Int) {
            lock.lock()
            defer { lock.unlock() }
            buffer[index].append(value)
            
            send()
        }
        
        func receiveCompletion(_ event: Subscribers.Completion<Failure>, at index: Int) {
            lock.lock()
            defer { lock.unlock() }
            
            guard let subscriber = subscriber else { return }
            
            switch event {
            case .finished:
                finishedCount += 1
                if finishedCount == buffer.count {
                    subscriber.receive(completion: event)
                    self.subscriber = nil
                }
            case .failure:
                subscriber.receive(completion: event)
                self.subscriber = nil
            }
        }
        
        func send() {
            guard let subscriber = subscriber else { return }
            while leftDemand > .none, let outputs = firstRowOutputItems {
                leftDemand -= .max(1)
                let nextDemand = subscriber.receive(outputs)
                leftDemand += nextDemand
            }
        }
        
        var firstRowOutputItems: [Output]? {
            guard buffer.allSatisfy({ !$0.isEmpty }) else { return nil }
            var outputs = [Output]()
            for i in 0 ..< buffer.count {
                var column = buffer[i]
                outputs.append(column.removeFirst())
                buffer[i] = column
            }
            return outputs
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            defer { lock.unlock() }
            
            leftDemand += demand
            send()
        }
        
        func cancel() {
            lock.lock()
            defer { lock.unlock() }
            
            childSubscriptions = []
            subscriber = nil
        }
    }
}

extension Collection where Element: Publisher {
    var zipAll: Publishers.ZipAll<Self> {
        Publishers.ZipAll(self)
    }
}

let p1 = [1,2,3].publisher
let p2 = [4,5,6].publisher
let p3 = [7,8,9,10].publisher

let zipped = [p1, p2, p3].zipAll
zipped.sink { completion in
    print(completion)
} receiveValue: { value in
    print(value)
}

//: [Next](@next)
