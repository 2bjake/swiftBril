//
//  EffectOperation.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

struct EffectOperation {
    enum OpType: String {
        case jmp
        case br
        case call
        case ret
        case print
        case nop
    }
    let opType: OpType
    var arguments: [String]
    let functions: [String]
    let labels: [String]
}

extension EffectOperation {
    var name: String { opType.rawValue }
}
