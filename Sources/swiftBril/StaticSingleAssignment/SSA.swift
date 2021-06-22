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
        for block in function.makeBlocks(includeEmpty: true) {
            labelToDefinitions[block.label.name] = Set(block.code.compactMap(\.destinationIfPresent))
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

//    private static func findPhiOps(cfg: ControlFlowGraph) -> [String: [ValueOperation]] {
//        var labelToPhis: [String: [ValueOperation]] = [:]
//
//        for (label, code) in cfg.labeledBlocks {
//            for instr in code {
//                switch instr {
//                    case .instruction(.value(let op)) where op.opType == .phi:
//                        labelToPhis[label, default: []].append(op)
//                    default:
//                        break
//                }
//            }
//        }
//        return labelToPhis
//    }

//    private static func makeAssignJmpBlocks(toLabel: String, phiOp: ValueOperation) -> [[Code]] {
//
//    }

//    static func convertFromSSA(function: Function) -> Function {
//        let cfg = ControlFlowGraph(function: function)
//        guard !cfg.orderedLabels.isEmpty else { return function }
//
//        let labelToPhis = findPhiOps(cfg: cfg)
//
//
//
//    }

    static func convertToSSA(function: Function) -> Function {
        let cfg = ControlFlowGraph(function: function)
        guard !cfg.orderedLabels.isEmpty else { return function }

        var function = function
        let varToType = getVariableTypes(function: function)
        let immediateDominators = findImmediateDominators(cfg: cfg)

        var labelToVarToPhiBuilders = findNeededPhis(function: function).mapValues { variables in
            variables.reduce(into: [:]) { result, variable in
                result[variable] = PhiBuilder(destination: variable, type: varToType[variable]!)
            }
        }

        var counter = 0
        func rename(label: String, varToNameStack: [String: [String]]) {
            guard let block = cfg.labeledBlocks[label] else { return }
            var varToNameStack = varToNameStack

            func pushNewNameFor(_ variable: String) -> String {
                let newName = "\(variable).\(counter)"
                counter += 1
                varToNameStack[variable]?.append(newName)
                return newName
            }

            // update phi builders with new destinations
            if let variables = labelToVarToPhiBuilders[label]?.keys {
                for variable in variables {
                    labelToVarToPhiBuilders[label]?[variable]?.newDestination = pushNewNameFor(variable)
                }
            }

            // update arguments and destinations with new names
            for idx in block.indices {
                switch function.code[idx] {
                    case .instruction(.const(var op)):
                        op.destination = pushNewNameFor(op.destination)
                        function.code[idx] = .instruction(.const(op))
                    case .instruction(.value(var op)):
                        op.arguments = op.arguments.map { varToNameStack[$0]!.last! }
                        op.destination = pushNewNameFor(op.destination)
                        function.code[idx] = .instruction(.value(op))
                    case .instruction(.effect(var op)):
                        op.arguments = op.arguments.map { varToNameStack[$0]!.last! }
                        function.code[idx] = .instruction(.effect(op))
                    case .label:
                        break
                }
            }

            for successorLabel in cfg.successorLabels(of: label) {
                guard let variables = labelToVarToPhiBuilders[successorLabel]?.keys else { continue }
                for variable in variables {
                    let newName = varToNameStack[variable]?.last ?? "__undefined"
                    labelToVarToPhiBuilders[successorLabel]?[variable]?.addArg(newName, forLabel: label)
                }
            }

            // sorting isn't strictly necessary but makes the generated labels deterministic from run to run
            immediateDominators[label]?.sorted().forEach {
                rename(label: $0, varToNameStack: varToNameStack)
            }
        }

        var varToNameStack = varToType.reduce(into: [:]) { result, entry in
            result[entry.key] = [entry.key]
        }
        // need to add function args as well
        function.arguments.forEach {
            varToNameStack[$0.name] = [$0.name]
        }

        rename(label: cfg.orderedLabels[0], varToNameStack: varToNameStack)

        // insert phi nodes
        for label in cfg.orderedLabels.reversed() {
            guard let varToBuilder = labelToVarToPhiBuilders[label] else { continue }
            let insertIdx = cfg.labeledBlocks[label]!.startIndex
            varToBuilder.forEach { variable, builder in
                try! function.code.insert(.instruction(builder.build()), at: insertIdx)
            }
        }

        return function
    }
}
