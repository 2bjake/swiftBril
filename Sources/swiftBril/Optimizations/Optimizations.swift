//
//  Optimizations.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

enum Optimizations { }

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

extension Function {
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
        for i in code.indices {
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

extension Program {
    mutating func optimize() -> Self {
        functions = functions
            .map(Optimizations.removeUnusedLabels)
            .map(Optimizations.lvnRewrite)
            .map(Optimizations.removeUnusedAssignments)
            .map(Optimizations.removeRedundantAssignments)
        return self
    }
}
