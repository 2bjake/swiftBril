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

enum BlockLabel {
    case entry
    case labeled(String)
    case unlabeled(String)
}

extension BlockLabel {
    var label: String {
        switch self {
            case .entry: return "cfg.entry"
            case .labeled(let value), .unlabeled(let value): return value
        }
    }
}

extension BlockLabel: Hashable { }

struct Block {
    let label: BlockLabel
    let code: ArraySlice<String>
}

extension Function {
    func makeBlock(startingAt idx: Int) -> (BlockLabel, ArraySlice<Code>)? {
        guard idx < code.count else { return nil }
        let label: BlockLabel
        let blockStart: Int
        if case .label(let labelName) = code[idx] {
            label = .labeled(labelName)
            blockStart = idx + 1
        } else {
            label = idx == 0 ? .entry : .unlabeled("\(idx)")
            blockStart = idx
        }

        if blockStart >= code.count {
            return (label, [])
        }

        for i in blockStart..<code.count {
            if code[i].isBlockTerminator {
                var slice = code[blockStart...i]
                if case .label = slice.last {
                    slice = slice.dropLast()
                }
                return (label, slice)
            }
        }
        return (label, code[blockStart...(code.count - 1)])
    }

    func makeLabeledBlocks() -> (labeledBlocks: [BlockLabel: ArraySlice<Code>], orderedLabels: [String]) {
        var labeledBlocks = [BlockLabel: ArraySlice<Code>]()
        var orderedLabels = [String]()
        var curIdx = 0
        while let (label, block) = makeBlock(startingAt: curIdx) {
            labeledBlocks[label] = block
            orderedLabels.append(label.label)
            curIdx = block.endIndex
        }
        return (labeledBlocks, orderedLabels)
    }

    func makeBlocks() -> [ArraySlice<Code>] {
        var result = [ArraySlice<Code>]()
        var curIdx = 0
        while let (_, block) = makeBlock(startingAt: curIdx) {
            if !block.isEmpty {
                result.append(block)
                curIdx = block.endIndex
            } else {
                curIdx += 1
            }
        }
        return result
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
