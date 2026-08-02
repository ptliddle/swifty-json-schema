//
//  JSONSchemaMetadata.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//  Updated on 6/26/25.
//

import Foundation

public protocol HasCustomJSONSchemaDescriptions {
    static var schemaDescriptions: [String: String] { get }
}

public protocol GeneratesJSONSchemaMetadata {
    var schemaDescription: String? { get }
    var additionalProperties: AdditionalPropertiesType? { get }
}

extension GeneratesJSONSchemaMetadata {
    var schemaDescription: String? {
        return nil
    }
    
    var additionalProperties: AdditionalPropertiesType?  {
        return nil
    }
}

public protocol BaseJSONSchemaMetadataProtocol: Sendable {
    associatedtype T
    var schemaDescription: String? { get }
    var subjectValue: T? { get }
    var additionalProperties: AdditionalPropertiesType? { get }
}

protocol JSONSchemaIgnorable: Codable {}

@propertyWrapper
public struct JSONSchemaExclude<Value: Codable>: JSONSchemaIgnorable {
    
    public var _wrappedValue: Value?
    
    public init(wrappedValue: Value) {
        self._wrappedValue = wrappedValue
    }
    
    public init(wrappedValue: Value?) {
        self._wrappedValue = wrappedValue
    }
    
    public var wrappedValue: Value {
        get {
            return _wrappedValue ?? { fatalError("This shouldn't happen") }()
        }
        set {
            _wrappedValue = newValue
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self._wrappedValue = try container.decode(Value.self)
    }
    
    public func encode(to encoder: any Encoder) throws {
        // This is a decorator property so we just ouput wrapped value directly
        var container = encoder.singleValueContainer()
        try container.encode(_wrappedValue)
    }
}

// Indicates that the schema allows additional properties
public protocol DynamicSchema {}

protocol OptionalJSONSchemaMetadataProtocol: Codable, Sendable, BaseJSONSchemaMetadataProtocol {
    associatedtype T
    var wrappedValue: T? { get }
    var wrappedType: Any.Type { get }
}

public extension KeyedDecodingContainer {
    
    // Provide a decode method for the OptionalJSONSchemaMetadata so if the associated property is missing in the input JSON
    // it returns a OptionalJSONSchemaMetadata with a wrapped nil value rather then failing to decode
    public func decode<T>(_ type: OptionalJSONSchemaMetadata<T>.Type, forKey key: Key) throws -> OptionalJSONSchemaMetadata<T> where T: Decodable {
        do {
            let value = try self.decode(T.self, forKey: key)
            return OptionalJSONSchemaMetadata(wrappedValue: value)
        }
        catch DecodingError.keyNotFound(_, _) {
            // If no key return a nil value
            return OptionalJSONSchemaMetadata(wrappedValue: nil)
        }
    }
}
 

@propertyWrapper
public struct OptionalJSONSchemaMetadata<T>: OptionalJSONSchemaMetadataProtocol where T: Codable, T: Sendable {
    
    public var wrappedValue: T?
    public var schemaDescription: String?
    
    public var additionalProperties: AdditionalPropertiesType?

    public init(wrappedValue: T?, description: String? = nil, additionalProperties: AdditionalPropertiesType? = nil, oType: T.Type = T.self) {
        self.wrappedValue = wrappedValue
        self.schemaDescription = description
    }
    
    // Custom encoding to include the description
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }

    // Custom decoding to ignore the description
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(T?.self)
        self.schemaDescription = ""
    }
    
    public var subjectValue: T? {
        return wrappedValue
    }

    var wrappedType: Any.Type {
        return T.self
    }
}

protocol JSONSchemaMetadataProtocol: Codable, Sendable, BaseJSONSchemaMetadataProtocol {
    associatedtype T
    var wrappedValue: T { get }
}

@propertyWrapper
public struct JSONSchemaMetadata<T>: JSONSchemaMetadataProtocol where T: Codable, T: Sendable{

    public var wrappedValue: T
    public var schemaDescription: String?
    
    public var additionalProperties: AdditionalPropertiesType?

    public init(wrappedValue: T, description: String? = nil, additionalProperties: AdditionalPropertiesType? = nil, oType: T.Type = T.self) {
        self.wrappedValue = wrappedValue
        self.schemaDescription = description
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
        self.schemaDescription = ""
    }
    
    public var subjectValue: T? {
        return wrappedValue
    }
}
