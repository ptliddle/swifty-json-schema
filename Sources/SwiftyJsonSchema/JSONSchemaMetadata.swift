//
//  JSONSchemaMetadata.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//  Updated on 6/26/25.
//

import Foundation

protocol GeneratesJSONSchemaMetadata {
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

protocol BaseJSONSchemaMetadataProtocol: Sendable {
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
        return _wrappedValue ?? { fatalError("This shouldn't happen") }()
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
}

@propertyWrapper
public struct OptionalJSONSchemaMetadata<T>: OptionalJSONSchemaMetadataProtocol where T: Codable, T: Sendable{
    
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
        self.wrappedValue = try container.decode(T.self)
        self.schemaDescription = ""
    }
    
    var subjectValue: T? {
        return wrappedValue
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
    
    var subjectValue: T? {
        return wrappedValue
    }
}
