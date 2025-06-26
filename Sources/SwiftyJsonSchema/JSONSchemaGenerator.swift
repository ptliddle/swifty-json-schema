//
//  JSONSchemaGenerator.swift
//
//
//  Created on 6/26/25.
//

import Foundation

enum JSONSchemaGenerationError: Error {
    case notACodableType(String)
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
    
    /// Generate a JSON Schema for the given Codable object
    /// - Parameters:
    ///   - object: The object to generate a schema for
    /// - Returns: A JSONSchema object representing the schema
    public func generateSchema<T: Codable>(for object: T) throws -> JSONSchema {
        // Create a base schema with the configuration values
        let schema = JSONSchema(id: configuration.schemaId, schema: configuration.schemaVersion, type: .object)
        return try _generateSchema(for: object, schema: schema)
    }
     
    private func _generateSchema<T: Codable>(for object: T, schema: JSONSchema = JSONSchema(type: .object)) throws -> JSONSchema {
        
        var schema = schema
        
        // Create dictionaries to store properties and required fields
        var properties: [String: JSONSchema] = [:]
        var required: [String] = []
        
        // Use Mirror to reflect on the object's properties
        let mirror = Mirror(reflecting: object)
        
        // Process each child in the mirror
        for child in mirror.children {
            // Skip if the property has no label
            guard let propertyName = child.label else { continue }
            
            // Clean the property name (remove underscore prefix for property wrappers)
            let cleanPropertyName = cleanPropertyName(propertyName)
            
            guard let value = child.value as? Codable else {
                throw JSONSchemaGenerationError.notACodableType("\(child.value.self)")
            }
            
            if isOptional(child.value) {
                let propertySchema = try generateSchemaForProperty(value)
                properties[cleanPropertyName] = propertySchema
            }
            else {
                // Generate schema for this property
                let propertySchema = try generateSchemaForProperty(value)
                properties[cleanPropertyName] = propertySchema
                required.append(cleanPropertyName)
            }
        }
        
        // Add properties and required fields to the schema
        schema.properties = properties
        schema.required = required
        
        return schema
    }
    
    /// Generate a JSON Schema for the given Codable type
    /// - Parameters:
    ///   - type: The type to generate a schema for
    /// - Returns: A JSONSchema object representing the schema
    public func generateSchema<T: ProducesJSONSchema>(for type: T.Type) throws -> JSONSchema {
        // This is just a stub that will be implemented later
        let instance = T.exampleValue
        return try generateSchema(for: instance)
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
    
    /// Generate a JSON Schema for a property value
    /// - Parameter value: The property value to generate a schema for
    /// - Returns: A JSONSchema object representing the property
    private func generateSchemaForProperty<T>(_ value: T) throws -> JSONSchema where T: Codable {
        // Handle optionals by unwrapping and recursing
        if isOptional(value) {
            let mirror = Mirror(reflecting: value)
            if let firstChild = mirror.children.first {
                guard let value = firstChild.value as? Codable else {
                    throw JSONSchemaGenerationError.notACodableType("\(firstChild.self)")
                }
                return try generateSchemaForProperty(value)
            } else {
                // For nil optionals, return a placeholder schema
                return JSONSchema(type: .object)
            }
        }
        
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
            
        // Handle Foundation types
        case _ as URL:
            var schema = JSONSchema(type: .string)
            schema.format = "uri"
            return schema
            
        case _ as Date:
            var schema = JSONSchema(type: .string)
            schema.format = "date-time"
            return schema
            
        // Handle arrays
        case let array as [Any]:
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
                throw JSONSchemaGenerationError.notACodableType("\(firstItem.self)")
            }
            
            // Generate schema for the item
            let itemSchema = try generateSchemaForProperty(arrayItem)
            return JSONSchema(type: .array, items: itemSchema)
            
        // Handle dictionaries
        case let dict as [String: Any]:
            // For dictionaries, we create an object schema with string keys and dynamic values
            var schema = JSONSchema(type: .object)
            
            // Set additionalProperties to true to allow any properties beyond those defined
            schema.additionalProperties = true
            
            // If the dictionary is empty, we can't determine the value type
            if dict.isEmpty {
                return schema
            }
            
            // For non-empty dictionaries, we'll create a properties map with the existing keys
            var properties = [String: JSONSchema]()
            
            // Process each key-value pair
            for (key, value) in dict {
                // Check that the value is Codable
                guard let dictValue = value as? Codable else {
                    throw JSONSchemaGenerationError.notACodableType("\(value.self)")
                }
                
                // Generate schema for the value
                let valueSchema = try generateSchemaForProperty(dictValue)
                properties[key] = valueSchema
            }
            
            schema.properties = properties
            return schema
            
        default:
            // For complex types (like nested Codable objects), use Mirror to generate a schema
            return try generateSchema(for: value)
        }
    }
}
