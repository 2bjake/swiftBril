//
//  Optimizations.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

enum Optimizations { }

extension Array {
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

extension Function {
    var blocks: [ArraySlice<Code>] {
        var result = [ArraySlice<Code>]()

        func appendSlice(range: ClosedRange<Int>) {
            var slice = code[range]
            if case .label = slice.last {
                slice = slice.dropLast()
            }
            //if !slice.isEmpty {
                result.append(slice)
            //}
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

enum BlockLabel {
    case entry
    case labeled(String)
    case unlabeled(String)
}

extension BlockLabel {
    var label: String {
        switch self {
            case .entry: return "entry"
            case .labeled(let value), .unlabeled(let value): return value
        }
    }
}

extension BlockLabel: Hashable { }

extension Function {
    var labeledBlocks: [BlockLabel: ArraySlice<Code>] {
        blocks.reduce(into: [:]) { result, block in
            let blockLabel: BlockLabel
            if block.startIndex == 0 {
                blockLabel = .entry
            } else if case .label(let label) = code[block.startIndex - 1] {
                blockLabel = .labeled(label)
            } else {
                blockLabel = .unlabeled("\(block.startIndex)")
            }
            result[blockLabel] = block
        }
    }
}

extension Program {
    mutating func optimize() -> Self {
        functions = functions
            .map(Optimizations.removeUnreachableCode)
            .map(Optimizations.lvnRewrite)
            .map(Optimizations.removeUnusedAssignments)
            .map(Optimizations.removeRedundantAssignments)
        return self
    }
}
