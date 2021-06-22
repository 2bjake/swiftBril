//
//  Function.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

public struct Function {
    public var name: String
    @DefaultDecodable public var arguments: [Argument]
    public var type: Type?
    public var code: [Code]
}

extension Function: Decodable {
    enum CodingKeys: String, CodingKey {
        case name
        case arguments = "args"
        case type
        case code = "instrs"
    }
}

extension Function: CustomStringConvertible {
    public var description: String {
        var val = "@\(name)"

        if !arguments.isEmpty {
            val += "(" + arguments.map(String.init).joined(separator: ", ") + ")"
        }

        if let type = type {
            val += ": \(type)"
        }
        val += " {\n" + code.map(String.init).joined(separator: "\n") + "\n}"

        return val
    }
}
