//
//  DataFlowAnalyzer.swift
//
//
//  Created by Jake Foster on 2/22/21.
//

enum DataFlowAnalyzer {
    private static func union<T>(values: [Set<T>]) -> Set<T> {
        values.reduce(into: []) { $0.formUnion($1) }
    }

    static func findDefinedVariables(function: Function) -> [String: Set<String>] {
        return forwardAnalyzer(function: function,
                               inInitializer: { ["entry": Set($0.arguments.map(\.name))] },
                               merge: union,
                               transfer: { block, values in values.union(block.compactMap(\.destinationIfPresent)) })

    }

    private static func forwardAnalyzer<T>(function: Function,
                                           inInitializer: (Function) -> [String: Set<T>] = { _ in [:] },
                                           outInitializer: ((Function) -> [String: Set<T>])? = nil,
                                           merge: ([Set<T>]) -> Set<T>,
                                           transfer: (ArraySlice<Code>, Set<T>) -> Set<T>) -> [String: Set<T>] {
        let cfg = ControlFlowGraph(function: function)
        var worklist = Set(cfg.labeledBlocks.keys)

        var inValues = inInitializer(function)
        var outValues = outInitializer?(function) ?? cfg.labeledBlocks.keys.reduce(into: [:]) { $0[$1] = [] }

        while let label = worklist.popFirst(), let block = cfg.labeledBlocks[label] {
            let predecessorValues = cfg.predecessorLabels(of: label).compactMap { outValues[$0] }
            inValues[label] = merge(predecessorValues)

            let newOutValues = transfer(block, inValues[label] ?? [])
            if newOutValues != outValues[label] {
                worklist.formUnion(cfg.successorLabels(of: label))
                outValues[label] = newOutValues
            }
        }
        return outValues
    }
}
