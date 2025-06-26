//
//  JsonSchemaCreator.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//
import Foundation

enum JSONSchemaError: Error {
    case typeWasNotCodable(String)
    case unrecognizedType
    case doesNotConformToProducesUnionJSONSchema(String)
    case hasNoIterableCases(String)
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
public class JsonSchemaCreator {

#warning("Eat throws for now until we can fix SwiftyPrompts")
    /// Special case that handles enums, it basically enumerates each enum and creates a schema for it and then adds them to a union type
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - id: <#id description#>
    ///   - schema: <#schema description#>
    ///   - propertyDescriptions: <#propertyDescriptions description#>
    /// - Returns: <#description#>
    public static func createJSONSchema<T: Codable>(from type: T.Type, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil ) -> JSONSchema where T: ProducesUnionJSONSchema {
        guard let exampleCase = T.allCases.first else {
            #warning("Eat error for now but reinstate when we update to 0.3 and make all dependencies adhere")
//            throw JSONSchemaError.hasNoIterableCases("\(T.self)")
            return .init()
        }
        return try! _createJSONSchema(for: exampleCase, id: id, schema: schema, propertyDescriptions: propertyDescriptions)
    }
    
    public static func createJSONSchema<T: Codable>(from type: T.Type, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil )  -> JSONSchema where T: ProducesJSONSchema {
        try! _createJSONSchema(for: T.exampleValue, id: id, schema: schema, propertyDescriptions: propertyDescriptions)
    }
    
    // Function to convert a Codable object to JSONSchema
    public static func createJSONSchema<T: Codable>(for object: T, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil )  -> JSONSchema {
        try! _createJSONSchema(for: object, id: id, schema: schema, propertyDescriptions: propertyDescriptions)
    }
     
    static private func getRawValueType<T: RawRepresentable>(for enumType: T.Type) -> String {
        return "\(T.RawValue.self)"
    }
    
    static private func createBasicEnumSchema<E>(for object: E, id: String?, schema: String?) -> JSONSchema where E: CaseIterable {
        
        var schemaType: JSONSchemaType = .string
        
        // There are 2 types of basic enums those that are `default` and RawRepresentables. Defaults are always strings in jsonschema
        if let rawEnum = E.self as? RawRepresentable.Type {
            let rawTypeString = getRawValueType(for: rawEnum)
            schemaType = .init(rawValue: rawTypeString) ?? .string
        }
        else {
            schemaType = .string
        }
        
        
        let caseLabels: [String] = E.allCases.map { "\($0.self)" }
        let jsonSchema = JSONSchema(id: id, schema: schema, type: .string, enumValues: caseLabels)
        return jsonSchema
    }
    
    
    static private func createAssociatedTypeEnumSchema<E>(for object: E, id: String?, schema: String?) throws -> JSONSchema where E: CaseIterable, E: ProducesUnionJSONSchema {
      
        
        let allSchemas = try E.allCases.map { caseValue in
            let label = "\(caseValue.self)"
            var schema = try Self._createJSONSchema(for: caseValue)
            schema.id = label
            return schema
        }
        
        return JSONSchema(id: id, schema: schema, type: .object, oneOf: allSchemas)
    }
    
