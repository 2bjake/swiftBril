//
//  Program.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

public struct Program: Decodable {
    public var functions: [Function]
}

extension Program: CustomStringConvertible {
    public var description: String {
        functions.map(String.init).joined(separator: "\n\n")
    }
}
