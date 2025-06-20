//
//  JsonSchemaCreator.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//
import Foundation

public class JsonSchemaCreator {
    
    public static func createJSONSchema<T: Codable>(from type: T.Type, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil ) -> JSONSchema where T: ProducesJSONSchema {
        _createJSONSchema(for: T.exampleValue, id: id, schema: schema, propertyDescriptions: propertyDescriptions)
    }
    
    // Function to convert a Codable object to JSONSchema
    public static func createJSONSchema<T: Codable>(for object: T, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil ) -> JSONSchema {
        _createJSONSchema(for: object, id: id, schema: schema, propertyDescriptions: propertyDescriptions)
    }
     
    private static func _createJSONSchema<T: Codable>(for object: T, id: String? = nil, schema: String? = nil, propertyDescriptions: [String: String]? = nil) -> JSONSchema {
        
        let mirror = Mirror(reflecting: object)
        
        var properties = [String: JSONSchema]()
        var required = [String]()
        
        func handleOneOfUnion(oneOfUnion: JSONSchemaOneOfDiscriminatedUnion) -> JSONSchema? {
            
            var jsonSchema = JSONSchema()
            let subjectType = type(of: object)
            jsonSchema.type = .object
            jsonSchema.oneOf = oneOfUnion.allowedTypes.compactMap({ sType in
                return createJSONSchema(for: sType.exampleValue)
            })
            return jsonSchema
        }
        
        func handleAnyOfUnion(anyOfUnion: JSONSchemaAnyOfDiscriminatedUnion) -> JSONSchema? {
            
            var jsonSchema = JSONSchema()
            let subjectType = type(of: object)
            jsonSchema.type = .object
            jsonSchema.anyOf = anyOfUnion.allowedTypes.compactMap({ sType in
                return createJSONSchema(for: sType.exampleValue)
            })
            
            return jsonSchema
        }
        
        func extractSchema(from value: Any) -> JSONSchema? {
            
            var jsonSchema = JSONSchema()
            let subjectType = type(of: value)
            
            switch subjectType {
            case is String.Type:
                jsonSchema.type = .string
            case is [String].Type: // And array of primitive type string
                jsonSchema.type = .array
                jsonSchema.items = .contain(JSONSchema(type: .string))
            case is Int.Type, is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type:
                jsonSchema.type = .integer
            case is [Int].Type, is [Int8].Type, is [Int16].Type, is [Int32].Type, is [Int64].Type: // And array of primitive integer types
                jsonSchema.type = .array
                jsonSchema.items =  .contain(JSONSchema(type: .integer))
            case is Float.Type, is Double.Type:
                jsonSchema.type = .number
            case is [Float].Type, is [Double].Type: // And array of primitive float types
                jsonSchema.type = .array
                jsonSchema.items = .contain( JSONSchema(type: .number))
            case is Bool.Type:
                jsonSchema.type = .boolean
            case is [Bool].Type: // And array of primitive type Bool
                jsonSchema.type = .array
                jsonSchema.items =  .contain(JSONSchema(type: .boolean))
            case is Optional<Any>.Type:
                jsonSchema.type = .null
            default:
                
                // Handle cases where we didn't match on type and need the value to produce the schema
                switch value {
                case let uValue as JSONSchemaOneOfDiscriminatedUnion:
                    guard let schema = handleOneOfUnion(oneOfUnion: uValue) else {
                        break
                    }
                    jsonSchema = schema
                case let uValue as JSONSchemaAnyOfDiscriminatedUnion:
                    guard let schema = handleAnyOfUnion(anyOfUnion: uValue) else {
                        break
                    }
                    jsonSchema = schema
                case let array as [JSONSchemaOneOfDiscriminatedUnion]:
                    guard let arrayElement = array.first else { break }
                    guard let schema = handleOneOfUnion(oneOfUnion: arrayElement) else { break }
                    jsonSchema.type = .array
                    jsonSchema.anyOf = [schema]
                case let array as [JSONSchemaAnyOfDiscriminatedUnion]:
                    guard let arrayElement = array.first else { break }
                    guard let schema = handleAnyOfUnion(anyOfUnion: arrayElement) else { break }
                    jsonSchema.type = .array
                    jsonSchema.anyOf = [schema]
                case let array as [Codable]:
                    guard let arrayElement = array.first else { return nil }
                    jsonSchema.type = .array
                    jsonSchema.items = .contain(_createJSONSchema(for: arrayElement, propertyDescriptions: propertyDescriptions))
                case let codValue as Codable:
                    var newJsonSchema = _createJSONSchema(for: codValue, propertyDescriptions: propertyDescriptions)
                    newJsonSchema.description = jsonSchema.description
                    jsonSchema = newJsonSchema
                default:
                    break
                }
            }
            
            return jsonSchema
        }

        for child in mirror.children {
            
            guard var label = child.label else { continue }
            
            let value = child.value
            
            var jsonSchema: JSONSchema
            
            if let describedProp = value as? SchemaInfoProtocol {
                
                guard let value = describedProp.subjectValue else { continue }
                
                guard var newJsonSchema = extractSchema(from: value) else { continue }
                
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
