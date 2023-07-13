//===----------------------------------------------------------*- swift -*-===//
//
// Created by Yikai Wu on 2023/7/10.
// Copyright © 2023 Yikai Wu. All rights reserved.
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import CustomCombine
import Combine

class CustomCombineTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScan() throws {
        let subjectA = PassthroughSubject<Int, Never>()
        let scanB = Publishers.Scan(upstream: subjectA, initialResult: 10, nextPartialResult: +)
        
        var received = [Subscribers.Event<Int, Never>]()
        let sink = Subscribers.Sink {
            received.append(.completion($0))
        } receiveValue: {
            received.append(.value($0))
        }

        scanB.subscribe(sink)
        subjectA.send(sequence: 1...3, completion: .finished)
        
        XCTAssertEqual(received, [11, 13, 16].asEvents(completion: .finished))
    }

    func testDeferredSubjects() throws {
        var subjects = [PassthroughSubject<Int, Never>]()
        let deffered = Deferred { () -> PassthroughSubject<Int, Never> in
            let request = PassthroughSubject<Int, Never>()
            subjects.append(request)
            return request
        }
        
        let scanB = Publishers.Scan(upstream: deffered, initialResult: 10, nextPartialResult: +)
        
        var receivedC = [Subscribers.Event<Int, Never>]()
        let sinkC = Subscribers.Sink {
            receivedC.append(.completion($0))
        } receiveValue: {
            receivedC.append(.value($0))
        }
        
        var receivedD = [Subscribers.Event<Int, Never>]()
        let sinkD = Subscribers.Sink {
            receivedD.append(.completion($0))
        } receiveValue: {
            receivedD.append(.value($0))
        }
        
        print("subjects", subjects)
        
        scanB.subscribe(sinkC)
        print("subjects-1", subjects)
        
        scanB.subscribe(sinkD)
        print("subjects-2", subjects)
    }
    
    func testSharedSubject() {
        let subjectA = PassthroughSubject<Int, Never>()
        let scanB = subjectA.scan(10, +)

        var receivedC = [Subscribers.Event<Int, Never>]()
        let sinkC = scanB.sink(event: { receivedC.append($0) })
        
        subjectA.send(sequence: 1...2, completion: nil)
        
        var receivedD = [Subscribers.Event<Int, Never>]()
        let sinkD = scanB.sink(event: { receivedD.append($0) })
        
        subjectA.send(sequence: 3...4, completion: .finished)
        
        XCTAssertEqual(receivedC, [11, 13, 16, 20].asEvents(completion: .finished))
        XCTAssertEqual(receivedD, [13, 17].asEvents(completion: .finished))
        
        sinkC.cancel()
        sinkD.cancel()
    }
    
    func testMulticastSubject() {
        let subjectA = PassthroughSubject<Int, Never>()
        let multicastB = subjectA.scan(10, +)
            .multicast { PassthroughSubject() }
            .autoconnect()
        
        var receivedC = [Subscribers.Event<Int, Never>]()
        let sinkC = multicastB.sink(event: { receivedC.append($0) })
        
        subjectA.send(sequence: 1...2, completion: nil)
        
        var receivedD = [Subscribers.Event<Int, Never>]()
        let sinkD = multicastB.sink(event: { receivedD.append($0) })
        
        subjectA.send(sequence: 3...4, completion: .finished)
        
        XCTAssertEqual(receivedC, [11, 13, 16, 20].asEvents(completion: .finished))
        XCTAssertEqual(receivedD, [16, 20].asEvents(completion: .finished))
        
        sinkC.cancel()
        sinkD.cancel()
    }
    
    func testCurrentValueSubject() {
        let subjectA = PassthroughSubject<Int, Never>()
        let multicastB = subjectA.scan(10, +)
            .multicast { CurrentValueSubject(0) }
            .autoconnect()
        
        var receivedC = [Subscribers.Event<Int, Never>]()
        let sinkC = multicastB.sink(event: { receivedC.append($0) })
        
        subjectA.send(sequence: 1...2, completion: nil)
        
        var receivedD = [Subscribers.Event<Int, Never>]()
        let sinkD = multicastB.sink(event: { receivedD.append($0) })
        
        subjectA.send(sequence: 3...4, completion: .finished)
        
        XCTAssertEqual(receivedC, [0, 11, 13, 16, 20].asEvents(completion: .finished))
        XCTAssertEqual(receivedD, [13, 16, 20].asEvents(completion: .finished))
        
        sinkC.cancel()
        sinkD.cancel()
    }
    
    func testMulticastBuffer() {
        let subjectA = PassthroughSubject<Int, Never>()
        let multicastB = subjectA.scan(10, +)
            .multicast { BufferSubject(limit: Int.max) }
            .autoconnect()
        
        var receivedC = [Subscribers.Event<Int, Never>]()
        let sinkC = multicastB.sink(event: { receivedC.append($0) })
        
        subjectA.send(sequence: 1...2, completion: nil)
        
        var receivedD = [Subscribers.Event<Int, Never>]()
        let sinkD = multicastB.sink(event: { receivedD.append($0) })
        
        subjectA.send(sequence: 3...4, completion: .finished)
        
        XCTAssertEqual(receivedC, [11, 13, 16, 20].asEvents(completion: .finished))
        XCTAssertEqual(receivedD, [11, 13, 16, 20].asEvents(completion: .finished))
        
        sinkC.cancel()
        sinkD.cancel()
    }
    
    func testMergeInput() {
        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()
        let input = MergeInput<Int>()
        
        subject1.merge(into: input)
        subject2.merge(into: input)
        
        var received = [Subscribers.Event<Int, Never>]()
        
        let sink = input.sink(receiveCompletion: {
            received.append(.completion($0))
        }, receiveValue: {
            received.append(.value($0))
        })
        
        subject1.send(sequence: 1...2, completion: .finished)
        subject2.send(sequence: 3...4, completion: .finished)
        
        XCTAssertEqual(received, [1, 2, 3, 4].asEvents(completion: nil))
        
        sink.cancel()
    }
}
