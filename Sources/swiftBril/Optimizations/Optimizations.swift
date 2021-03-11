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

struct Block {
    enum Label {
        case entry
        case labeled(String)
        case unlabeled(Int)
    }

    let label: Label
    let code: ArraySlice<Code>
}

extension Block.Label {
    var name: String {
        switch self {
            case .entry: return "cfg.entry"
            case .labeled(let value): return value
            case .unlabeled(let value): return "cfg.\(value)"
        }
    }
}

extension Function {
    func makeBlock(startingAt idx: Int) -> Block? {
        guard idx < code.count else { return nil }
        let label: Block.Label
        let blockStart: Int
        if case .label(let labelName) = code[idx] {
            label = .labeled(labelName)
            blockStart = idx + 1
        } else {
            label = idx == 0 ? .entry : .unlabeled(idx)
            blockStart = idx
        }

        if blockStart >= code.count {
            return Block(label: label, code: [])
        }

        for i in blockStart..<code.count {
            if code[i].isBlockTerminator {
                var slice = code[blockStart...i]
                if case .label = slice.last {
                    slice = slice.dropLast()
                }
                return Block(label: label, code: slice)
            }
        }
        return Block(label: label, code: code[blockStart...(code.count - 1)])
    }

    func makeBlocks(includeEmpty: Bool = false) -> [Block] {
        var result = [Block]()
        var curIdx = 0
        while let block = makeBlock(startingAt: curIdx) {
            if includeEmpty || !block.code.isEmpty {
                result.append(block)
                curIdx = block.code.endIndex
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
