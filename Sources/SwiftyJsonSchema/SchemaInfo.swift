//
//  SchemaInfo.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//

import Foundation


protocol SchemaInfoProtocol {
    var description: String? { get }
    var subjectValue: Any? { get }
}

@propertyWrapper
public struct SchemaInfo<T: Codable>: Codable, SchemaInfoProtocol {

    public var wrappedValue: T
    public var description: String?

    public init(wrappedValue: T, description: String = "", oType: T.Type = T.self) {
        self.wrappedValue = wrappedValue
        self.description = description
    }
    
    // Custom encoding to include the description
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }

    // Custom decoding to ignore the description
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(T.self)
        self.description = ""
    }
    
    var subjectValue: Any? {
        return wrappedValue as? T
    }
}
