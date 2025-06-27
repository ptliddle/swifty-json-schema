//
//  JSONSchemaGenerator.swift
//
//
//  Created on 6/26/25.
//

import Foundation

enum JSONSchemaGenerationError: Error {
    case notACodableType(String)
    case notCaseIterableEnum(String)
    case notCaseIterableOrCodable(String)
    case noEnumCases
    case unknownBaseType
    case invalidCollection(String)
    case invalidOptional(String)
}


/// A class that generates JSON Schema from Swift Codable types
public class JSONSchemaGenerator {
    
    /// Configuration options for JSON Schema generation
    public struct Configuration {
        /// The JSON Schema version to use
        public let schemaVersion: String
        
        /// The schema ID to use
        public let schemaId: String?
        
        /// Whether to include descriptions from property wrappers
        public let includeDescriptions: Bool
        
        /// Initialize with default values
        public init(schemaVersion: String = "http://json-schema.org/draft-07/schema#", schemaId: String? = nil, includeDescriptions: Bool = true) {
            self.schemaVersion = schemaVersion
            self.schemaId = schemaId
            self.includeDescriptions = includeDescriptions
        }
    }
    
    /// The configuration for this generator
    private let configuration: Configuration
    
    /// Initialize with the given configuration
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    func handleEnums<E>(enumObject: E) throws -> JSONSchema where E: CaseIterable, E: Codable {
        
        func getRawValueType<T: RawRepresentable>(for enumType: T.Type) -> String {
            return "\(T.RawValue.self)"
        }
            
        var schema = JSONSchema()
        
        // get all the types
        var basicEnums = [E]()
        var associatedTypeEnums = [E]()
        
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
            // There are 2 types of basic enums those that are `default` and RawRepresentables. Defaults are always strings in jsonschema
            var schemaType: JSONSchemaType = try {
                
                if let rawEnumObject = enumObject as? (RawRepresentable & Codable) {
                    let type = type(of: rawEnumObject)
                    let rawTypeString = getRawValueType(for: type)
                    let jsonType = try JSONSchemaType(withRawEnumType: rawTypeString)
                    return jsonType
                }
                else {
                    return .string
                }
            }()
                
            let caseLabels = E.allCases.compactMap({ enumObject in
                if let rawEnumObject = enumObject as? (any RawRepresentable & Codable) {
                    return Value(from: rawEnumObject.rawValue as? Codable)
                } 
                else {
                    // For non-RawRepresentable enums, use the string representation
                    return Value.string("\(enumObject)")
                }
            })
            
            schema.enumValues = caseLabels
            schema.type = schemaType
        }
        
        
        if !associatedTypeEnums.isEmpty {
            let allSchemas = try associatedTypeEnums.map { caseValue in
                let label = "\(caseValue.self)"
                
                var props = [String: JSONSchema]()
                var required = [String]()
                var schema = try generateSchema(for: caseValue)
                
                schema.id = label
                return schema
            }
            
            schema.type = .object
            schema.oneOf = allSchemas
        }
        