    static func handleEnums<E>(enumObject: E, id: String?, schema: String?, propertyDescriptions: [String: String]?) throws -> JSONSchema where E: CaseIterable, E: Codable {
        // get all the types
        var basicEnums = [E]()
        var associatedTypeEnums = [E]()
        
        var fullSchema = JSONSchema(id: id, schema: schema)
        
        E.allCases.forEach { enumObj in
            let mirror = Mirror(reflecting: enumObj)
            if mirror.children.isEmpty {
                basicEnums.append(enumObj)
            }
            else {
                associatedTypeEnums.append(enumObj)
            }
        }
        
        if !basicEnums.isEmpty {
            
            // Create the basic enums schema
            var schemaType: JSONSchemaType = {
                
                // There are 2 types of basic enums those that are `default` and RawRepresentables. Defaults are always strings in jsonschema
                if let rawEnum = E.self as? RawRepresentable.Type {
                    let rawTypeString = getRawValueType(for: rawEnum)
                    return .init(rawValue: rawTypeString) ?? .string
                }
                else {
                    return .string
                }
            }()
            
            
            let caseLabels: [String] = E.allCases.map { "\($0.self)" }
            fullSchema.type = .string
            fullSchema.enumValues = caseLabels
        }
        
        
        if !associatedTypeEnums.isEmpty {
            let allSchemas = try associatedTypeEnums.map { caseValue in
                let label = "\(caseValue.self)"
                
                var props = [String: JSONSchema]()
                var required = [String]()
                var schema = try Self._createJSONSchemaNoEnums(for: caseValue, id: id, schema: schema,
                                                               propertyDescriptions: propertyDescriptions, properties: &props, required: &required)
                schema.id = label
                return schema
            }
            
            fullSchema.type = .object
            fullSchema.oneOf = allSchemas
        }
        
        
        return fullSchema
    }
   
    
    static private func _createJSONSchema<T: Codable>(for object: T, id: String? = nil, schema: String? = nil, propertyDescriptions: [String: String]? = nil) throws -> JSONSchema {
        
        let mirror = Mirror(reflecting: object)
        
        var properties = [String: JSONSchema]()
        var required = [String]()
        
        // Handle enums. We shouldn't need to check for case iterable because they should all really adhere
        if mirror.displayStyle == .enum, let enumObject = object as? (CaseIterable & Codable) {
            let jsonSchema = try handleEnums(enumObject: enumObject, id: id, schema: schema, propertyDescriptions: propertyDescriptions)
            properties["\(T.self)"] = jsonSchema
            //            // Get all the types
            //            enum
            //
            //
            //            #warning("Not all cases are basic we can have a mix, so we need to handle that situation")
            //            // Handle basic enums
            //            if mirror.children.count <= 0 {
            //                let jsonSchema = createBasicEnumSchema(for: enumObject, id: id, schema: schema)
            //                properties["\(T.self)"] = jsonSchema
            //            }
            //            else {
            //                // Handle enums with associated types. For this we go through and create a schema for each type. They need to adhere to 'ProducesUnionJSONSchema' for associatedTypes
            //                guard let associatedEnum = enumObject as? ProducesUnionJSONSchema else {
            //                    throw JSONSchemaError.doesNotConformToProducesUnionJSONSchema("\(enumObject.self)")
            //                }
            //                let jsonSchema = try createAssociatedTypeEnumSchema(for: associatedEnum, id: id, schema: schema)
            //                properties["\(T.self)"] = jsonSchema
            //            }
        }
        
        //        // If it's an basic enum, i.e. no associated values we need to handle a little differently
        //        if mirror.displayStyle == .enum, mirror.children.count <= 0, let enumObject = object as? CaseIterable { //let caseEnum = T.self as? CaseIterable.Type {
        //            let jsonSchema = createEnumSchema(for: enumObject, id: id, schema: schema)
        //            properties["\(T.self)"] = jsonSchema
        //        }
        
        return try _createJSONSchemaNoEnums(for: object, id: id, schema: schema, propertyDescriptions: propertyDescriptions,
                                            properties: &properties, required: &required)
    }
    
    static private func _createJSONSchemaNoEnums<T>(for object: T, id: String? = nil, schema: String? = nil, propertyDescriptions: [String: String]? = nil,
    properties: inout [String: JSONSchema], required: inout [String]) throws -> JSONSchema {
        
        
        let mirror = Mirror(reflecting: object)
        
        for child in mirror.children {
            
            guard var label = child.label else { continue }
            
            let value = child.value
            
            var jsonSchema: JSONSchema
            
            // Ignore the field
            if let _ = value as? IgnorableField {
                continue
            }
            
            if let describedProp = value as? SchemaInfoProtocol {
                
                guard let value = describedProp.subjectValue else { continue }
                
                guard var newJsonSchema = try extractSchema(from: value, propertyDescriptions: propertyDescriptions) else { continue }
                
                newJsonSchema.description = describedProp.description
                jsonSchema = newJsonSchema
                
                if label.hasPrefix("_") {
                    label = String(label.dropFirst())
                }
            }
            else {
                guard let newJsonSchema = try extractSchema(from: value, propertyDescriptions: propertyDescriptions) else { continue }
                jsonSchema = newJsonSchema
            }
            
            // Allow additional properties if it's a dynamic schema
            if value is DynamicSchema {
                jsonSchema.additionalProperties = true
            }
            
            if label != "wrappedValue" {
                properties[label] = jsonSchema
            }
            
            required.append(label)
            
            if !Mirror(reflecting: child.value).children.isEmpty {
                try _createJSONSchemaNoEnums(for: child.value, properties: &properties, required: &required)
            }
        }
        
//        return JSONSchema(id: id,
//                          schema: schema,
//                          type: .object,
//                          properties: properties,
//                          required: required)
        
//        var topLevelSchema = try extractSchema(from: object, propertyDescriptions: propertyDescriptions) ??  JSONSchema(id: id, schema: schema, type: .object, properties: properties, required: required)
//        
//        topLevelSchema.schema = schema
//        topLevelSchema.properties = properties
//        topLevelSchema.required = required
//        return topLevelSchema
        
        var finalSchema = try extractBasicTypeSchema(from: object, propertyDescriptions: propertyDescriptions) ?? JSONSchema(type: .object)
        finalSchema.schema = schema
        finalSchema.id = id
        finalSchema.properties = properties
        finalSchema.required = required
        
//        return JSONSchema(id: id, schema: schema, type: .object, properties: properties, required: required)
        return finalSchema
    }
    
