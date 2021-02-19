//
//  Code.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

enum Code {
    case label(String)
    case instruction(Instruction)
}

extension Code: Decodable {
    enum CodingKeys: CodingKey {
        case label
        case op
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let label = try container.decodeIfPresent(String.self, forKey: .label) {
            self = .label(label)
        } else if container.contains(.op) {
            self = .instruction(try Instruction(from: decoder))
        } else {
            throw BrilParseError(message: "instr entry did not contain 'label' or 'op' field")
        }
    }
}

extension Code: CustomStringConvertible {
    var description: String {
        switch self {
            case .label(let label):
                return ".\(label)"
            case .instruction(let instruction):
                return "  \(instruction)"
        }
    }
}
