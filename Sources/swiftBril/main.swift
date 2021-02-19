import Foundation

let data = FileHandle.standardInput.availableData

let program = try! JSONDecoder().decode(Program.self, from: data)
print(program)
