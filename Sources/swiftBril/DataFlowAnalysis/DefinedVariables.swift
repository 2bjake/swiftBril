//
//  DefinedVariables.swift
//
//
//  Created by Jake Foster on 2/26/21.
//

import Bril

extension DataFlowAnalyzer {
    static func runDefinedVariablesAnalysis(function: Function) -> Results<Set<String>> {
        runAnalysis(function: function,
                    runForward: true,
                    initializer: Set.init,
                    merge: union,
                    transfer: { block, values in values.union(block.compactMap(\.destinationIfPresent)) })

    }
}
