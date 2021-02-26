//
//  DataFlowAnalyzer.swift
//
//
//  Created by Jake Foster on 2/22/21.
//

enum DataFlowAnalyzer {
    struct Results<T: Hashable> {
        let cfg: ControlFlowGraph
        let inValues: [String: Set<T>]
        let outValues: [String: Set<T>]
    }

    private static func union<T>(values: [Set<T>]) -> Set<T> {
        values.reduce(into: []) { $0.formUnion($1) }
    }

    static func findDefinedVariables(function: Function) -> Results<String> {
        runAnalysis(cfg: ControlFlowGraph(function: function),
                    runForward: true,
                    initializer: { ["entry": Set(function.arguments.map(\.name))] },
                    merge: union,
                    transfer: { block, values in values.union(block.compactMap(\.destinationIfPresent)) })

    }

    static func findLiveVariables(function: Function) -> Results<String> {
        let cfg = ControlFlowGraph(function: function)
        guard let lastLabel = cfg.orderedLabels.last else { return Results(cfg: cfg, inValues: [:], outValues: [:]) }

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

        return runAnalysis(cfg: cfg,
                           runForward: false,
                           initializer: { [lastLabel: Set()] },
                           merge: union,
                           transfer: { block, values in use(block).union(values.subtracting(gen(block)))}
)
    }

    private static func runAnalysis<T>(cfg: ControlFlowGraph,
                                       runForward: Bool,
                                       initializer: () -> [String: Set<T>] = { [:] },
                                       merge: ([Set<T>]) -> Set<T>,
                                       transfer: (ArraySlice<Code>, Set<T>) -> Set<T>) -> Results<T> {
        var worklist = Set(cfg.labeledBlocks.keys)

        var startValues = runForward ? initializer() : cfg.labeledBlocks.keys.reduce(into: [:]) { $0[$1] = [] }
        var endValues = !runForward ? initializer() : cfg.labeledBlocks.keys.reduce(into: [:]) { $0[$1] = [] }

        func leadingLabels(of label: String) -> [String] {
            runForward ? cfg.predecessorLabels(of: label) : cfg.successorLabels(of: label)
        }

        func trailingLabels(of label: String) -> [String] {
            runForward ? cfg.successorLabels(of: label) : cfg.predecessorLabels(of: label)
        }

        while let label = worklist.popFirst(), let block = cfg.labeledBlocks[label] {
            let leadingValues = leadingLabels(of: label).compactMap { endValues[$0] }
            startValues[label] = merge(leadingValues)

            let newEndValues = transfer(block, startValues[label] ?? [])
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

extension DataFlowAnalyzer.Results: CustomStringConvertible where T: CustomStringConvertible {
    var description: String {
        var str = ""
        for label in cfg.orderedLabels {
            let inVals = Array(inValues[label] ?? []).map(\.description).sorted().joined(separator: ", ")
            let outVals = Array(outValues[label] ?? []).map(\.description).sorted().joined(separator: ", ")
            str += "\(label):\n" +
                   "  in:  [ \(inVals) ]\n" +
                   "  out: [ \(outVals) ]\n"
        }
        return str
    }
}
