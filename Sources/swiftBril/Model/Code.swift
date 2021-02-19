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

// convenience properties

extension Code {
    var arguments: [String] {
        guard case .instruction(let instruction) = self else {
            return []
        }

        switch instruction {
            case .const: return []
            case .value(let op): return op.arguments
            case .effect(let op): return op.arguments
        }
    }
}

extension Code {
    var functions: [String] {
        guard case .instruction(let instruction) = self else {
            return []
        }

        switch instruction {
            case .const: return []
            case .value(let op): return op.functions
            case .effect(let op): return op.functions
        }
    }
}

extension Code {
    var labels: [String] {
        guard case .instruction(let instruction) = self else {
            return []
        }

        switch instruction {
            case .const: return []
            case .value(let op): return op.labels
            case .effect(let op): return op.labels
        }
    }
}

extension Code {
    var destination: String? {
        guard case .instruction(let instruction) = self else {
            return nil
        }

        switch instruction {
            case .const(let op): return op.destination
            case .value(let op): return op.destination
            case .effect: return nil
        }
    }
}
