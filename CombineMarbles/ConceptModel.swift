//
//  ConceptModel.swift
//  CombineMarbles
//
//  Created by DouKing on 2019/12/5.
//  Copyright © 2019 douking. All rights reserved.
//

import Foundation

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
