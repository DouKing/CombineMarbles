//
//  ViewController.swift
//  CombineDemo
//
//  Created by DouKing on 2019/10/15.
//

import UIKit
import Combine

enum CustomError: Swift.Error {
    case test
}


class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var actions: [[String: Any]] = []

    var subscrition: AnyCancellable?
    var name: String = "" {
        didSet {
            print("VC's name is \(name)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addTests()
        tableView.reloadData()
    }

    func test(name: String, handler: () -> Void) {
        print("----------- \(name) -----------")
        handler()
    }

    func addTest(name: String, action: @escaping () -> Void) {
        actions.append([
            "name": name,
            "action": action
        ])
    }

    func printcompletion(completion: Subscribers.Completion<CustomError>) {
        switch completion {
            case .finished:
                print("finish")
            case .failure(let error):
                print("failure: \(error)")
        }
    }

    func printcompletion(completion: Subscribers.Completion<Never>) {
        switch completion {
            case .finished:
                print("finish")
            case .failure(let error):
                print("failure: \(error)")
        }
    }
}

extension ViewController {
    func addTests() {
        addTest(name: "Just") {
            _ = Just("one").sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
                self.printcompletion(completion: completion)
            }) { (element: String) in
                print(element)
            }

            //_ = Just("test name").assign(to: \.name, on: self)
            let subscriber = Subscribers.Assign(object: self, keyPath: \.name)
            Just("testName").subscribe(subscriber)
        }

        addTest(name: "Empty") {
            _ = Empty<String, Never>(completeImmediately: true).sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
                self.printcompletion(completion: completion)
            }, receiveValue: { (element: String) in
                print(element)
            }) as AnyCancellable
        }

        addTest(name: "Deferred") {//直到订阅时才发布元素
            let deferred: Deferred<Just> = Deferred {
                return Just("a")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("Deferred 2 秒后")
                _ = deferred.sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
                    self.printcompletion(completion: completion)
                }) { (element: String) in
                    print(element)
                }
            }

//            _ = Just("a").delay(for: 2, scheduler: DispatchQueue.main).sink(receiveCompletion: { (completion: Subscribers.Completion<Never>) in
//                self.printcompletion(completion: completion)
//            }) { (element: String) in
//                print("Deferred 2 秒后")
//                print(element)
//            }
        }

        addTest(name: "Fail") {
            _ = Fail(error: CustomError.test).sink(receiveCompletion: { (completion: Subscribers.Completion<CustomError>) in
                self.printcompletion(completion: completion)
            }, receiveValue: { (element: String) in
                print(element)
            })
        }

        addTest(name: "Sequence") {
            _ = Publishers.Sequence<[String], Never>(sequence: ["🍌", "🍎", "🍐"]).sink(receiveCompletion: { (completion) in
                self.printcompletion(completion: completion)
            }, receiveValue: { (element: String) in
                print(element)
            })
        }

        addTest(name: "Future") {
            let publisher = Future<String, CustomError>({ (promise: @escaping (Result<String, CustomError>) -> Void) in
                DispatchQueue.global().async {
                    print("networking...")
                    DispatchQueue.main.async {
                        promise(.success("network result"))
                    }
                }
            })
            self.subscrition = publisher.sink(receiveCompletion: { (completion: Subscribers.Completion<CustomError>) in
                self.printcompletion(completion: completion)
            }, receiveValue: { (result: String) in
                print(result)
            })
        }

        addTest(name: "Subject") {
            // subject 既可以作为 Publisher,也可以作为 Subscriber
            let subject: PassthroughSubject<String, Never> = PassthroughSubject() //没有初始值,也不保存值,当值变化时会发送该值
            let subscriber = Subscribers.Assign(object: self, keyPath: \.name)
            subject.subscribe(subscriber)
            subject.send("🍌")
            subject.send("🍎")
            subject.send("🍐")

            let publisher = Publishers.Sequence<[String], Never>(sequence: ["A", "B", "C"])
            _ = publisher.subscribe(subject)

            subject.send(completion: .finished)
        }
    }

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELLID", for: indexPath)
        cell.textLabel?.text = actions[indexPath.row]["name"] as? String
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let info = actions[indexPath.row]
        let name = info["name"] as! String
        let action = info["action"] as! () -> Void
        test(name: name, handler: action)
    }
}