    private static func handleOneOfUnion(oneOfUnion: JSONSchemaOneOfDiscriminatedUnion) throws -> JSONSchema? {
        
        var jsonSchema = JSONSchema()
        jsonSchema.type = .object
        jsonSchema.oneOf = try oneOfUnion.allowedTypes.compactMap({ sType in
            return try createJSONSchema(for: sType.exampleValue)
        })
        return jsonSchema
    }
    
    private static func handleAnyOfUnion(anyOfUnion: JSONSchemaAnyOfDiscriminatedUnion) throws -> JSONSchema? {
        
        var jsonSchema = JSONSchema()
        jsonSchema.type = .object
        jsonSchema.anyOf = try anyOfUnion.allowedTypes.compactMap({ sType in
            return try createJSONSchema(for: sType.exampleValue)
        })
        
        return jsonSchema
    }
    
    private static func extractBasicTypeSchema<T>(from value: T, propertyDescriptions: [String: String]?) throws -> JSONSchema? where T: Any {
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
            return nil
        }
        
        return jsonSchema
    }
    
    private static func extractSchema<T>(from value: T, propertyDescriptions: [String: String]?) throws -> JSONSchema? where T: Any {
        
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
        case let EnumType as ProducesUnionJSONSchema.Type:
            jsonSchema = createJSONSchema(from: EnumType)
        case is IgnoreFieldInSchema<Any>.Type:
            print("Ignored field")
            break // we do nothing with this
        default:
            
            // Handle cases where we didn't match on type and need the value to produce the schema
            switch value {
            case let uValue as JSONSchemaOneOfDiscriminatedUnion:
                guard let schema = try handleOneOfUnion(oneOfUnion: uValue) else {
                    break
                }
                jsonSchema = schema
            case let uValue as JSONSchemaAnyOfDiscriminatedUnion:
                guard let schema = try handleAnyOfUnion(anyOfUnion: uValue) else {
                    break
                }
                jsonSchema = schema
            case let array as [JSONSchemaOneOfDiscriminatedUnion]:
                guard let arrayElement = array.first else { break }
                guard let schema = try handleOneOfUnion(oneOfUnion: arrayElement) else { break }
                jsonSchema.type = .array
                jsonSchema.anyOf = [schema]
            case let array as [JSONSchemaAnyOfDiscriminatedUnion]:
                guard let arrayElement = array.first else { break }
                guard let schema = try handleAnyOfUnion(anyOfUnion: arrayElement) else { break }
                jsonSchema.type = .array
                jsonSchema.anyOf = [schema]
            case let array as [Codable]:
                guard let arrayElement = array.first else { return nil }
                jsonSchema.type = .array
                jsonSchema.items = .contain(try _createJSONSchema(for: arrayElement, propertyDescriptions: propertyDescriptions))
//            case let codValue as Codable:
//                var newJsonSchema = try _createJSONSchema(for: codValue, propertyDescriptions: propertyDescriptions)
//                newJsonSchema.description = jsonSchema.description
//                jsonSchema = newJsonSchema
            default:
                break
            }
        }
        
        return jsonSchema
    }
}
