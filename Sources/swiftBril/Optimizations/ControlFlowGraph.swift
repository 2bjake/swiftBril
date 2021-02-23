//
//  ControlFlowGraph.swift
//
//
//  Created by Jake Foster on 2/22/21.
//

private extension Function {
    var namedBlocks: [String: ArraySlice<Code>] {
        blocks.reduce(into: [:]) { result, block in
            let name: String
            if block.startIndex == 0 {
                name = "entry"
            } else if case .label(let label) = code[block.startIndex - 1] {
                name = label
            } else {
                name = "\(block.startIndex)"
            }
            result[name] = block
        }
    }
}

struct ControlFlowGraph {
    let labeledBlocks: [String: ArraySlice<Code>]
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

    init(function: Function, removeUnreachableCode: Bool = true) {
        labeledBlocks = function.namedBlocks
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
