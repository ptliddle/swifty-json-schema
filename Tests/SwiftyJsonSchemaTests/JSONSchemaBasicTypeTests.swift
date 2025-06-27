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
        
        TestLog.debug("SCHEMA \(schema.debugDescription)")
        
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
        
        TestLog.debug("SCHEMA \(schema.debugDescription)")
        
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
        
        TestLog.debug("SCHEMA \(schema.debugDescription)")
        
        XCTAssertEqual(schema.type, .number)
    }
    
    // MARK: - Boolean Tests
    
    func testBoolSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = true
        let schema = try generator.generateSchema(for: value)
        
        TestLog.debug("SCHEMA \(schema.debugDescription)")
        
        XCTAssertEqual(schema.type, .boolean)
    }
    
    // MARK: - Foundation Type Tests
    
    func testURLSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = URL(string: "https://example.com")!
        let schema = try generator.generateSchema(for: value)
        
        TestLog.debug("SCHEMA \(schema.debugDescription)")
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.format, "uri")
    }
    
    func testDateSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = Date()
        let schema = try generator.generateSchema(for: value)
        
        TestLog.debug("SCHEMA \(schema.debugDescription)")
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.format, "date-time")
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
}
