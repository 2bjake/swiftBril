//
//  DataFlowAnalyzer.swift
//
//
//  Created by Jake Foster on 2/22/21.
//



enum DataFlowAnalyzer {
/*
    in[entry] = init
    out[*] = init

    worklist = all blocks
    while worklist is not empty:
        b = pick any block from worklist
        in[b] = merge(out[p] for every predecessor p of b)
        out[b] = transfer(b, in[b])
        if out[b] changed:
            worklist += successors of b
 */

    private static func merge(_ values: [Set<String>]) -> Set<String> {
        return values.reduce(into: []) { $0.formUnion($1) }
    }

    static func findInitializedVariables(function: Function) -> [String: Set<String>] {
        let cfg = ControlFlowGraph(function: function)
        var worklist = Set(cfg.labeledBlocks.keys)

        var labelToInVars = [String: Set<String>]()
        labelToInVars["entry"] = Set(function.arguments.map(\.name))
        var labelToOutVars: [String: Set<String>] = cfg.labeledBlocks.keys.reduce(into: [:]) { $0[$1] = [] }

        while let label = worklist.popFirst(), let block = cfg.labeledBlocks[label] {
            labelToInVars[label] = merge(cfg.predecessorLabels(of: label).compactMap { labelToOutVars[$0] })

            let newOutVars = labelToInVars[label]!.union(block.compactMap(\.destinationIfPresent))
            if newOutVars != labelToOutVars[label] {
                worklist.formUnion(cfg.successorLabels(of: label))
            }
            labelToOutVars[label] = newOutVars
        }
        return labelToOutVars
    }
    
}
