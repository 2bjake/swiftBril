//
//  Argument.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

struct Argument: Decodable {
    var name: String
    var type: Type
}

extension Argument: CustomStringConvertible {
    var description: String { "\(name): \(type)" }
}
