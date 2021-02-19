//
//  Optimizations.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

private func removeUnusedLabels(_ function: Function) -> Function {
    var function = function
    let usedLabels = Set(function.code.flatMap(\.labels))
    function.code.removeAll {
        guard case .label(let label) = $0 else { return false }
        return !usedLabels.contains(label)
    }
    return function
}

private func removeUnusedAssignmentsOnePass(_ function: Function) -> (changed: Bool, function: Function) {
    var changed = false
    var function = function

    let usedVars = Set(function.code.flatMap(\.arguments))
    function.code.removeAll {
        guard let destination = $0.destination else { return false }
        if !usedVars.contains(destination) {
            changed = true
            return true
        }
        return false
    }
    return (changed, function)
}

private func removeUnusedAssignments(_ function: Function) -> Function {
    var (changed, function) = removeUnusedAssignmentsOnePass(function)
    while changed {
        (changed, function) = removeUnusedAssignmentsOnePass(function)
    }
    return function
}

extension Program {
    mutating func optimize() -> Self {
        functions = functions
            .map(removeUnusedLabels)
            .map(removeUnusedAssignments)
        return self
    }
}
