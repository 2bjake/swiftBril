//
//  Operation.swift
//
//
//  Created by Jake Foster on 2/20/21.
//

protocol Operation {
    var destinationIfPresent: String? { get }
    var typeIfPresent: Type? { get }
    var valueIfPresent: Literal? { get }

    var name: String { get }
    var arguments: [String] { get }
    var functions: [String] { get }
    var labels: [String] { get }
}

extension Operation {
    var destinationIfPresent: String? { nil }
    var typeIfPresent: Type? { nil }
    var valueIfPresent: Literal? { nil }

    var arguments: [String] { [] }
    var functions: [String] { [] }
    var labels: [String] { [] }
}

extension ConstantOperation: Operation {
    var destinationIfPresent: String? { destination }
    var typeIfPresent: Type? { type }
    var valueIfPresent: Literal? { value }
}

extension ValueOperation: Operation {
    var destinationIfPresent: String? { destination }
    var typeIfPresent: Type? { type }
}

extension EffectOperation: Operation { }
