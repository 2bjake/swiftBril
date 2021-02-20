//
//  RemoveRedundantAssignments.swift
//
//
//  Created by Jake Foster on 2/20/21.
//

private extension Array {
    mutating func removeAll(at indicies: [Int]) {
        for index in indicies.sorted(by: >) {
            remove(at: index)
        }
    }
}

private extension Code {
    var isBlockTerminator: Bool {
        switch self {
            case .label:
                return true
            case .instruction(.effect(let op)):
                return [.jmp, .br, .ret].contains(op.opType)
            default:
                return false
        }
    }
}

private extension Function {
    var blocks: [ArraySlice<Code>] {
        var result = [ArraySlice<Code>]()

        func appendSlice(range: ClosedRange<Int>) {
            var slice = code[range]
            if case .label = slice.last {
                slice = slice.dropLast()
            }
            if !slice.isEmpty {
                result.append(slice)
            }
        }

        var blockStart = 0
        for i in 0..<code.count {
            if code[i].isBlockTerminator {
                appendSlice(range: blockStart...i)
                blockStart = i + 1
            }
        }

        if blockStart < code.count {
            appendSlice(range: blockStart...(code.count - 1))
        }

        return result
    }
}

extension Optimizations {
    private static func findRedundantAssignmentIndiciesSinglePass(_ function: Function) -> [Int] {
        var deleteIndicies = [Int]()
        for block in function.blocks {
            var lastDef = [String: Int]()
            for i in block.startIndex..<block.endIndex {
                block[i].arguments.forEach {
                    lastDef[$0] = nil
                }

                if let dest = block[i].destination {
                    if let unusedIdx = lastDef[dest] {
                        deleteIndicies.append(unusedIdx)
                    }
                    lastDef[dest] = i
                }
            }
        }
        return deleteIndicies
    }

    /// Remove (side-effect-free) assignments to variables that are reassigned before being read
    static func removeRedundantAssignments(_ function: Function) -> Function {
        var function = function
        var deleteIndicies = findRedundantAssignmentIndiciesSinglePass(function)
        while !deleteIndicies.isEmpty {
            function.code.removeAll(at: deleteIndicies)
            deleteIndicies = findRedundantAssignmentIndiciesSinglePass(function)
        }
        return function
    }

//    static func removeRedundantAssignments(_ program: Program) -> Program {
//        var program = program
//        for i in 0..<program.functions.count {
//            program.functions[i] = removeRedundantAssignments(program.functions[i])
//        }
//        return program
//    }
}
