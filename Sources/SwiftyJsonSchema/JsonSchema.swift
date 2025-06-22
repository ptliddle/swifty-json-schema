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


/// Used when you need to reference a JSONSchema but you can't directly reference yourself in a struct in Swift
public final class PassthroughContainer: Codable, Sendable {
    let items: JSONSchema?
    
    init(_ items: JSONSchema?) {
        self.items = items
    }
    
    static func contain(_ items: JSONSchema?) -> Self? {
        return Self(items) ?? nil
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
    var enumValues: [String]?
    var format: String?
    var minimum: Double?
    var maximum: Double?
    var minLength: Int?
    var maxLength: Int?
    var pattern: String?
    var additionalProperties: Bool?
    
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
    
    public init(id: String? = nil, schema: String? = nil, title: String? = nil, type: JSONSchemaType? = nil, properties: [String : JSONSchema]? = nil, required: [String]? = nil, items: JSONSchema? = nil, description: String? = nil, enumValues: [String]? = nil, format: String? = nil, minimum: Double? = nil, maximum: Double? = nil, minLength: Int? = nil, maxLength: Int? = nil, pattern: String? = nil, additionalProperties: Bool = false, anyOf: [JSONSchema] = [], oneOf: [JSONSchema] = []) {
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
 
