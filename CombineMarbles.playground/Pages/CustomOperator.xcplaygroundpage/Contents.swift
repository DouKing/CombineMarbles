//: [Previous](@previous)

import Combine

extension Publisher {
    public func asyncTryMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
    
    public func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }
}

let cancel = [1, 2, 3, 4]
    .publisher
    .asyncMap { value in
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "element \(value)"
    }
    .sink { value in
        print(value)
    }

//: [Next](@next)
