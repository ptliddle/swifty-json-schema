//
//  JsonSchema.swift
//
//
//  Created by Peter Liddle on 8/27/24.
//

import Foundation

// Represents the type of a JSON Schema
public enum JSONSchemaType: String, Sendable, Codable {
    case object
    case array
    case string
    case number
    case integer
    case boolean
    case null
}

extension JSONSchemaType {
    init(withRawEnumType: String) throws {
        switch withRawEnumType {
        case "Int", "Int8", "Int16", "Int32", "Int64",
             "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            self = .integer
        case "Double", "Float":
            self = .number
        case "Bool":
            self = .boolean
        case "String", "Character":
            self = .string
        case "Array":
            self = .array
        case "Dictionary":
            self = .object
        default:
            throw JSONSchemaError.unrecognizedType
        }
    }
}

/// Used when you need to reference a JSONSchema but you can't directly reference yourself in a struct in Swift
public final class PassthroughContainer: Codable, Sendable {
    let items: JSONSchema?
    
    init(_ items: JSONSchema?) {
        self.items = items
    }
    
    static func contain(_ items: JSONSchema?) -> Self? {
        if let items = items {
            return Self(items)
        }
        return nil
    }
}

public enum AdditionalPropertiesType: Codable, Sendable, Equatable {
    public static func == (lhs: AdditionalPropertiesType, rhs: AdditionalPropertiesType) -> Bool {
        
        if case let AdditionalPropertiesType.bool(lhsBool) = lhs, case let AdditionalPropertiesType.bool(rhsBool) = rhs {
            return lhsBool == rhsBool
        }
        else if case let AdditionalPropertiesType.schema(lhsSchema) = lhs, case let AdditionalPropertiesType.schema(rhsSchema) = rhs {
            return lhsSchema.type == rhsSchema.type
        }
        
        return false
    }
    
    case bool(Bool)
    indirect case schema(JSONSchema)
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .schema(let schemaValue):
            try container.encode(schemaValue)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        }
        else {
            let schemaValue = try container.decode(JSONSchema.self)
            self = .schema(schemaValue)
        }
    }
}

// A struct to represent a JSON Schema
public struct JSONSchema: Codable, Sendable, CustomDebugStringConvertible {
   
    var id: String?
    var schema: String?
    
    var title: String?
    var type: JSONSchemaType?
    var properties: [String: JSONSchema]?
    var required: [String]?
    var items: PassthroughContainer?
    var description: String?
    var enumValues: [Value]?
    var format: String?
    var minimum: Double?
    var maximum: Double?
    var minLength: Int?
    var maxLength: Int?
    var pattern: String?
    var additionalProperties: AdditionalPropertiesType?
    
    var contentEncoding: String?
    var contentMediaType: String?
    
    // Used for unions
    var anyOf: [JSONSchema]?
    var oneOf: [JSONSchema]?
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case schema = "$schema"
        case title
        case type
        case properties
        case required
        case items
        case description
        case enumValues = "enum"
        case format
        case minimum
        case maximum
        case minLength
        case maxLength
        case pattern
        case additionalProperties = "additionalProperties"
        case anyOf
        case oneOf
    }
    
    public init(id: String? = nil, schema: String? = nil, title: String? = nil, type: JSONSchemaType? = nil, properties: [String : JSONSchema]? = nil,
                required: [String]? = nil, items: JSONSchema? = nil, description: String? = nil, enumValues: [Value]? = nil, format: String? = nil,
                minimum: Double? = nil, maximum: Double? = nil, minLength: Int? = nil, maxLength: Int? = nil, pattern: String? = nil,
                additionalProperties: AdditionalPropertiesType? = nil, anyOf: [JSONSchema]? = nil, oneOf: [JSONSchema]? = nil) {
        self.id = id
        self.schema = schema
        self.title = title
        self.type = type
        self.properties = properties
        self.required = required
        self.items = .contain(items)
        self.description = description
        self.enumValues = enumValues
        self.format = format
        self.minimum = minimum
        self.maximum = maximum
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.additionalProperties = additionalProperties
        
        self.oneOf = oneOf
        self.anyOf = anyOf
    }
    
    public var debugDescription: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            
            let jsonForPrint = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)
            let prettyPrintData = try JSONSerialization.data(withJSONObject: jsonForPrint, options: .prettyPrinted)
            
            return String(data: prettyPrintData, encoding: .utf8) ?? ""
        }
        catch {
            return ""
        }
    }
}
 
