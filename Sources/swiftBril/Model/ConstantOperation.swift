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

extension Literal {
    var int: Int? {
        switch self {
            case .bool: return nil
            case .int(let int): return int
        }
    }

    var bool: Bool? {
        switch self {
            case .bool(let bool): return bool
            case .int: return nil
        }
    }
}

extension Literal: Hashable { }

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
    var destination: String
    let type: Type
    let value: Literal
}
