//
//  ControlFlowGraph.swift
//
//
//  Created by Jake Foster on 2/22/21.
//

struct ControlFlowGraph {
    let labeledBlocks: [String: ArraySlice<Code>]
    let orderedLabels: [String]
    private let labelToSuccessorLabels: [String: [String]]
    private let labelToPredecessorLabels: [String: [String]]

    func successorLabels(of label: String) -> [String] {
        labelToSuccessorLabels[label] ?? []
    }

    func successorBlocks(of label: String) -> [ArraySlice<Code>] {
        labelToSuccessorLabels[label]?.compactMap { labeledBlocks[$0] } ?? []
    }

    func predecessorLabels(of label: String) -> [String] {
        labelToPredecessorLabels[label] ?? []
    }

    func predecessorBlocks(of label: String) -> [ArraySlice<Code>] {
        labelToPredecessorLabels[label]?.compactMap { labeledBlocks[$0] } ?? []
    }

    init(function: Function) {
        var blocks = function.makeBlocks(includeEmpty: true)

        if blocks.isEmpty {
            blocks.append(.emptyEntry)
        }

        // insert a entry block if the first label is ever jumped to
        if function.code.contains(where: { $0.operation?.labels.contains(blocks[0].label.name) ?? false } ) {
            blocks.insert(.emptyEntry, at: 0)
        }

        labeledBlocks = blocks.reduce(into: [:]) { result, block in
            result[block.label.name] = block.code
        }
        self.orderedLabels = blocks.map(\.label.name)
        labelToSuccessorLabels = labeledBlocks.reduce(into: [:]) { result, entry in
            let (label, block) = entry
            if case .instruction(.effect(let op)) = block.last, op.opType == .ret {
                result[label] = []
            } else if let labels = block.last?.labels, !labels.isEmpty {
                result[label] = labels
            } else if block.endIndex >= function.code.count {
                result[label] = []
            } else if case .label(let nextLabel) = function.code[block.endIndex] {
                result[label] = [nextLabel]
            } else {
                result[label] = ["\(block.endIndex)"]
            }
        }

        labelToPredecessorLabels = labelToSuccessorLabels.reduce(into: [:]) { result, entry in
            let (predecessor, successors) = entry
            for successor in successors {
                result[successor, default: []].append(predecessor)
            }
        }
    }
}

private extension Block {
    static var emptyEntry: Block { .init(label: .entry, code: []) }
}
