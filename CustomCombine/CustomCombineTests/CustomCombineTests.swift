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
        
        XCTAssertEqual(received, [11, 13, 16].asEvent(completion: .finished))
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
}
