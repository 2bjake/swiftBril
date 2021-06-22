//
//  DataFlowAnalyzer.swift
//
//
//  Created by Jake Foster on 2/22/21.
//

import Bril

enum DataFlowAnalyzer {
    struct Results<T> {
        let cfg: ControlFlowGraph
        let inValues: [String: T]
        let outValues: [String: T]
    }

    static func runAnalysis<T: Equatable>(function: Function,
                                          runForward: Bool,
                                          initializer: () -> T,
                                          merge: ([T]) -> T,
                                          transfer: (ArraySlice<Code>, T) -> T) -> Results<T> {
        let cfg = ControlFlowGraph(function: function)
        guard let beginLabel = (runForward ? cfg.orderedLabels.first : cfg.orderedLabels.last) else {
            return Results(cfg: cfg, inValues: [:], outValues: [:])
        }

        let allInitialized = cfg.labeledBlocks.keys.reduce(into: [:]) { $0[$1] = initializer() }
        let beginInitialized = [beginLabel: initializer()]

        var startValues = runForward ? beginInitialized : allInitialized
        var endValues = !runForward ? beginInitialized : allInitialized

        var worklist = Set(cfg.labeledBlocks.keys)

        func leadingLabels(of label: String) -> [String] {
            runForward ? cfg.predecessorLabels(of: label) : cfg.successorLabels(of: label)
        }

        func trailingLabels(of label: String) -> [String] {
            runForward ? cfg.successorLabels(of: label) : cfg.predecessorLabels(of: label)
        }

        while let label = worklist.popFirst(), let block = cfg.labeledBlocks[label] {
            let leadingValues = leadingLabels(of: label).compactMap { endValues[$0] }
            startValues[label] = merge(leadingValues)

            let newEndValues = transfer(block, startValues[label] ?? initializer())
            if newEndValues != endValues[label] {
                worklist.formUnion(trailingLabels(of: label))
                endValues[label] = newEndValues
            }
        }

        return Results(cfg: cfg,
                       inValues: runForward ? startValues : endValues,
                       outValues: runForward ? endValues : startValues)
    }
}

extension DataFlowAnalyzer {
    static func union<T>(_ sets: [Set<T>]) -> Set<T> {
        sets.reduce(into: []) { $0.formUnion($1) }
    }
}
