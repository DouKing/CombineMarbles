//
//  ConceptModel.swift
//  CombineMarbles
//
//  Created by DouKing on 2019/12/5.
//  Copyright © 2019 douking. All rights reserved.
//

import Foundation
import Combine

typealias Action = () -> Void

struct ConceptModel {
    var name: String
    var desc: String?
    var action: Action
}

struct ConceptDataSource {
    var title: String
    var list: [ConceptModel]
}

extension Subscribers.Completion: CustomStringConvertible {
    public var description: String {
        switch self {
            case .finished:
                return "finish"
            case .failure(let error):
                return "failure: \(error)"
        }
    }
}
