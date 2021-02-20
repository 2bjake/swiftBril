//
//  RemoveUnusedLabels.swift
//
//
//  Created by Jake Foster on 2/20/21.
//

extension Optimizations {
    /// Remove labels that are never referenced
    static func removeUnusedLabels(_ function: Function) -> Function {
        var function = function
        let usedLabels = Set(function.code.flatMap(\.labels))
        function.code.removeAll {
            guard case .label(let label) = $0 else { return false }
            return !usedLabels.contains(label)
        }
        return function
    }
}
