//
//  RemoveUnreachableCode.swift
//
//
//  Created by Jake Foster on 2/23/21.
//

extension Optimizations {
    private static func findDeadCodeIndicies(function: Function) -> [Int] {
        var result = [Int]()
        for (label, block) in function.makeLabeledBlocks().labeledBlocks {
            if case .unlabeled = label {
                result.append(contentsOf: block.indices)
            }
        }
        return result
    }

    static func removeUnreachableCode(_ function: Function) -> Function {
        var function = removeUnusedLabels(function)
        var deadIndicies = findDeadCodeIndicies(function: function)
        while !deadIndicies.isEmpty {
            function.code.removeAll(at: deadIndicies)
            function = removeUnusedLabels(function)
            deadIndicies = findDeadCodeIndicies(function: function)
        }
        return function
    }
}
