//
//  LocalValueNumbering.swift
//
//
//  Created by Jake Foster on 2/20/21.
//

private extension Code {
    static func makeId(_ variable: String, from original: ValueOperation) -> Code {
        return .instruction(.value(ValueOperation(opType: .id, destination: original.destination, type: original.type, arguments: [variable], functions: [], labels: [])))
    }

    static func makeConstant(_ constant: Literal, from original: ValueOperation) -> Code {
        return .instruction(.const(.init(destination: original.destination, type: original.type, value: constant)))
    }

    mutating func replaceArgsWith(_ args: [String]) {
        switch self {
            case .instruction(.value(var op)):
                op.arguments = args
                self = .instruction(.value(op))
            case .instruction(.effect(var op)):
                op.arguments = args
                self = .instruction(.effect(op))
            default: break
        }
    }
}

private extension ValueTable.Value {
    init(_ opType: ValueOperation.OpType, argNumbers: [Int]) {
        var argNumbers = argNumbers
        if opType == .add || opType == .mul {
            argNumbers.sort()
        }
        self = .value(op: opType.rawValue, valueNums: argNumbers)
    }
}

private extension ValueOperation.OpType {
    var binaryFoldOperator: ((Literal, Literal) -> Literal)? {
        switch self {
            case .add: return { .int($0.int! + $1.int!) }
            case .sub: return { .int($0.int! - $1.int!) }
            case .mul: return { .int($0.int! * $1.int!) }
            case .div: return { .int($0.int! / $1.int!) }
            case .eq: return { .bool($0.int! == $1.int!) }
            case .lt: return { .bool($0.int! < $1.int!) }
            case .gt: return { .bool($0.int! > $1.int!) }
            case .le: return { .bool($0.int! <= $1.int!) }
            case .ge: return { .bool($0.int! >= $1.int!) }
            case .and: return { .bool($0.bool! && $1.bool!) }
            case .or: return { .bool($0.bool! || $1.bool!) }
            default: return nil
        }
    }

    var unaryFoldOperator: ((Literal) -> Literal)? {
        guard self == .not else { return nil }
        return { .bool(!$0.bool!) }
    }
}

extension Optimizations {
    private static func fold(op: ValueOperation, table: ValueTable, varToNum: [String: Int]) -> Literal? {
        let constants: [Literal] = op.arguments.compactMap {
            guard case .constant(let constant) = table.entryForNumber(varToNum[$0]!).value else {
                return nil
            }
            return constant
        }

        if constants.count == 1 {
            return op.opType.unaryFoldOperator?(constants[0])
        } else if constants.count == 2 {
            return op.opType.binaryFoldOperator?(constants[0], constants[1])
        }
        return nil
    }

    static func lvnRewrite(function: Function) -> Function {
        var function = function
        for block in function.blocks {
            var table = ValueTable()
            var varToNum = [String: Int]()
            for i in block.indices {
                if case .instruction(.const(let op)) = block[i] {
                    let value = ValueTable.Value.constant(op.value)
                    let entry = table.entryForValue(value) ?? table.insert(value: value, variableName: op.destination)
                    varToNum[op.destination] = entry.number
                } else if case .instruction(.value(let op)) = block[i], op.opType != .call {
                    var value: ValueTable.Value
                    if op.opType == .id, let variableName = op.arguments.first, let num = varToNum[variableName] {
                        value = table.entryForNumber(num).value
                    } else {
                        value = ValueTable.Value(op.opType, argNumbers: block[i].arguments.map {
                            if varToNum[$0] == nil {
                                let num = table.insertIdentity(variableName: $0)
                                varToNum[$0] = num
                            }
                            return varToNum[$0]!
                        })
                    }

                    if let entry = table.entryForValue(value) {
                        switch entry.value {
                            case .constant(let constant):
                                function.code[i] = .makeConstant(constant, from: op)
                            case .value:
                                function.code[i] = .makeId(entry.variableName, from: op)
                        }
                        varToNum[op.destination] = entry.number
                    } else {
                        // it's a new value. can we constant fold before saving it?
                        if let foldConstant = fold(op: op, table: table, varToNum: varToNum) {
                            function.code[i] = .makeConstant(foldConstant, from: op)
                            value = ValueTable.Value.constant(foldConstant)
                        }

                        let entry = table.insert(value: value, variableName: op.destination)
                        varToNum[op.destination] = entry.number
                    }
                }

                if let args = function.code[i].operation?.arguments, !args.isEmpty {
                    let newArgs: [String] = args.map {
                        guard let num = varToNum[$0] else { return $0 }
                        return table.entryForNumber(num).variableName
                    }
                    function.code[i].replaceArgsWith(newArgs)
                }
            }

        }
        return function
    }
}
