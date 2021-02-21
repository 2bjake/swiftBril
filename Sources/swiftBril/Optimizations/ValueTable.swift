//
//  ValueTable.swift
//
//
//  Created by Jake Foster on 2/20/21.
//

struct ValueTable {
    enum Value: Hashable {
        case constant(Literal)
        case value(op: String, valueNums: [Int])
    }

    class Entry {
        let number: Int
        let value: Value
        let variableName: String

        init(number: Int, value: Value, variableName: String) {
            self.number = number
            self.value = value
            self.variableName = variableName
        }
    }

    private var orderedEntries: [Entry] = []
    private var valueToEntry: [Value: Entry] = [:]

    @discardableResult
    mutating func insert(value: Value, variableName: String) -> Entry {
        let entry = Entry(number: orderedEntries.count, value: value, variableName: variableName)
        orderedEntries.append(entry)
        valueToEntry[value] = entry
        return entry
    }

    @discardableResult
    mutating func insertIdentity(variableName: String) -> Int {
        let num = orderedEntries.count
        let value = Value.value(op: ValueOperation.OpType.id.rawValue, valueNums: [num])
        return insert(value: value, variableName: variableName).number
    }

    func entryForValue(_ value: Value) -> Entry? {
        return valueToEntry[value]
    }

    // number must be in bounds, else 💥
    func entryForNumber(_ number: Int) -> Entry {
        return orderedEntries[number]
    }
}
