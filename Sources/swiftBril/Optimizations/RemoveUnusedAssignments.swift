//
//  RemoveUnusedAssignments.swift
//
//
//  Created by Jake Foster on 2/20/21.
//

import Bril

extension Optimizations {
    private static func removeUnusedAssignmentsSinglePass(_ function: Function) -> (changed: Bool, function: Function) {
        var changed = false
        var function = function

        let usedVars = Set(function.code.flatMap(\.arguments))
        function.code.removeAll {
            guard let assignedVar = $0.destinationIfPresent else { return false }

            // call can have side effects, so don't remove it even if destination isn't used
            if case .instruction(.value(let op)) = $0, op.opType == .call {
                return false
            }

            if !usedVars.contains(assignedVar) {
                changed = true
                return true
            }
            return false
        }
        return (changed, function)
    }

    /// Remove (side-effect-free) assignments to variables that are never used
    static func removeUnusedAssignments(_ function: Function) -> Function {
        var (changed, function) = removeUnusedAssignmentsSinglePass(function)
        while changed {
            (changed, function) = removeUnusedAssignmentsSinglePass(function)
        }
        return function
    }
}
