//
//  LiveVariables.swift
//
//
//  Created by Jake Foster on 2/26/21.
//

import Bril

extension DataFlowAnalyzer {
    private static func transfer(block: ArraySlice<Code>, values: Set<String>) -> Set<String> {
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

    static func runLiveVariablesAnalysis(function: Function) -> Results<Set<String>> {
        runAnalysis(function: function,
                    runForward: false,
                    initializer: Set.init,
                    merge: union,
                    transfer: transfer)
    }
}
