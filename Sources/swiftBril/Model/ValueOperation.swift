//
//  ValueOperation.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

struct ValueOperation {
    enum OpType: String {
        case add
        case sub
        case mul
        case div
        case eq
        case lt
        case gt
        case le
        case ge
        case not
        case and
        case or
        case call
        case id
    }
    let opType: OpType
    var destination: String
    let type: Type
    var arguments: [String]
    let functions: [String]
    let labels: [String]
}

extension ValueOperation {
    var name: String { opType.rawValue }
}
