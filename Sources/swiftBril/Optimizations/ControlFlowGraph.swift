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
        var (blocks, orderedLabels) = function.makeLabeledBlocks()

        // insert a entry block if the first label is ever jumped to
        if function.code.contains(where: { $0.operation?.labels.contains(orderedLabels[0]) ?? false } ) {
            blocks[.entry] = []
            orderedLabels.insert(BlockLabel.entry.label, at: 0)
        }

        labeledBlocks = .init(uniqueKeysWithValues: blocks.map { (key: $0.key.label, value: $0.value) })
        self.orderedLabels = orderedLabels
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
