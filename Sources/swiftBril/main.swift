import Foundation

let data = FileHandle.standardInput.availableData

var program = try! JSONDecoder().decode(Program.self, from: data)
print(program)
print()
//print(program.optimize())
print()
_ = DataFlowAnalyzer.findLiveVariables(function: program.functions[0])
print()
_ = DataFlowAnalyzer.findDefinedVariables(function: program.functions[0])
