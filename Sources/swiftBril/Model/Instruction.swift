//
//  Instruction.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

enum Instruction {
    case const(ConstantOperation)
    case value(ValueOperation)
    case effect(EffectOperation)
}

extension Instruction: Decodable {
    enum CodingKeys: CodingKey {
        case op
        case dest
        case type
        case args
        case funcs
        case labels
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let opStr = try? container.decodeIfPresent(String.self, forKey: .op) else {
            throw BrilParseError(message: "Instruction did not contain 'op' key")
        }
        let dest = try? container.decodeIfPresent(String.self, forKey: .dest)
        let type = try? container.decodeIfPresent(Type.self, forKey: .type)
        let args = (try? container.decodeIfPresent([String].self, forKey: .args)) ?? []
        let funcs = (try? container.decodeIfPresent([String].self, forKey: .funcs)) ?? []
        let labels = (try? container.decodeIfPresent([String].self, forKey: .labels)) ?? []

        if opStr == ConstantOperation.opName {
            guard let dest = dest else {
                throw BrilParseError(message: "'\(opStr)' field 'dest' is missing")
            }

            guard let type = type else {
                throw BrilParseError(message: "'\(opStr)' field 'type' is missing")
            }

            let literal: Literal
            if let literalBool = try? container.decodeIfPresent(Bool.self, forKey: .value) {
                literal = .bool(literalBool)
            } else if let literalInt = try? container.decodeIfPresent(Int.self, forKey: .value) {
                literal = .int(literalInt)
            } else {
                throw BrilParseError(message: "const field 'value' is missing or is not a valid type")
            }
            self = .const(ConstantOperation(destination: dest, type: type, value: literal))
        } else if let valueOp = ValueOperation.OpType(rawValue: opStr) {
            guard let dest = dest else {
                throw BrilParseError(message: "'\(opStr)' field 'dest' is missing")
            }

            guard let type = type else {
                throw BrilParseError(message: "'\(opStr)' field 'type' is missing")
            }
            self = .value(ValueOperation(opType: valueOp, destination: dest, type: type, arguments: args, functions: funcs, labels: labels))
        } else if let effectOp = EffectOperation.OpType(rawValue: opStr) {
            self = .effect(EffectOperation(opType: effectOp, arguments: args, functions: funcs, labels: labels))
        } else {
            throw BrilParseError(message: "unknown op '\(opStr)'")
        }
    }
}

extension Instruction: CustomStringConvertible {
    private func appendToDescription(_ description: String, functions: [String], arguments: [String], labels: [String]) -> String {
        description +
            functions.map { " @\($0)" }.joined() +
            arguments.map { " \($0)" }.joined() +
            labels.map { " .\($0)" }.joined() +
            ";"
    }

    var description: String {
        switch self {
            case .const(let op):
                return "\(op.destination): \(op.type) = \(op.name) \(op.value);"
            case .value(let op):
                let description = "\(op.destination): \(op.type) = \(op.name)"
                return appendToDescription(description, functions: op.functions, arguments: op.arguments, labels: op.labels)
            case .effect(let op):
                return appendToDescription(op.name, functions: op.functions, arguments: op.arguments, labels: op.labels)
        }
    }
}