        return schema
    }
   
    
    /// Generate a JSON Schema for the given Codable object
    /// - Parameters:
    ///   - object: The object to generate a schema for
    /// - Returns: A JSONSchema object representing the schema
    public func generateSchema<T>(for object: T) throws -> JSONSchema where T: Codable {
        // Create a base schema with the configuration values
        let schema = JSONSchema(id: configuration.schemaId, schema: configuration.schemaVersion, type: .object)
        return try _generateSchema(for: object, schema: schema)
    }
    
    public func generateSchema<T>(for object: T) throws -> JSONSchema where T: CaseIterable {
        // Create a base schema with the configuration values
        let schema = JSONSchema(id: configuration.schemaId, schema: configuration.schemaVersion, type: .object)
        return try _generateSchema(for: object, schema: schema)
    }
     
    private func _generateSchema<T>(for object: T, schema: JSONSchema? = nil) throws -> JSONSchema where T: Any {
        
        // Create dictionaries to store properties and required fields
        var properties: [String: JSONSchema] = [:]
        var required: [String] = []
        
        // First things first, check if it's a primitive type and we can handle based on the information we already have without needing reflection
        if let schema = try generateSchemaForBaseTypes(object) {
            return schema // We have a base type so return it
        }
        
        
        
        // Use Mirror to reflect on the object's properties
        let mirror = Mirror(reflecting: object)
        
        // First we check if we're at the base, i.e. a basic type. It should have no children
        // Dictionaries and Arrays are considered base types
        guard !mirror.children.isEmpty else {
            return try generateSchemaForBaseTypes(object)!
        }
        
        var parentOptional = false
        
        // Now handle complex base types, i.e. enum, dictionary and array
        if let displayStyle =  mirror.displayStyle {
            switch displayStyle {
            case .struct, .class:
                break // struct and class can just be handled normally by parsing their chilren recursively
            case .enum, .tuple, .dictionary, .set:
                print("SPECIAL TYPE NOT YET HANDLED")
            case .optional:
                print("HANDLE OPTIONAL")
                parentOptional = true
                // Optionals are handled as a base type
//                guard let opt = object as Optional<Any> else {
//                    throw JSONSchemaGenerationError.invalidOptional("\(type(of:object))")
//                }
                break
   
            case .collection:
                guard let array = object as? [Any] else {
                    throw JSONSchemaGenerationError.invalidCollection("\(type(of:object))")
                }
                
                // For array we need to get a collection element and recurse on it
                // If the array is empty, we can't determine the item type
                if array.isEmpty {
                    return JSONSchema(type: .array)
                }
                
                // Get the first item to determine array item type
                guard let firstItem = array.first else {
                    return JSONSchema(type: .array)
                }
                
                // Check that the item is Codable
                guard let arrayItem = firstItem as? Codable else {
                    throw JSONSchemaGenerationError.notACodableType("\(type(of:firstItem.self))")
                }
                
                // Generate schema for the item
                let itemSchema = try _generateSchema(for: arrayItem) //try generateSchemaForProperty(arrayItem)
                return JSONSchema(type: .array, items: itemSchema)
            }
        }
        

        var schema = schema ?? JSONSchema(type: .object) // ?? generateSchemaForProperty(object)
        
        // Handle each of the types children
        try handleChildren()
        
        func handleChildren() throws {
            // Process each child in the mirror
            for child in mirror.children {
                // Skip if the property has no label
                guard let propertyName = child.label else { continue }
                
                // Clean the property name (remove underscore prefix for property wrappers)
                let cleanPropertyName = cleanPropertyName(propertyName)
                
                let value = child.value
//                guard let value = child.value as? Codable else {
//                    throw JSONSchemaGenerationError.notACodableType("\(type(of: child.value))")
//                }
              
                if isOptional(child.value) {
                    let propertySchema = try generateSchemaForBaseTypes(value)
                    properties[cleanPropertyName] = propertySchema
                }
                else if isEnum(child.value){
                    guard let value = child.value as? (any CaseIterable & Codable) else {
                        throw JSONSchemaGenerationError.notCaseIterableEnum("\(child.value.self)")
                    }
                    let schema = try handleEnums(enumObject: value)
                    properties[cleanPropertyName] = schema
                }
                else {
                    // Generate schema for this property
                    let propertySchema = try _generateSchema(for: value)
                    properties[cleanPropertyName] = propertySchema
                    if !parentOptional {
                        required.append(cleanPropertyName)
                    }
                }
            }
            
            // Add properties and required fields to the schema
            schema.properties = properties
            schema.required = required
        }
        
        return schema
    }
    
    /// Generate a JSON Schema for the given Codable type
    /// - Parameters:
    ///   - type: The type to generate a schema for
    /// - Returns: A JSONSchema object representing the schema
    public func generateSchema<T: ProducesJSONSchema>(for type: T.Type) throws -> JSONSchema {
        let instance = T.exampleValue
        return try _generateSchema(for: instance)
    }
    
    public func generateSchema<T: CaseIterable>(for type: T.Type) throws -> JSONSchema {
        
        var schema = JSONSchema()
        
        let subSchemas = try T.allCases.map { enumdCase in
            try _generateSchema(for: enumdCase)
        }
        
        schema.type = .object
        schema.oneOf = subSchemas
        return schema
    }
    
    // MARK: - Private Methods
    
    /// Cleans a property name by removing any leading underscore
    /// - Parameter propertyName: The raw property name
    /// - Returns: The cleaned property name
    private func cleanPropertyName(_ propertyName: String) -> String {
        return propertyName.hasPrefix("_") ? String(propertyName.dropFirst()) : propertyName
    }
    
    /// Determines if a value is an Optional type
    /// - Parameter value: The value to check
    /// - Returns: True if the value is an Optional, false otherwise
    private func isOptional(_ value: Any) -> Bool {
        return Mirror(reflecting: value).displayStyle == .optional
    }
    
    
    private func isEnum(_ value: Any) -> Bool {
        return Mirror(reflecting: value).displayStyle == .enum
    }
    
   
