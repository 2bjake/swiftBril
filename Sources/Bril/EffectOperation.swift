//
//  EffectOperation.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

public struct EffectOperation {
    public enum OpType: String {
        case jmp
        case br
        case call
        case ret
        case print
        case nop
    }
    public let opType: OpType
    public var arguments: [String]
    public let functions: [String]
    public let labels: [String]
}

extension EffectOperation {
    public var name: String { opType.rawValue }
}
