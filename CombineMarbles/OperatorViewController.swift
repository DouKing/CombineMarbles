//
// CombineMarbles
// OperatorViewController.swift
//
// Created by wuyikai on 2022/5/18.
// Copyright © 2022 wuyikai. All rights reserved.
// 

import UIKit
import Combine

class OperatorViewController: UIViewController {

    private struct Item: Hashable {
        static func == (lhs: OperatorViewController.Item, rhs: OperatorViewController.Item) -> Bool {
            lhs.identifier == rhs.identifier
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        let title: String
        let detail: String?
        let action: (() -> Void)?
        private let identifier = UUID()
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<String, Item>! = nil
    private var collectionView: UICollectionView! = nil
    private var cancels: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Operators"
        configureHierarchy()
        configureDataSource()
        
        addDataSource()
    }
}

extension OperatorViewController {
    func addDataSource() {
        addTransform()
        addFilter()
        addReduce()
        addOperation()
        addMatch()
        addSequence()
        addCombination()
        addErrorHanding()
        addTiming()
        addOthers()
    }
    
    func addTransform() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "transform", detail: "转换", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "map/mapError", intro: "将给定的值/错误转换为其他值") {
            _ = Just("🍌")
                .map { _ in "🍊" }
                .sink {
                    print("🍌", "->", $0)
                }
            
            _ = Fail<String, CustomError>(error: .test)
                .mapError { error in
                    OriginError.test("转换后的错误")
                }
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { _ in
                    print("走不到这里")
                })
        }
        
        test(name: "flatMap", intro: "将上游 Publisher 中的值用新的 Publisher 发送") {
            _ = Publishers.Sequence(sequence: ["🍌", "🍎", "🍐"])
                .flatMap() { item -> Just in
                    print("new publisher with element: \(item)")
                    return Just(item)
                }.sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { value in
                    print(value)
                })
        }
        
        test(name: "replaceNil", intro: "将收到的空值转换成给定的值") {
            _ = Publishers.Sequence(sequence: ["🍌", "🍎", nil])
                .replaceNil(with: "🍊")
                .sink(receiveValue: { item in
                    print(item!)
                })
        }
        
        test(name: "scan", intro: "将收到的值与当前值按 closure 转换") {
            _ = Publishers.Sequence(sequence: ["🍌", "🍎", "🍐"])
                .scan(10, { price, fruit in
                    price * 2
                })
                .sink(receiveValue: { result in
                    print(result) // 20 40 80
                })
        }
        
        test(name: "setFailureType", intro: "强制将上游 Publisher 的错误类型设置为指定类型，以便与下游匹配") {
            _ = Publishers.Sequence(sequence: ["🍌", "🍎", "🍐"])
                .setFailureType(to: CustomError.self)
                .append(Fail<String, CustomError>(error: CustomError.test))
                //.combineLatest(Fail<Any, CustomError>(error: CustomError.test))
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addFilter() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "filter", detail: "过滤", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "filter", intro: "筛选出符合条件的值") {
            _ = Publishers.Sequence(sequence: [("🍌", 10), ("🍎", 15), ("🍐", 20)])
                .filter({ fruit in
                    fruit.1 < 20
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        test(name: "compactMap", intro: "与 map 类似，只是会自动过滤掉空值") {
            _ = ["🍌", "🍎", nil].publisher
                .compactMap { fruit in
                    fruit
                }
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        test(name: "removeDuplicates", intro: "自动跳过刚刚发送过的值") {
            _ = ["🍌", "🍎", "🍎", "🍎", "🍍"].publisher
                .removeDuplicates(by: { pre, current in
                    pre == current
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        test(name: "replaceEmpty", intro: "如果上游是空值，则发送指定值，正常结束") {
            _ = [].publisher
                .replaceEmpty(with: "🥜")
                .sink(receiveValue: { item in
                    print(item)
                })
        }
        
        test(name: "replaceError", intro: "如果上游因错误而终止，则发送指定值，然后正常结束") {
            _ = Fail<String, CustomError>(error: .test)
                .replaceError(with: "🥜")
                .sink(receiveValue: { item in
                    print(item)
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addReduce() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "reduce", detail: "简化", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "collect", intro: "将上游 Publisher 的值收集到一个数组中，然后发送数组") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .collect()
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            _ = ["🍌", "🍎", "🍐"].publisher
                .collect(2)
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            let pub = Timer.publish(every: 1, on: .main, in: .default)
                .autoconnect()
                .collect(.byTime(RunLoop.main, .seconds(5))) // 每 5s 收集一次
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { item in
                    print(item, terminator: "\n\n")
                })
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                pub.cancel()
            }
        }
        
        test(name: "ignoreOutput", intro: "忽略上游 Publisher 的所有值，但会传递完成状态") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .ignoreOutput()
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        test(name: "reduce", intro: "将接收到的值与当前值按 closure 转换，输出最终的转换结果") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .reduce("", { prev, curr in
                    prev + curr
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addOperation() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "operation", detail: "运算", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "count", intro: "将上游 Publisher 的值的数量作为值发出") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .count()
                .sink(receiveValue: { count in
                    print("接收到\(count)个水果")
                })
        }
        
        test(name: "min/max", intro: "将上游 Publisher 的值中的最大/最小值作为值发出") {
            _ = [1, 2, 3, 9, 5, 6].publisher
                .max()
//                .min()
                .sink(receiveValue: { max in
                    print("收到的最大值是\(max)")
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addMatch() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "match", detail: "匹配", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "contains", intro: "上游 Publisher 是否包含指定值或指定条件的值") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .contains("🍌")
                .sink(receiveValue: { isContains in
                    print(isContains)
                })
            
            _ = [("🍌", 10), ("🍎", 15), ("🍐", 20)].publisher
                .contains(where: { fruit in
                    fruit.1 == 20
                })
                .sink(receiveValue: { isContains in
                    print(isContains)
                })
        }
        
        test(name: "allSatisfy", intro: "上游 Publisher 的值是否都满足给定条件") {
            _ = [("🍌", 10), ("🍎", 15), ("🍐", 20)].publisher
                .allSatisfy({ fruit in
                    fruit.1 < 20
                })
                .sink(receiveValue: { isCheap in
                    print("is cheap? \(isCheap)")
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addSequence() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "sequence", detail: "序列", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "drop/dropFirst", intro: "一直丢弃值，直到满足给定条件") {
            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10), ("🍍", 15)].publisher
                .drop(while: { fruit in
                    fruit.1 > 10
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            print("--")
            
            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10)].publisher
                .dropFirst()
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
//            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10)].publisher
//                .drop(untilOutputFrom: <#T##Publisher#>)
        }
        
        test(name: "append/prepend", intro: "在原有数据流中拼接新的值") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .append("🍊")
                .prepend("🍍")
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            _ = ["🍌", "🍎", "🍐"].publisher
                .append(["🥜"].publisher)
                .prepend(["🌰"].publisher)
                .sink(receiveValue: { item in
                    print(item)
                })
        }
        
        test(name: "prefix/first/last/output", intro: "") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .prefix(2)
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10), ("🍍", 15)].publisher
                .prefix(while: { fruit in
                    fruit.1 > 10
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            print("-- first")
            
            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10), ("🍍", 15)].publisher
                .first(where: { fruit in
                    fruit.1 > 10
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            print("-- last")
            
            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10), ("🍍", 15)].publisher
                .last(where: { fruit in
                    fruit.1 < 20
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            print("-- output")
            
            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10), ("🍍", 15)].publisher
                .output(at: 1)
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            _ = [("🍌", 20), ("🍎", 15), ("🍐", 10), ("🍍", 15)].publisher
                .output(in: 2...)
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addCombination() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "combination", detail: "组合", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "combineLatest", intro: "将两个/多个 Publisher 的最后一个值组合成元组发送") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .combineLatest(Just(10))
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            _ = ["🍌", "🍎", "🍐"].publisher
                .combineLatest([20, 15, 10].publisher, { fruit, price in
                    (fruit, price)
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
            
            let pub1 = PassthroughSubject<Int, Never>()
            let pub2 = PassthroughSubject<Int, Never>()
            
            let cancelable = pub1
                .combineLatest(pub2)
                .sink { print("Result: \($0).") }
            
            pub1.send(1)
            pub1.send(2)
            pub2.send(2)    // (2, 2)
            pub1.send(3)    // (3, 2)
            pub1.send(45)   // (45, 2)
            pub2.send(22)   // (45, 22)
            
            cancelable.cancel()
        }
        
        test(name: "merge", intro: "合并两个 Publisher 的值到一个序列中") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .merge(with: ["🍆", "🥦", "🥬"].publisher)
                .sink(receiveValue: { item in
                    print(item)
                })
        }
        
        test(name: "zip", intro: "将两个/多个 Publishers 的值组合成元组发送") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .zip([20, 15, 10, 5].publisher)
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addErrorHanding() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "error handing", detail: "错误处理", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "assertNoFailure", intro: "当上游 Publisher 失败，抛出异常") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .assertNoFailure()
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        test(name: "catch", intro: "处理上游 Publisher 的错误：用新的 Publisher 发送") {
            let subject = CurrentValueSubject<String, Error>("🍌")
            let cancelable = subject.catch({ error in
                Just("🍊")
            }).sink(receiveCompletion: {
                print ("completion: \($0)")
            }, receiveValue: {
                print ("value: \($0).")
            })
            subject.send(completion: .failure(CustomError.test))
            cancelable.cancel()
        }
        
        test(name: "retry", intro: "收到失败时重试") {
            let subject = CurrentValueSubject<String, Error>("🍌")
            let cancelable = subject.retry(2).sink(receiveCompletion: {
                print ("completion: \($0)")
            }, receiveValue: {
                print ("value: \($0).")
            })
            subject.send(completion: .failure(CustomError.test))
            cancelable.cancel()
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addTiming() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "timing", detail: "时间控制", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "measureTimeInterval", intro: "测量发送事件之间的时间间隔") {
            let cancellable = Timer.publish(every: 1, on: .main, in: .default)
                .autoconnect()
                .measureInterval(using: RunLoop.main)
                .sink { print("\($0)", terminator: "\n") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                cancellable.cancel()
            }
        }
        
        test(name: "debounce", intro: "事件间时间间隔达到特定时间才发送") {
            let bounces:[(Int,TimeInterval)] = [
                (0, 0),
                (1, 0.25),  // 0.25s interval since last index
                (2, 1),     // 0.75s interval since last index
                (3, 1.25),  // 0.25s interval since last index
                (4, 1.5),   // 0.25s interval since last index
                (5, 2)      // 0.5s interval since last index
            ]
            
            let subject = PassthroughSubject<Int, Never>()
            let cancellable = subject
                .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                .sink { index in
                    print ("Received index \(index)")
                }
            
            for bounce in bounces {
                DispatchQueue.main.asyncAfter(deadline: .now() + bounce.1) {
                    subject.send(bounce.0)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                cancellable.cancel()
            }
        }
        
        test(name: "delay", intro: "延迟一定时间发送") {
            let subject = PassthroughSubject<String, Never>()
            let cancellable = subject
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .sink { value in
                    print ("Received value \(value)")
                }
            ["🍌", "🍎", "🍐"].forEach { fruit in
                subject.send(fruit)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                cancellable.cancel()
            }
        }
        
        test(name: "throttle", intro: "只发送第一个元素和规定时间内的最后一个元素") {
            let cancellable = Timer.publish(every: 3.0, on: .main, in: .default)
                .autoconnect()
                .print("\(Date().description)")
                .throttle(for: 10.0, scheduler: RunLoop.main, latest: true)
                .sink(
                    receiveCompletion: { print ("Completion: \($0).") },
                    receiveValue: { print("Received Timestamp \($0).") }
                )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                cancellable.cancel()
            }
        }
        
        test(name: "timeout", intro: "如果规定时间内未发出值，则终止") {
            let cancellable = ["🍌", "🍎", "🍐"].publisher
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .timeout(.seconds(2), scheduler: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { fruit in
                    print(fruit)
                })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                cancellable.cancel()
            }
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
    func addOthers() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(title: "others", detail: "其他", action: nil)
        sectionSnapshot.append([headerItem])
        
        func test(name: String, intro: String?, action: @escaping () -> Void) {
            let item = Item(title: name, detail: intro, action: action)
            sectionSnapshot.append([item])
        }
        
        test(name: "encode/decode", intro: "") {
            struct Article: Codable {
                let title: String
                let author: String
                let pubDate: Date
            }
            
            let dataProvider = PassthroughSubject<Article, Never>()
            let cancellable = dataProvider
                .encode(encoder: JSONEncoder())
                .sink(receiveCompletion: {
                    print ("Completion: \($0)")
                }, receiveValue: {  data in
                    guard let stringRepresentation = String(data: data, encoding: .utf8) else { return }
                    print("Data received \(data) string representation: \(stringRepresentation)")
                })
            
            dataProvider.send(Article(title: "My First Article", author: "Gita Kumar", pubDate: Date()))
            
            cancellable.cancel()
        }
        
        test(name: "switchToLatest", intro: "") {            
            let fruits = ["🍌", "🍊", "🍐"]
            var index = 0
            
            func getFruit() -> AnyPublisher<String, Never> {
                return Future<String, Never> { promise in
                    //simulate delay for download
                    DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                        promise(.success(fruits[index % fruits.count]))
                    }
                }.map { $0 }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
            }
            
            let taps = PassthroughSubject<Void, Never>()
            
            taps.map { _ in getFruit() }
                .switchToLatest()
                .sink {
                    print($0)
                }
                .store(in: &self.cancels)
            
            //get 🍊
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                index += 1
                taps.send()
            }
            
            //get 🍐
            // overwrites the 🍊 due to switch to latest
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                index += 1
                taps.send()
            }
        }
        
        test(name: "share", intro: "分享上游 Publisher 的值，供多个 Subscriber 订阅") {
            let pub = ["🍌", "🍎", "🍐"].publisher
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .share()
            
            let cancellable1 = pub.sink { fruit in
                print("stream1 receive \(fruit)")
            }
            
            let cancellable2 = pub.sink { fruit in
                print("stream2 receive \(fruit)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                cancellable1.cancel()
                cancellable2.cancel()
            }
        }
        
        test(name: "breakpoint/breakpointOnError", intro: "") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .breakpoint(receiveSubscription: nil) { fruit in
                    fruit == "🍎"
                }
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        test(name: "handleEvents", intro: "") {
            _ = ["🍌", "🍎", "🍐"].publisher
                .handleEvents(receiveSubscription: { subscription in
                    print("handle subscription \(subscription)")
                }, receiveOutput: { fruit in
                    print("handle value \(fruit)")
                }, receiveCompletion: { completion in
                    print("handle completion \(completion)")
                }, receiveCancel: {
                    print("handle cancel")
                }, receiveRequest: { demand in
                    print("handle demand \(demand)")
                })
                .sink(receiveValue: { fruit in
                    print(fruit)
                })
        }
        
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: headerItem.title)
    }
    
}

//--------------------------------------------------------------------------------
// MARK: - Layout
//--------------------------------------------------------------------------------

extension OperatorViewController {
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.headerMode = .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
}

extension OperatorViewController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        collectionView.delegate = self
    }
    
    private func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var content = UIListContentConfiguration.valueCell()
            content.text = item.title
            content.secondaryText = item.detail
            content.textProperties.color = .gray
            content.textProperties.transform = .uppercase
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure()]
        }
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
            (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.secondaryText = item.detail
            content.secondaryTextProperties.color = .lightGray
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }
        
        dataSource = UICollectionViewDiffableDataSource<String, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            if indexPath.item == 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
    }
}

extension OperatorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        if let item = dataSource.itemIdentifier(for: indexPath) {
            print("----------- \(item.title) -----------")
            item.action?()
        }
    }
}

// MARK: Helper

enum OriginError: Error {
    case test(String)
}
