import Foundation

let data = FileHandle.standardInput.availableData

var program = try! JSONDecoder().decode(Program.self, from: data)
print(program)
let function = program.functions[0]
print()
//print(program.optimize())
//print("live variables analysis:")
//print(DataFlowAnalyzer.runLiveVariablesAnalysis(function: function))
//print("defined variables analysis:")
//print(DataFlowAnalyzer.runDefinedVariablesAnalysis(function: function))
//print("constant propagation analysis:")
//print(DataFlowAnalyzer.runConstantPropagationAnalysis(function: function))
//print(SSA.findDominators(cfg: ControlFlowGraph(function: function)))
//print(SSA.findImmediateDominators(cfg: ControlFlowGraph(function: function)))
//print(SSA.findDominanceFrontiers(cfg: ControlFlowGraph(function: function)))
//print(SSA.findNeededPhis(function: function))
print(SSA.convertToSSA(function: function))
