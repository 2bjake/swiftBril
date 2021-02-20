//
//  Optimizations.swift
//
//
//  Created by Jake Foster on 2/19/21.
//

enum Optimizations { }

extension Program {
    mutating func optimize() -> Self {
        functions = functions
            .map(Optimizations.removeUnusedLabels)
            .map(Optimizations.removeUnusedAssignments)
            .map(Optimizations.removeRedundantAssignments)
        return self
    }
}
