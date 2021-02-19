//
//  ConstantOperation.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

enum Literal {
    case bool(Bool)
    case int(Int)
}

extension Literal: CustomStringConvertible {
    var description: String {
        switch self {
            case .bool(let value): return "\(value)"
            case .int(let value): return "\(value)"
        }
    }
}

struct ConstantOperation {
    static let opName = "const"

    let name = opName
    let destination: String
    let type: Type
    let value: Literal
}

