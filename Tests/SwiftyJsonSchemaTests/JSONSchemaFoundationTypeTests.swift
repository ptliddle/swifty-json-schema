//
//  JSONSchemaFoundationTypeTests.swift
//  SwiftyJsonSchema
//
//  Created on 6/27/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema

final class JSONSchemaFoundationTypeTests: XCTestCase {
    
    // MARK: - URL Tests
    
    func testURLSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = URL(string: "https://example.com")!
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.format, "uri")
    }
    
    // MARK: - UUID Tests
    
    func testUUIDSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = UUID()
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.format, "uuid")
    }
    
    // MARK: - Date Tests
    
    func testDateSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = Date()
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.format, "date-time")
    }
    
    // MARK: - Data Tests
    
    func testDataSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = "Hello, World!".data(using: .utf8)!
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, .string)
        XCTAssertEqual(schema.contentEncoding, "base64")
    }
    
    // MARK: - Optional Foundation Type Tests
    
    func testOptionalURLSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        
        // Test Some case
        let someURL: URL? = URL(string: "https://example.com")
        let someSchema = try generator.generateSchema(for: someURL)
        
        XCTAssertEqual(someSchema.type, .string)
        XCTAssertEqual(someSchema.format, "uri")
        
        // Test None case
        let noneURL: URL? = nil
        let noneSchema = try generator.generateSchema(for: noneURL)
        
        XCTAssertEqual(noneSchema.type, .null)
    }
    
    func testOptionalUUIDSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        
        // Test Some case
        let someUUID: UUID? = UUID()
        let someSchema = try generator.generateSchema(for: someUUID)
        
        XCTAssertEqual(someSchema.type, .string)
        XCTAssertEqual(someSchema.format, "uuid")
        
        // Test None case
        let noneUUID: UUID? = nil
        let noneSchema = try generator.generateSchema(for: noneUUID)
        
        XCTAssertEqual(noneSchema.type, .null)
    }
    
    func testOptionalDateSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        
        // Test Some case
        let someDate: Date? = Date()
        let someSchema = try generator.generateSchema(for: someDate)
        
        XCTAssertEqual(someSchema.type, .string)
        XCTAssertEqual(someSchema.format, "date-time")
        
        // Test None case
        let noneDate: Date? = nil
        let noneSchema = try generator.generateSchema(for: noneDate)
        
        XCTAssertEqual(noneSchema.type, .null)
    }
    
    func testOptionalDataSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        
        // Test Some case
        let someData: Data? = "Hello, World!".data(using: .utf8)
        let someSchema = try generator.generateSchema(for: someData)
        
        XCTAssertEqual(someSchema.type, .string)
        XCTAssertEqual(someSchema.contentEncoding, "base64")
        
        // Test None case
        let noneData: Data? = nil
        let noneSchema = try generator.generateSchema(for: noneData)
        
        XCTAssertEqual(noneSchema.type, .null)
    }
}
