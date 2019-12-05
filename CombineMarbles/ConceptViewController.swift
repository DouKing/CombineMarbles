//
// CombineMarbles
// ViewController.swift
//
// Created by wuyikai on 2019/10/13.
// Copyright © 2019 wuyikai. All rights reserved.
// 

import UIKit
import Combine

class ConceptViewController: UITableViewController {
    
    //--------------------------------------------------------------------------------
    // MARK: - Property
    //--------------------------------------------------------------------------------

    var subscrition: AnyCancellable?
    var cellId: String {
        return "CELLID"
    }
    var name: String = "" {
        didSet {
            print("VC's name is \(name)")
        }
    }
    
    var dataSource: [ConceptDataSource] = []
    
    //--------------------------------------------------------------------------------
    // MARK: - Life cycle
    //--------------------------------------------------------------------------------

    deinit {
        //也可以不用写，因为 `AnyCancellable` 在释放时，会自动调用 cancel
        self.subscrition?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        self.tableView.tableHeaderView = searchBar
        self.addDataSource()
        self.tableView.reloadData()
    }

    //--------------------------------------------------------------------------------
    // MARK: - Table view delegate & data source
    //--------------------------------------------------------------------------------
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource[section].list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELLID", for: indexPath)
        let model = self.dataSource[indexPath.section].list[indexPath.row]
        cell.textLabel?.text = model.name
        cell.detailTextLabel?.text = model.desc
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataSource[section].title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.dataSource[indexPath.section].list[indexPath.row]
        self.test(name: model.name, handler: model.action)
    }
}

// MARK: -

extension ConceptViewController {
    func addDataSource() {
        self.addPublisher()
        self.addSubscriber()
        self.addSubject()
        self.addCancellable()
    }
    
    //--------------------------------------------------------------------------------
    // MARK: - Publisher
    //--------------------------------------------------------------------------------

    func addPublisher() {
        var list: [ConceptModel] = []
        func addTest(name: String, intro: String? = nil, action: @escaping Action) {
            list.append(ConceptModel(name: name, desc: intro, action: action))
        }
        
        addTest(name: "NotificationCenter") {
            self.subscrition = NotificationCenter
                .default.publisher(for: UITextField.textDidChangeNotification)
                .map({ (note: Notification) -> String in
                    return (note.object as! UITextField).text ?? ""
                })
                .sink { (text: String) in
                    print(text)
            }
            print("在输入框输入值...")
        }
        
        addTest(name: "Just", intro: "发送一个值, 立即结束") {
            _ = Just("🍌").sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
                print(completion)
            }) { (element: String) in
                print(element)
            }
            
            //_ = Just("test name").assign(to: \.name, on: self)
            let subscriber = Subscribers.Assign(object: self, keyPath: \.name)
            Just("testName").subscribe(subscriber)
        }
        
        addTest(name: "Empty", intro: "不提供新值, 立即结束") {
            _ = Empty<String, Never>(completeImmediately: true).sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
                print(completion)
            }, receiveValue: { (element: String) in
                print(element)
            }) as AnyCancellable
        }
        
        addTest(name: "Deferred", intro: "直到订阅时才发布元素") {
            let deferred: Deferred<Just> = Deferred {
                return Just("🍐")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("Deferred 2 秒后")
                _ = deferred.sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
                    print(completion)
                }) { (element: String) in
                    print(element)
                }
            }
            
