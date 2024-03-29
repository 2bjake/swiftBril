//
//  DefaultDecodable.swift
//
//
//  Created by Jake Foster on 2/18/21.
//

import Foundation

public protocol DecodeDefaulting: Decodable {
    static var defaultDecodingValue: Self { get }
}

extension Array: DecodeDefaulting where Element: Decodable {
    public static var defaultDecodingValue: Self { [] }
}

//extension Dictionary: DecodeDefaulting where Key: Decodable, Value: Decodable {
//    static var defaultDecodingValue: Self { [:] }
//}

@propertyWrapper
public struct DefaultDecodable<T: DecodeDefaulting>: Decodable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode(T.self)) ?? T.defaultDecodingValue
    }
}

extension KeyedDecodingContainer {
    func decode<T>(_: DefaultDecodable<T>.Type, forKey key: Key) throws -> DefaultDecodable<T> {
        if let value = try decodeIfPresent(DefaultDecodable<T>.self, forKey: key) {
            return value
        } else {
            return DefaultDecodable(wrappedValue: T.defaultDecodingValue)
        }
    }
}
