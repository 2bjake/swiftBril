//
//  Function.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

struct Function {
    var name: String
    @DefaultDecodable var arguments: [Argument]
    var type: Type?
    var code: [Code]
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
    var description: String {
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
