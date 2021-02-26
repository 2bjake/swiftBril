import Foundation

let data = FileHandle.standardInput.availableData

var program = try! JSONDecoder().decode(Program.self, from: data)
print(program)
print()
//print(program.optimize())
print("live variables analysis:")
print(DataFlowAnalyzer.findLiveVariables(function: program.functions[0]))
print("defined variables analysis:")
print(DataFlowAnalyzer.findDefinedVariables(function: program.functions[0]))
