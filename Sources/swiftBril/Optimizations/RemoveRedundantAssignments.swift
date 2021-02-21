//
//  RemoveRedundantAssignments.swift
//
//
//  Created by Jake Foster on 2/20/21.
//

private extension Array {
    mutating func removeAll(at indicies: [Int]) {
        for index in indicies.sorted(by: >) {
            remove(at: index)
        }
    }
}

extension Optimizations {
    private static func findRedundantAssignmentIndiciesSinglePass(_ function: Function) -> [Int] {
        var deleteIndicies = [Int]()
        for block in function.blocks {
            var lastDef = [String: Int]()
            for i in block.indices {
                block[i].arguments.forEach {
                    lastDef[$0] = nil
                }

                if let dest = block[i].destination {
                    if let unusedIdx = lastDef[dest] {
                        deleteIndicies.append(unusedIdx)
                    }
                    lastDef[dest] = i
                }
            }
        }
        return deleteIndicies
    }

    /// Remove (side-effect-free) assignments to variables that are reassigned before being read
    static func removeRedundantAssignments(_ function: Function) -> Function {
        var function = function
        var deleteIndicies = findRedundantAssignmentIndiciesSinglePass(function)
        while !deleteIndicies.isEmpty {
            function.code.removeAll(at: deleteIndicies)
            deleteIndicies = findRedundantAssignmentIndiciesSinglePass(function)
        }
        return function
    }

//    static func removeRedundantAssignments(_ program: Program) -> Program {
//        var program = program
//        for i in 0..<program.functions.count {
//            program.functions[i] = removeRedundantAssignments(program.functions[i])
//        }
//        return program
//    }
}
