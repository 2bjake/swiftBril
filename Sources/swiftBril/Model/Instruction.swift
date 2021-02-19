//
//  Instruction.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

enum Instruction: String {
    case const
    case jmp
    case print
    case call
    case add
    case ret
}

extension Instruction: Decodable {

    enum CodingKeys: CodingKey {
        case op
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let op = try? container.decodeIfPresent(String.self, forKey: .op) else {
            throw BrilParseError(message: "Instruction did not contain 'op' key")
        }

        switch op {
            case "const": self = .const
            case "jmp": self = .jmp
            case "print": self = .print
            case "call": self = .call
            case "add": self = .add
            case "ret": self = .ret
            default: throw BrilParseError(message: "unknown op '\(op)'")
        }
    }
}

extension Instruction: CustomStringConvertible {
    var description: String { rawValue }
}
