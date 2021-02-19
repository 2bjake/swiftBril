//
//  Program.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

struct Program: Decodable {
    var functions: [Function]
}

extension Program: CustomStringConvertible {
    var description: String {
        functions.map(String.init).joined(separator: "\n\n")
    }
}
