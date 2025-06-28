//
//  JSONSchemaEmptyTypeEdgeCasesTests.swift
//  SwiftyJsonSchema
//
//  Created on 6/27/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema

final class JSONSchemaEmptyTypeEdgeCasesTests: XCTestCase {
    
    // Empty struct with no properties
    struct EmptyStruct: Codable {}
    
    
    // MARK: - Protocol Conformance Tests
    
    // Empty protocol
    protocol EmptyProtocol {}
    
    // Empty struct conforming to a protocol
    struct EmptyStructWithProtocol: Codable, EmptyProtocol {}
    
    // Empty class conforming to multiple protocols
    class EmptyClassWithProtocols: Codable, EmptyProtocol {}
    
    func testEmptyStructWithProtocolSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyStruct = EmptyStructWithProtocol()
        
        let schema = try generator.generateSchema(for: emptyStruct)
        
        // Should still be a valid object schema despite protocol conformance
        XCTAssertEqual(schema.type, .object)
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
    }
    
    func testEmptyClassWithProtocolsSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyClass = EmptyClassWithProtocols()
        
        let schema = try generator.generateSchema(for: emptyClass)
        
        // Should still be a valid object schema despite protocol conformances
        XCTAssertEqual(schema.type, .object)
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
    }
    
    // MARK: - Inheritance Tests
    
    // Empty base class
    class EmptyBaseClass: Codable {}
    
    // Empty derived class
    class EmptyDerivedClass: EmptyBaseClass {}
    
    // Derived class with properties inheriting from empty base class
    class DerivedClassWithProperties: EmptyBaseClass {
        var name: String = "Derived"
        var value: Int = 42
    }
    
    func testEmptyDerivedClassSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let derivedClass = EmptyDerivedClass()
        
        let schema = try generator.generateSchema(for: derivedClass)
        
        // Should still be a valid object schema despite inheritance
        XCTAssertEqual(schema.type, .object)
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
    }
    
    func testDerivedClassWithPropertiesSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let derivedClass = DerivedClassWithProperties()
        
        let schema = try generator.generateSchema(for: derivedClass)
        
        // Should be a valid object schema with properties from derived class
        XCTAssertEqual(schema.type, .object)
        XCTAssertEqual(schema.properties?.count, 2)
        XCTAssertNotNil(schema.properties?["name"])
        XCTAssertNotNil(schema.properties?["value"])
    }
    
    // MARK: - Generic Type Tests
    
    // Empty generic struct
    struct EmptyGenericStruct<T: Codable>: Codable {}
    
    // Empty generic class
    class EmptyGenericClass<T: Codable>: Codable {}
    
    func testEmptyGenericStructSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyGenericStruct = EmptyGenericStruct<String>()
        
        let schema = try generator.generateSchema(for: emptyGenericStruct)
        
        // Should still be a valid object schema despite being generic
        XCTAssertEqual(schema.type, .object)
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
    }
    
    func testEmptyGenericClassSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyGenericClass = EmptyGenericClass<Int>()
        
        let schema = try generator.generateSchema(for: emptyGenericClass)
        
        // Should still be a valid object schema despite being generic
        XCTAssertEqual(schema.type, .object)
        XCTAssertTrue(schema.properties?.isEmpty ?? true)
    }
    
    // MARK: - Collection of Empty Types
    
    func testArrayOfEmptyStructsSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyStructs = [EmptyStruct(), EmptyStruct()]
        
        let schema = try generator.generateSchema(for: emptyStructs)
        
        // Should be a valid array schema
        XCTAssertEqual(schema.type, .array)
        
        // Items should be objects
        XCTAssertEqual(schema.items?.content?.type, .object)
        
        // Items should have empty or nil properties
        XCTAssertTrue(schema.items?.content?.properties?.isEmpty ?? true)
    }
    
//    func testDictionaryWithEmptyStructValuesSchemaGeneration() throws {
//        let generator = JSONSchemaGenerator()
//        let emptyStructDict = ["first": EmptyStruct(), "second": EmptyStruct()]
//        
//        let schema = try generator.generateSchema(for: emptyStructDict)
//        
//        // Should be a valid object schema
//        XCTAssertEqual(schema.type, .object)
//        
//        // Additional properties should be objects
//        XCTAssertEqual(schema.additionalProperties?.schema?.type, .object)
//        
//        // Additional properties should have empty or nil properties
//        XCTAssertTrue(schema.additionalProperties?.schema?.properties?.isEmpty ?? true)
//    }
}
