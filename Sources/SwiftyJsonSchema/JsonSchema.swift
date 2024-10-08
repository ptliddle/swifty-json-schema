//
//  JsonSchema.swift
//
//
//  Created by Peter Liddle on 8/27/24.
//

import Foundation

// Represents the type of a JSON Schema
public enum JSONSchemaType: String, Codable {
    case object
    case array
    case string
    case number
    case integer
    case boolean
    case null
}

// A struct to represent a JSON Schema
open class JSONSchema: Codable, CustomDebugStringConvertible {
    
    var id: String?
    var schema: String?
    
    var title: String?
    var type: JSONSchemaType?
    var properties: [String: JSONSchema]?
    var required: [String]?
    var items: JSONSchema?
    var description: String?
    var enumValues: [String]?
    var format: String?
    var minimum: Double?
    var maximum: Double?
    var minLength: Int?
    var maxLength: Int?
    var pattern: String?
    var additionalProperties: Bool?
    
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
    }
    
    public init(id: String? = nil, schema: String? = nil, title: String? = nil, type: JSONSchemaType? = nil, properties: [String : JSONSchema]? = nil, required: [String]? = nil, items: JSONSchema? = nil, description: String? = nil, enumValues: [String]? = nil, format: String? = nil, minimum: Double? = nil, maximum: Double? = nil, minLength: Int? = nil, maxLength: Int? = nil, pattern: String? = nil, additionalProperties: Bool = false) {
        self.id = id
        self.schema = schema
        self.title = title
        self.type = type
        self.properties = properties
        self.required = required
        self.items = items
        self.description = description
        self.enumValues = enumValues
        self.format = format
        self.minimum = minimum
        self.maximum = maximum
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.additionalProperties = additionalProperties
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
 
