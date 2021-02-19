//
//  ValueOperation.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

struct ValueOperation {
    enum OpType: String {
        case add
        case call
    }
    let opType: OpType
    let destination: String
    let type: Type
    let arguments: [String]
    let functions: [String]
    let labels: [String]
}

extension ValueOperation {
    var name: String { opType.rawValue }
}
