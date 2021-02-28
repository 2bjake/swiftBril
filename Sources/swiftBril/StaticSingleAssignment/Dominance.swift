//
//  Dominance.swift
//
//
//  Created by Jake Foster on 2/27/21.
//

enum SSA {
    private static func reversePostOrderedLabels(cfg: ControlFlowGraph) -> [String] {
        var result = [String]()
        var visited = Set<String>()

        func visit(_ labels: [String]) {
            for label in labels where !visited.contains(label) {
                visited.insert(label)
                visit(cfg.successorLabels(of: label))
                result.append(label)
            }
        }

        let entryPoints = cfg.orderedLabels.filter { cfg.predecessorLabels(of: $0).isEmpty }
        visit(entryPoints)
        return result.reversed()
    }

    // returns a dictionary of labels to their dominator labels
    static func findDominators(cfg: ControlFlowGraph, strict: Bool = false) -> [String: Set<String>] {
        let labelSet = Set(cfg.orderedLabels)
        var labelToDominators = [String: Set<String>]()
        for label in labelSet {
            labelToDominators[label] = labelSet
        }
        var changing = true
        let labels = reversePostOrderedLabels(cfg: cfg)
        while changing {
            changing = false
            for label in labels {
                let predsDominators = cfg.predecessorLabels(of: label).compactMap { labelToDominators[$0] }
                let newVal = Set([label]).union(intersection(predsDominators))
                if newVal != labelToDominators[label] {
                    labelToDominators[label] = newVal
                    changing = true
                }
            }
        }

        if strict {
            for (label, dominators) in labelToDominators {
                var strictDominators = dominators
                strictDominators.remove(label)
                labelToDominators[label] = strictDominators
            }
        }

        return labelToDominators
    }

    // returns a dictionary of labels to the labels they immediately dominate
    static func findImmediateDominators(cfg: ControlFlowGraph) -> [String: Set<String>] {
        var dominations = findDominators(cfg: cfg, strict: true)
        var immediateDominators: [String: Set<String>] = dominations.keys.reduce(into: [:]) { $0[$1] = [] }

        var singlyDominated = dominations.filter({ $0.value.count == 1 })
        while let dominator = singlyDominated.first?.value.first {
            for label in singlyDominated.keys {
                immediateDominators[dominator]?.insert(label)
                dominations[label] = nil
            }
            dominations.keys.forEach { dominations[$0]?.remove(dominator) }
            singlyDominated = dominations.filter({ $0.value.count == 1 })
        }
        return immediateDominators
    }
}

extension SSA {
    static func intersection<T>(_ sets: [Set<T>]) -> Set<T> {
        guard let first = sets.first else { return [] }
        return sets.dropFirst().reduce(into: first) { result, set in result.formIntersection(set) }
    }
}