//    private func handleComplesBaseTypes<T>(_ value: T) throws -> JSONSchema where T: Any {
//        // Handle complex base types like array, dictionary and optional
//        
//    }
//    
    
    /// Generate a JSON Schema for a property value
    /// - Parameter value: The property value to generate a schema for
    /// - Returns: A JSONSchema object representing the property
    private func generateSchemaForBaseTypes<T>(_ value: T) throws -> JSONSchema? where T: Any {
        // Handle optionals by unwrapping and recursing
//        if isOptional(value) {
//            let mirror = Mirror(reflecting: value)
//            if let firstChild = mirror.children.first {
//                guard let value = firstChild.value as? Codable else {
//                    throw JSONSchemaGenerationError.notACodableType("\(type(of: firstChild))")
//                }
//                return try generateSchemaForBaseTypes(value)
//            } else {
//                // For nil optionals, return a placeholder schema
//                return JSONSchema(type: .object)
//            }
//        }
        
        // Handle basic primitive types
        switch value {
        case is String:
            return JSONSchema(type: .string)
            
        case is Int, is Int8, is Int16, is Int32, is Int64, is UInt, is UInt8, is UInt16, is UInt32, is UInt64:
            return JSONSchema(type: .integer)
            
        case is Float, is Double, is Decimal:
            return JSONSchema(type: .number)
            
        case is Bool:
            return JSONSchema(type: .boolean)
            
        // Foundation types with special handling
        case is URL:
            var schema = JSONSchema(type: .string)
            schema.format = "uri"
            return schema
            
        case is UUID:
            var schema = JSONSchema(type: .string)
            schema.format = "uuid"
            return schema
            
        case is Date:
            var schema = JSONSchema(type: .string)
            schema.format = "date-time"
            return schema
            
        case is Data:
            var schema = JSONSchema(type: .string)
            schema.contentEncoding = "base64"
            return schema
            
        case let optValue as Optional<Any>:
            guard let realValue = optValue else {
                return JSONSchema(type: .null)
            }
            return try generateSchemaForBaseTypes(realValue)
            
        // Handle arrays (even empty ones)
        case let array as [Any]:
            var schema = JSONSchema(type: .array)
            if !array.isEmpty, let firstItem = array.first {
                let itemSchema = try _generateSchema(for: firstItem)
                schema.items = PassthroughContainer(itemSchema)
            }
            return schema
            
        // Handle dictionaries (even empty ones)
        case let dict as [String: Any]:
            var schema = JSONSchema(type: .object)
            schema.additionalProperties = true
            
            if !dict.isEmpty {
                var properties = [String: JSONSchema]()
                for (key, value) in dict {
                    properties[key] = try _generateSchema(for: value)
                }
                schema.properties = properties
            }
            return schema
            
        default:
            // If it's not a Foundation or Primitive Swift type return nil
            return nil
        }
    }
}
