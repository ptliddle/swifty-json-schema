//
//  JSONSchemaEmptyTypeTests.swift
//  SwiftyJsonSchema
//
//  Created on 6/27/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema

final class JSONSchemaEmptyTypeTests: XCTestCase {
    
    // MARK: - Empty Struct Tests
    
    // Empty struct with no properties
    struct EmptyStruct: Codable {}
    
    // Empty struct with Codable conformance through extension
    struct EmptyStructWithExtension: Codable {}
    
    // Empty struct that produces its own schema
    struct EmptyStructWithProducer: ProducesJSONSchema {
        static var exampleValue = EmptyStructWithProducer()
    }
    
    func testEmptyStructSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyStruct = EmptyStruct()
        
        let schema = try generator.generateSchema(for: emptyStruct)
        
        // An empty struct should still generate a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Properties should be empty or nil
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
        
        // Required array should be empty or nil
        XCTAssertTrue(schema.required?.isEmpty ?? true)
    }
    
    func testEmptyStructWithExtensionSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyStruct = EmptyStructWithExtension()
        
        let schema = try generator.generateSchema(for: emptyStruct)
        
        // An empty struct should still generate a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Properties should be empty or nil
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
        
        // Required array should be empty or nil
        XCTAssertTrue(schema.required?.isEmpty ?? true)
    }
    
    func testEmptyStructWithProducerSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        
        let schema = try generator.generateSchema(from: EmptyStructWithProducer.self)
        
        // An empty struct should still generate a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Properties should be empty or nil
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
        
        // Required array should be empty or nil
        XCTAssertTrue(schema.required?.isEmpty ?? true)
    }
    
    // MARK: - Empty Class Tests
    
    // Empty class with no properties
    class EmptyClass: Codable {}
    
    // Empty class with Codable conformance through extension
    class EmptyClassWithExtension: Codable {}
    
    func testEmptyClassSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyClass = EmptyClass()
        
        let schema = try generator.generateSchema(for: emptyClass)
        
        // An empty class should still generate a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Properties should be empty or nil
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
        
        // Required array should be empty or nil
        XCTAssertTrue(schema.required?.isEmpty ?? true)
    }
    
    func testEmptyClassWithExtensionSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyClass = EmptyClassWithExtension()
        
        let schema = try generator.generateSchema(for: emptyClass)
        
        // An empty class should still generate a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Properties should be empty or nil
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
        
        // Required array should be empty or nil
        XCTAssertTrue(schema.required?.isEmpty ?? true)
    }
    
    // MARK: - Edge Cases
    
    // Struct with only static properties (should appear empty to reflection)
    struct StaticOnlyStruct: Codable {
        static let version = "1.0"
        static var environment = "production"
    }
    
    // Struct with computed properties only (no stored properties)
    struct ComputedOnlyStruct: Codable {
        var name: String { "ComputedStruct" }
        var timestamp: Date { Date() }
        
        // Required for Codable when there are no stored properties
        init() {}
        
        // Custom Codable implementation since there are no stored properties
        init(from decoder: Decoder) throws {}
        func encode(to encoder: Encoder) throws {}
    }
    
    func testStaticOnlyStructSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let staticStruct = StaticOnlyStruct()
        
        let schema = try generator.generateSchema(for: staticStruct)
        
        // A struct with only static properties should still generate a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Properties should be empty or nil (static properties aren't included)
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
        
        // Required array should be empty or nil
        XCTAssertTrue(schema.required?.isEmpty ?? true)
    }
    
    func testComputedOnlyStructSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let computedStruct = ComputedOnlyStruct()
        
        let schema = try generator.generateSchema(for: computedStruct)
        
        // A struct with only computed properties should still generate a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Properties should be empty or nil (computed properties aren't included by default)
        // Note: This behavior might vary depending on your implementation
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
        
        // Required array should be empty or nil
        XCTAssertTrue(schema.required?.isEmpty ?? true)
    }
    
    // MARK: - Nested Empty Types
    
    // Struct containing an empty struct
    struct ContainerWithEmptyStruct: Codable {
        var name: String
        var empty: EmptyStruct
    }
    
    func testNestedEmptyStructSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let container = ContainerWithEmptyStruct(name: "Container", empty: EmptyStruct())
        
        let schema = try generator.generateSchema(for: container)
        
        // The container should be a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // The container should have two properties
        XCTAssertEqual(schema.properties?.count, 2)
        
        // The 'empty' property should be an object
        XCTAssertEqual(schema.properties?["empty"]?.type, .object)
        
        // The 'empty' property should have empty or nil properties
        XCTAssertTrue(schema.properties?["empty"]?.properties?.isEmpty ?? true)
    }
}
