//
//  JsonSchemaBuilder.swift
//  SwiftyJsonSchema
//
//  Created by Peter Liddle on 6/25/25.
//


public class JsonSchemaBuilder {
    
    var schema: String = "http://json-schema.org/draft-07/schema#"
    
    public init(schema: String = "http://json-schema.org/draft-07/schema#") {
        self.schema = schema
    }
    
    func getSchemaType<Value>(for value: Value) -> JSONSchema? {
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
        case is IgnoreFieldInSchema<Any>.Type:
            print("Ignored field")
            break // we do nothing with this
        default:
            return nil
        }
        
        return jsonSchema
    }
    
    private func getRawValueType<T: RawRepresentable>(for enumType: T.Type) -> String {
        return "\(T.RawValue.self)"
    }
    
    func handle<E>(enumObject: E) throws -> JSONSchema where E: Codable, E: CaseIterable  {
        
        let id: String? = nil
        
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
                var schema = try createSchema(for: caseValue)
                schema.id = label
                return schema
            }
            
            fullSchema.type = .object
            fullSchema.oneOf = allSchemas
        }
        
        
        return fullSchema
    }
    
    
    
    public func createSchema<O>(for oType: O.Type) throws -> JSONSchema where O: ProducesUnionJSONSchema {
        guard let firstObject = O.allCases.first else {
            fatalError("Throw error here")
        }
        return try createSchema(for: firstObject)
    }
    
//    public func createSchema<O>(for object: O) throws -> JSONSchema where O: ProducesJSONSchema {
//        return try createSchema(for: object)
//    }
//    
    private var properties = [String: JSONSchema]()
    private var required = [String]()
    
    private func handleModifiers<Value>(for value: Value, schema: inout JSONSchema) {
        if value is DynamicSchema {
            schema.additionalProperties = true
        }
    }
    
    public func createSchema<O>(for object: O, jsonSchema: JSONSchema? = nil) throws -> JSONSchema {
        
//        properties = [:]
//        required = []
        
        let mirror = Mirror(reflecting: object)
        let oType = type(of: object)
        let displayStyle = mirror.displayStyle
        let children = mirror.children
        
        // If no children probably base type or enum
        if children.isEmpty {
            
            if let displayStyle = mirror.displayStyle {
                switch displayStyle {
                    
                case .struct, .class, .collection, .dictionary, .set:
                    // These need no special handling
                    let schema = try createSchema(for: object)
                    jsonSchema.required = .contain(schema)
                case .enum:
                    guard let enumObject = object as? (CaseIterable & Codable) else {
                        throw JSONSchemaError.hasNoIterableCases("\(object)")
                    }
                    let schema = try handle(enumObject: enumObject)
                    jsonSchema.items = .contain(schema)
                case .tuple:
                    break
                case .optional:
                    break
                }
            }
            else {
                // Probably a basic type so let's get it
                var schema = getSchemaType(for: object)
                jsonSchema.properties = properties
                jsonSchema.required = required
                handleModifiers(for: object, schema: &jsonSchema)
            }
        }
        else {
            
            func shouldSkip<Value>(label: String, value: Value) -> Bool {
                if let _ = value as? IgnorableField {
                    return true
                }
                
                if label == "wrappedValue" {
                    return true
                }
                
                return false
            }
            
            // If it has children, go through and extract base types
            for child in mirror.children {
                let value = child.value
//
                guard let label = child.label, !shouldSkip(label: label, value: value) else {
                    continue
                }
                
                try createSchema(for: value)
            }
//
//            for child in mirror.children {
//                
//                guard var label = child.label else { continue }
//                
//                let value = child.value
//                
//                var jsonSchema: JSONSchema
//                
//                // Ignore the field
//                if let _ = value as? IgnorableField {
//                    continue
//                }
//                
//                if let describedProp = value as? SchemaInfoProtocol {
//                    
//                    guard let value = describedProp.subjectValue else { continue }
//                    
//                    guard var newJsonSchema = try extractSchema(from: value, propertyDescriptions: propertyDescriptions) else { continue }
//                    
//                    newJsonSchema.description = describedProp.description
//                    jsonSchema = newJsonSchema
//                    
//                    if label.hasPrefix("_") {
//                        label = String(label.dropFirst())
//                    }
//                }
//                else {
//                    guard let newJsonSchema = try extractSchema(from: value, propertyDescriptions: propertyDescriptions) else { continue }
//                    jsonSchema = newJsonSchema
//                }
//                
//                // Allow additional properties if it's a dynamic schema
//                if value is DynamicSchema {
//                    jsonSchema.additionalProperties = true
//                }
//                
//                if label != "wrappedValue" {
//                    properties[label] = jsonSchema
//                }
//                
//                required.append(label)
//                
//                if !Mirror(reflecting: child.value).children.isEmpty {
//                    try _createJSONSchemaNoEnums(for: child.value, properties: &properties, required: &required)
//                }
//            }
        }
        
        return jsonSchema
    }
}
