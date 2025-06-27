//
//  JSONSchemaBasicTypeTests.swift.swift
//  SwiftyJsonSchema
//
//  Created by Peter Liddle on 6/27/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema


final class JSONSchemaBasicTypeTests: XCTestCase {
    
    // MARK: - String Tests
    
    func testStringSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = "Hello, World!"
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertNil(schema.format)
        XCTAssertNil(schema.minLength)
        XCTAssertNil(schema.maxLength)
        XCTAssertNil(schema.pattern)
    }
    
    // MARK: - Integer Tests
    
    func testIntSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = 42
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .integer)
        XCTAssertNil(schema.minimum)
        XCTAssertNil(schema.maximum)
    }
    
    func testInt8SchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: Int8 = 42
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .integer)
    }
    
    func testInt16SchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: Int16 = 42
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .integer)
    }
    
    func testInt32SchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: Int32 = 42
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .integer)
    }
    
    func testInt64SchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: Int64 = 42
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .integer)
    }
    
    func testUIntSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: UInt = 42
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .integer)
    }
    
    // MARK: - Number Tests
    
    func testDoubleSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: Double = 3.14159
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .number)
        XCTAssertNil(schema.minimum)
        XCTAssertNil(schema.maximum)
    }
    
    func testFloatSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: Float = 3.14
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .number)
    }
    
    func testDecimalSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: Decimal = 3.14159
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .number)
    }
    
    // MARK: - Boolean Tests
    
    func testBoolSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = true
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .boolean)
    }
    
    // MARK: - Foundation Type Tests
    
    func testURLSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = URL(string: "https://example.com")!
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.format, "uri")
    }
    
    func testDateSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = Date()
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.format, "date-time")
    }
    
    // MARK: - Array Tests
    
    func testEmptyArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: [String] = []
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .array)
        XCTAssertNil(schema.items?.items)
    }
    
    func testStringArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = ["one", "two", "three"]
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .array)
        XCTAssertEqual(schema.items?.items?.type, .string)
    }
    
    func testIntArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = [1, 2, 3]
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .array)
        XCTAssertEqual(schema.items?.items?.type, .integer)
    }
    
    // MARK: - Dictionary Tests
    
    func testEmptyDictionarySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value: [String: String] = [:]
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .object)
        XCTAssertTrue(schema.additionalProperties ?? false)
        XCTAssertNil(schema.properties) // Empty dictionary has no properties
    }
    
    func testStringDictionarySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = ["key1": "value1", "key2": "value2"]
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .object)
        XCTAssertTrue(schema.additionalProperties ?? false)
        XCTAssertNotNil(schema.properties)
        XCTAssertEqual(schema.properties?["key1"]?.type, .string)
        XCTAssertEqual(schema.properties?["key2"]?.type, .string)
    }
    
    // MARK: - Optional Tests
    
    func testBasicOptionalSchemaGenerationForSome() throws {
        let generator = JSONSchemaGenerator()
        
        let optionalString: String? = "Bobiverse"
        let schema = try generator.generateSchema(for: optionalString)
        
        XCTAssertEqual(schema.type, .string)
    }
    
    func testBasicOptionalSchemaGenerationForNone() throws {
        let generator = JSONSchemaGenerator()
        
        let optionalString: String? = nil
        let schema = try generator.generateSchema(for: optionalString)
        
        XCTAssertEqual(schema.type, .null)
    }
    
    // MARK: - Nested Object Tests
    
    func testNestedObjectSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        
        struct Person: Codable {
            let name: String
            let age: Int
            let address: Address
            
            struct Address: Codable {
                let street: String
                let city: String
                let zipCode: String
            }
        }
        
        let person = Person(
            name: "John Doe",
            age: 30,
            address: Person.Address(
                street: "123 Main St",
                city: "Anytown",
                zipCode: "12345"
            )
        )
        
        let schema = try generator.generateSchema(for: person)
        
        XCTAssertEqual(schema.type, .object)
        XCTAssertNotNil(schema.properties)
        XCTAssertEqual(schema.properties?["name"]?.type, .string)
        XCTAssertEqual(schema.properties?["age"]?.type, .integer)
        XCTAssertEqual(schema.properties?["address"]?.type, .object)
        XCTAssertEqual(schema.properties?["address"]?.properties?["street"]?.type, .string)
        XCTAssertEqual(schema.properties?["address"]?.properties?["city"]?.type, .string)
        XCTAssertEqual(schema.properties?["address"]?.properties?["zipCode"]?.type, .string)
        
        // Check required fields
        XCTAssertTrue(schema.required?.contains("name") ?? false)
        XCTAssertTrue(schema.required?.contains("age") ?? false)
        XCTAssertTrue(schema.required?.contains("address") ?? false)
        
        // Check nested required fields
        XCTAssertTrue(schema.properties?["address"]?.required?.contains("street") ?? false)
        XCTAssertTrue(schema.properties?["address"]?.required?.contains("city") ?? false)
        XCTAssertTrue(schema.properties?["address"]?.required?.contains("zipCode") ?? false)
    }
}