//            _ = Just("a").delay(for: 2, scheduler: DispatchQueue.main).sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
//                print(completion)
//            }) { (element: String) in
//                print("Deferred 2 秒后")
//                print(element)
//            }
        }
        
        addTest(name: "Fail", intro: "发送一个值, 立即失败") {
            _ = Fail(error: CustomError.test).sink(receiveCompletion: { (completion: Subscribers.Completion<CustomError>) in
                print(completion)
            }, receiveValue: { (element: String) in
                print(element)
            })
        }
        
        addTest(name: "Sequence", intro: "将给定序列按序发布") {
            _ = Publishers.Sequence<[String], Never>(sequence: ["🍌", "🍎", "🍐"]).sink(receiveCompletion: { (completion) in
                print(completion)
            }, receiveValue: { (element: String) in
                print(element)
            })
        }
        
        addTest(name: "Future", intro: "可用于异步操作, 如: 网络请求") {
            let publisher = Future<String, CustomError>({ (promise: @escaping (Result<String, CustomError>) -> Void) in
                DispatchQueue.global().async {
                    print("networking...")
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                        promise(.success("network result"))
                    }
                }
            })
            self.subscrition = publisher.sink(receiveCompletion: { (completion: Subscribers.Completion<CustomError>) in
                print(completion)
            }, receiveValue: { (result: String) in
                print(result)
            })
        }
        
        addTest(name: "AnyPublisher", intro: "类型擦除的发布者") {
            //通用类型，任何 Publisher 都可以转化成 AnyPublisher
            let publisher = Just("AnyPublisher").eraseToAnyPublisher()
            _ = publisher.sink { (value) in
                print(value)
            }
        }
        
        dataSource.append(ConceptDataSource(title: "Publisher", list: list))
    }
    
    //--------------------------------------------------------------------------------
    // MARK: - Subscriber
    //--------------------------------------------------------------------------------

    func addSubscriber() {
        var list: [ConceptModel] = []
        func addTest(name: String, intro: String? = nil, action: @escaping Action) {
            list.append(ConceptModel(name: name, desc: intro, action: action))
        }
        addTest(name: "Sink", intro: "通用的订阅者") {
            let just: Just<String> = Just("🍌")
            let observer: Subscribers.Sink<String, Never> = Subscribers.Sink(receiveCompletion: { (completion) in
                print(completion)
            }, receiveValue: { value in
                print(value)
            })
            just.subscribe(observer)
        }
        addTest(name: "Assign", intro: "将收到的值赋给制定对象的 keypath") {
            let just: Just<String> = Just("🍐")
            let observer = Subscribers.Assign(object: self, keyPath: \.name)
            just.subscribe(observer)
        }
        addTest(name: "AnySubscriber", intro: "类型擦除的订阅者") {
            let publiser: CurrentValueSubject<String, Never> = CurrentValueSubject("初始值")
            let subscriber = AnySubscriber<String, Never>(receiveSubscription: { (subscription: Subscription) in
                print("Receive subscription: \(subscription)")//订阅成功
                subscription.request(.unlimited)
            }, receiveValue: { (input: String) -> Subscribers.Demand in
                print("Received input: \(input)")
                return .unlimited
            }) { (completion: Subscribers.Completion<Never>) in
                print("Completed with \(completion)")
            }
            print("订阅")
            publiser.subscribe(subscriber)
            publiser.send("🍌")
            publiser.send("🍎")
            publiser.send("🍐")
        }
        dataSource.append(ConceptDataSource(title: "Subscriber", list: list))
    }
    
    //--------------------------------------------------------------------------------
    // MARK: - Subject
    //--------------------------------------------------------------------------------

    func addSubject() {
        // Subject 既可以作为 Publisher，也可以作为 Subscriber，通常用作中间代理
        var list: [ConceptModel] = []
        func addTest(name: String, intro: String? = nil, action: @escaping Action) {
            list.append(ConceptModel(name: name, desc: intro, action: action))
        }
        addTest(name: "CurrentValueSubject", intro: "会保留一个值, 当值更新时, 发送该值") {
            //保留一个值, 当值变化时会发送该值
            let subject: CurrentValueSubject<String, Never> = CurrentValueSubject("🍇")
            let subscriber = Subscribers.Assign(object: self, keyPath: \.name)
            subject.subscribe(subscriber)
            subject.send("🍌")
            subject.send("🍎")
            subject.send("🍐")
            
            let publisher = Publishers.Sequence<[String], Never>(sequence: ["🏃", "🚶", "🏊‍♀️"])
            _ = publisher.subscribe(subject)
            
            subject.send(completion: .finished)
            print("current value is \(subject.value)")
        }
        addTest(name: "PassthroughSubject", intro: "不保留值, 当收到值时, 发送该值") {
            //没有初始值,也不保存值,当值变化时会发送该值
            let subject: PassthroughSubject<String, Never> = PassthroughSubject()
            let subscriber = Subscribers.Assign(object: self, keyPath: \.name)
            subject.subscribe(subscriber)
            subject.send("🍌")
            subject.send("🍎")
            subject.send("🍐")
            
            let publisher = Publishers.Sequence<[String], Never>(sequence: ["🏃", "🚶", "🏊‍♀️"])
            _ = publisher.subscribe(subject)
            
            subject.send(completion: .finished)
        }
        addTest(name: "AnySubject") {
            // Swift 正式版本已没有该类型了
        }
        dataSource.append(ConceptDataSource(title: "Subject", list: list))
    }
    
    //--------------------------------------------------------------------------------
    // MARK: - Cancellable
    //--------------------------------------------------------------------------------

    func addCancellable() {
        var list: [ConceptModel] = []
        list.append(ConceptModel(name: "AnyCancellable", action: {
            // 实现了`Cancellable`协议
            let cancellable = AnyCancellable {
                self.subscrition?.cancel()
            }
            print("取消了通知订阅,在输入框输入文字试试...")
            cancellable.cancel()
        }))
        dataSource.append(ConceptDataSource(title: "Cancellable", list: list))
    }
}

//--------------------------------------------------------------------------------
// MARK: - Helper -
//--------------------------------------------------------------------------------

enum CustomError: Swift.Error {
    case test
}

extension ConceptViewController {
    func test(name: String, handler: Action) {
        print("----------- \(name) -----------")
        handler()
    }
}
