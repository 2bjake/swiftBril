import Foundation

let data = FileHandle.standardInput.availableData

var program = try! JSONDecoder().decode(Program.self, from: data)
print(program)
print()
//print(program.optimize())
print("live variables analysis:")
print(DataFlowAnalyzer.runLiveVariablesAnalysis(function: program.functions[0]))
print("defined variables analysis:")
print(DataFlowAnalyzer.runDefinedVariablesAnalysis(function: program.functions[0]))
print("constant propagation analysis:")
print(DataFlowAnalyzer.runConstantPropagationAnalysis(function: program.functions[0]))
