//
//  ConstantPropagation.swift
//
//
//  Created by Jake Foster on 2/26/21.
//

enum ConstantPropagation: Equatable {
    case constant(Literal)
    case nonConstant
}

extension ConstantPropagation {
    var constant: Literal? {
        guard case .constant(let value) = self else { return nil }
        return value
    }

    var isConstant: Bool {
        constant != nil
    }
}

extension ConstantPropagation: CustomStringConvertible {
    var description: String {
        switch self {
            case .constant(let value): return "\(value)"
            case .nonConstant: return "?"
        }
    }
}

extension DataFlowAnalyzer {
    private static func merge(values: [[String: ConstantPropagation]]) -> [String: ConstantPropagation] {
        var result = [String: ConstantPropagation]()
        for dict in values {
            for (key, value) in dict {
                if !value.isConstant {
                    result[key] = .nonConstant
                } else if let prevValue = result[key] {
                    if prevValue != value {
                        result[key] = .nonConstant
                    }
                } else {
                    result[key] = value
                }
            }
        }
        return result
    }

    private static func transfer(block: ArraySlice<Code>, values: [String: ConstantPropagation]) -> [String: ConstantPropagation] {
        block.reduce(into: values) { result, line in
            switch line {
                case .instruction(.const(let const)):
                    result[const.destination] = .constant(const.value)
                case .instruction(.value(let value)):
                    result[value.destination] = .nonConstant
                default:
                    break
            }
        }
    }

    static func runConstantPropagationAnalysis(function: Function) -> Results<Dictionary<String, ConstantPropagation>> {
        runAnalysis(function: function,
                    runForward: true,
                    initializer: Dictionary.init,
                    merge: merge,
                    transfer: transfer)
    }
}
