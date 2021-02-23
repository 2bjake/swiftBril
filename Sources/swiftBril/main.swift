import Foundation

let data = FileHandle.standardInput.availableData

var program = try! JSONDecoder().decode(Program.self, from: data)
print(program)
print()
//print(program.optimize())
print(DataFlowAnalyzer.findInitializedVariables(function: program.functions[0]))
