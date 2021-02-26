//
//  DataFlowAnalyzer.swift
//
//
//  Created by Jake Foster on 2/22/21.
//

private func union<T>(_ sets: [Set<T>]) -> Set<T> {
    sets.reduce(into: []) { $0.formUnion($1) }
}

enum DataFlowAnalyzer {
    struct Results<T> {
        let cfg: ControlFlowGraph
        let inValues: [String: T]
        let outValues: [String: T]
    }

    static func runConstantPropagationAnalysis(function: Function) -> Results<Dictionary<String, Literal>> {
        func merge(values: [[String: Literal]]) -> [String: Literal] {
            guard let first = values.first else { return [:] }
            let rest = values.dropFirst()

            var result = [String: Literal]()
            for (key, value) in first {
                if rest.allSatisfy({ $0[key] == value }) {
                    result[key] = value
                }
            }
            return result;
        }

        func transfer(block: ArraySlice<Code>, values: [String: Literal]) -> [String: Literal] {
            block.reduce(into: values) { result, line in
                switch line {
                    case .instruction(.const(let const)):
                        result[const.destination] = const.value
                    case .instruction(.value(let value)):
                        result[value.destination] = nil
                    default:
                        break
                }
            }
        }


        return runAnalysis(function: function,
                           runForward: true,
                           initializer: Dictionary.init,
                           merge: merge,
                           transfer: transfer)
    }

    static func runDefinedVariablesAnalysis(function: Function) -> Results<Set<String>> {
        runAnalysis(function: function,
                    runForward: true,
                    initializer: Set.init,
                    merge: union,
                    transfer: { block, values in values.union(block.compactMap(\.destinationIfPresent)) })

    }

    static func runLiveVariablesAnalysis(function: Function) -> Results<Set<String>> {
        func transfer(block: ArraySlice<Code>, values: Set<String>) -> Set<String> {
            var defined = Set<String>()
            var used = Set<String>()
            for line in block {
                used.formUnion(Set(line.arguments).subtracting(defined))
                if let dest = line.destinationIfPresent {
                    defined.insert(dest)
                }
            }
            return used.union(values.subtracting(defined))
        }

        return runAnalysis(function: function,
                           runForward: false,
                           initializer: Set.init,
                           merge: union,
                           transfer: transfer)
    }

    private static func runAnalysis<T: Equatable>(function: Function,
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

protocol DataFlowAnalysisStringConvertible {
    var analysisDescription: String { get }
}

extension Set: DataFlowAnalysisStringConvertible where Element: CustomStringConvertible {
    var analysisDescription: String {
        self.map(\.description).sorted().joined(separator: ", ")
    }
}

extension Dictionary: DataFlowAnalysisStringConvertible where Key: CustomStringConvertible, Value: CustomStringConvertible {
    var analysisDescription: String {
        self.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
    }
}

extension DataFlowAnalyzer.Results: CustomStringConvertible where T: DataFlowAnalysisStringConvertible {
    var description: String {
        var str = ""
        for label in cfg.orderedLabels {
            let inVals = inValues[label]?.analysisDescription ?? "∅"
            let outVals = outValues[label]?.analysisDescription ?? "∅"
            str += "\(label):\n" +
                   "  in:  [ \(inVals) ]\n" +
                   "  out: [ \(outVals) ]\n"
        }
        return str
    }
}
