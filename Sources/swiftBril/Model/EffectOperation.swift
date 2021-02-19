//
//  EffectOperation.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

struct EffectOperation {
    enum OpType: String {
        case jmp
        case print
        case ret
    }
    let opType: OpType
    let arguments: [String]
    let functions: [String]
    let labels: [String]
}

extension EffectOperation {
    var name: String { opType.rawValue }
}
