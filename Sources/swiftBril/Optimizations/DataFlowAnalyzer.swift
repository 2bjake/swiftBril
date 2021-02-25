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
        return forwardAnalyzer(cfg: ControlFlowGraph(function: function),
                               initializer: { ["entry": Set(function.arguments.map(\.name))] },
                               merge: union,
                               transfer: { block, values in values.union(block.compactMap(\.destinationIfPresent)) })

    }

    static func findLiveVariables(function: Function) -> [String: Set<String>] {
        let cfg = ControlFlowGraph(function: function)
        guard let lastLabel = cfg.orderedLabels.last else { return [:] }

        func use(_ block: ArraySlice<Code>) -> Set<String> {
            var defined = Set<String>()
            var used = Set<String>()
            for line in block {
                used.formUnion(Set(line.arguments).subtracting(defined))
                if let dest = line.destinationIfPresent {
                    defined.insert(dest)
                }
            }
            return used
        }

        func gen(_ block: ArraySlice<Code>) -> [String] {
            block.compactMap(\.destinationIfPresent)
        }

        return backwardAnalyzer(cfg: cfg,
                               initializer: { [lastLabel: Set()] },
                               merge: union,
                               transfer: { block, values in use(block).union(values.subtracting(gen(block)))}
)
    }

    private typealias Value = Hashable & CustomStringConvertible

    private static func forwardAnalyzer<T: Value>(cfg: ControlFlowGraph,
                                           initializer: () -> [String: Set<T>] = { [:] },
                                           merge: ([Set<T>]) -> Set<T>,
                                           transfer: (ArraySlice<Code>, Set<T>) -> Set<T>) -> [String: Set<T>] {
        var worklist = Set(cfg.labeledBlocks.keys)

        var inValues = initializer()
        var outValues: [String: Set<T>] = cfg.labeledBlocks.keys.reduce(into: [:]) { $0[$1] = [] }

        while let label = worklist.popFirst(), let block = cfg.labeledBlocks[label] {
            let predecessorValues = cfg.predecessorLabels(of: label).compactMap { outValues[$0] }
            inValues[label] = merge(predecessorValues)

            let newOutValues = transfer(block, inValues[label] ?? [])
            if newOutValues != outValues[label] {
                worklist.formUnion(cfg.successorLabels(of: label))
                outValues[label] = newOutValues
            }
        }

        for label in cfg.orderedLabels {
            print("\(label):")
            let inVals = Array(inValues[label] ?? []).map(\.description).sorted().joined(separator: ", ")
            print("  in:  [ \(inVals) ]")
            let outVals = Array(outValues[label] ?? []).map(\.description).sorted().joined(separator: ", ")
            print("  out: [ \(outVals) ]")
        }

        return outValues
    }

    // TODO: can this be unified with forwardAnalyzer?
    private static func backwardAnalyzer<T: Value>(cfg: ControlFlowGraph,
                                                   initializer: () -> [String: Set<T>] = { [:] },
                                                   merge: ([Set<T>]) -> Set<T>,
                                                   transfer: (ArraySlice<Code>, Set<T>) -> Set<T>) -> [String: Set<T>] {
        var worklist = Set(cfg.labeledBlocks.keys)

        var inValues: [String: Set<T>] = cfg.labeledBlocks.keys.reduce(into: [:]) { $0[$1] = [] }
        var outValues = initializer()


        while let label = worklist.popFirst(), let block = cfg.labeledBlocks[label] {
            let successorValues = cfg.successorLabels(of: label).compactMap { inValues[$0] }
            outValues[label] = merge(successorValues)

            let newInValues = transfer(block, outValues[label] ?? [])
            if newInValues != inValues[label] {
                worklist.formUnion(cfg.predecessorLabels(of: label))
                inValues[label] = newInValues
            }
        }

        for label in cfg.orderedLabels {
            print("\(label):")
            let inVals = Array(inValues[label] ?? []).map(\.description).sorted().joined(separator: ", ")
            print("  in:  [ \(inVals) ]")
            let outVals = Array(outValues[label] ?? []).map(\.description).sorted().joined(separator: ", ")
            print("  out: [ \(outVals) ]")
        }

        return inValues
    }
}
