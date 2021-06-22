//
//  Argument.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

public struct Argument: Decodable {
    public var name: String
    public var type: Type
}

extension Argument: CustomStringConvertible {
    public var description: String { "\(name): \(type)" }
}
