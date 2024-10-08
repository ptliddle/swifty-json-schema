//
//  JsonSchemaCreator.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//

import Foundation

public class JsonSchemaCreator {
    
    // Function to convert a Codable object to JSONSchema
    public static func createJSONSchema<T: Codable>(for object: T, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil ) -> JSONSchema {
        _createJSONSchema(for: object, id: id, schema: schema, propertyDescriptions: propertyDescriptions)
    }
     
    private static func _createJSONSchema<T: Codable>(for object: T, id: String? = nil, schema: String? = nil, propertyDescriptions: [String: String]? = nil) -> JSONSchema {
        
        let mirror = Mirror(reflecting: object)
        
        var properties = [String: JSONSchema]()
        var required = [String]()
        
        func extractSchema(from value: Any) -> JSONSchema? {
            
            var jsonSchema = JSONSchema()
            let subjectType = type(of: value)
            
            switch subjectType {
            case is String.Type:
                jsonSchema.type = .string
            case is Int.Type, is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type:
                jsonSchema.type = .integer
            case is Float.Type, is Double.Type:
                jsonSchema.type = .number
            case is Bool.Type:
                jsonSchema.type = .boolean
            case is Optional<Any>.Type:
                jsonSchema.type = .null
            default:
                if let codArray = value as? [Codable] {
                    guard let arrayElement = codArray.first else { return nil }
                    jsonSchema.type = .array
                    jsonSchema.items = _createJSONSchema(for: arrayElement, propertyDescriptions: propertyDescriptions)
                }
                else if let codValue = value as? Codable {
                    let newJsonSchema = _createJSONSchema(for: codValue, propertyDescriptions: propertyDescriptions)
                    newJsonSchema.description = jsonSchema.description
                    jsonSchema = newJsonSchema
                }
            }
            
            return jsonSchema
        }
        
        for child in mirror.children {
            
            guard var label = child.label else { continue }
            
            let value = child.value
            
            let subjectType = type(of: value)
            
            var jsonSchema: JSONSchema
            
            if let describedProp = value as? SchemaInfoProtocol {
                
                guard let value = describedProp.subjectValue else { continue }
                
                guard let newJsonSchema = extractSchema(from: value) else { continue }
                
                newJsonSchema.description = describedProp.description
                jsonSchema = newJsonSchema
                
                if label.hasPrefix("_") {
                    label = String(label.dropFirst())
                }
            }
            else {
                guard let newJsonSchema = extractSchema(from: value) else { continue }
                jsonSchema = newJsonSchema
            }
            
            if label != "wrappedValue" {
                properties[label] = jsonSchema
            }
            
            required.append(label)
        }

        return JSONSchema(id: id,
                          schema: schema,
                          type: .object,
                          properties: properties,
                          required: required)
    }
}
