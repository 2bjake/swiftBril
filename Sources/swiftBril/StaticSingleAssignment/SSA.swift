//
//  SSA.swift
//
//
//  Created by Jake Foster on 2/28/21.
//


private struct PhiBuilder {
    enum BuildError: Error { case destinationMissing, argumentsMissing }

    let destination: String
    let type: Type

    var newDestination: String?
    private var args: [String] = []
    private var labels: [String] = []

    init(destination: String, type: Type) {
        self.destination = destination
        self.type = type
    }

    mutating func addArg(_ arg: String, forLabel label: String) {
        args.append(arg)
        labels.append(label)
    }

    func build() throws -> Instruction {
        guard let newDestination = newDestination else { throw BuildError.destinationMissing }
        guard !args.isEmpty && !labels.isEmpty else { throw BuildError.argumentsMissing }

        return .value(.init(opType: .phi,
                            destination: newDestination,
                            type: type,
                            arguments: args,
                            functions: [],
                            labels: labels))
    }
}

enum SSA {
    /// returns a mapping of variable names to the blocks (labels) that define them
    private static func buildDefiningMapping(function: Function) -> [String: Set<String>] {
        var labelToDefinitions = [String: Set<String>]()
        for (label, block) in function.makeLabeledBlocks().labeledBlocks {
            labelToDefinitions[label.label] = Set(block.compactMap(\.destinationIfPresent))
        }
        return labelToDefinitions.inverted()
    }

    private static func getVariableTypes(function: Function) -> [String: Type] {
        var varToType = [String: Type]()
        for code in function.code {
            if let dest = code.destinationIfPresent, let type = code.typeIfPresent {
                varToType[dest] = type
            }
        }
        return varToType
    }

    /// returns a mapping of block labels to the variables names that need phi instructions
    static func findNeededPhis(function: Function) -> [String: Set<String>] {
        let cfg = ControlFlowGraph(function: function)
        let labelToFrontierLabels = findDominanceFrontiers(cfg: cfg)
        var labelToVars = [String: Set<String>]()

        var varToDefiningLabels = buildDefiningMapping(function: function).filter { $0.value.count > 1 }
        for variable in varToDefiningLabels.keys {
            for definingLabel in varToDefiningLabels[variable, default: []] {
                for frontierLabel in labelToFrontierLabels[definingLabel, default: []] {
                    labelToVars[frontierLabel, default: []].insert(variable)
                    varToDefiningLabels[variable]?.insert(frontierLabel)
                }
            }
        }

        return labelToVars
    }

    static func convertToSSA(function: Function) -> Function {
        var function = function


        let varToType = getVariableTypes(function: function)

        var labelToVarToPhiBuilders = findNeededPhis(function: function).mapValues { variables in
            variables.reduce(into: [:]) { result, variable in
                result[variable] = PhiBuilder(destination: variable, type: varToType[variable]!)
            }
        }

        var varToNameStack = varToType.reduce(into: [:]) { result, entry in
            result[entry.key] = [String]()
        }

        var counter = 0
        func pushNewNameFor(_ variable: String) -> String {
            let newName = "\(variable).\(counter)"
            counter += 1
            varToNameStack[variable]?.append(newName)
            return newName
        }

//        let (labelToBlock, labels) = function.makeLabeledBlocks()
//        for label in labels {
//            // update phi builders with new destinations
//            if let variables = labelToVarToPhiBuilders[label]?.keys {
//                for variable in variables {
//                    labelToVarToPhiBuilders[label]?[variable]?.newDestination = pushNewNameFor(variable)
//                }
//            }
//
//
//        }

        return function
    }
}
