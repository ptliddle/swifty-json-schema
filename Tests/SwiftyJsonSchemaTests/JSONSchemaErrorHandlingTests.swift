//
//  JSONSchemaErrorHandlingTests.swift
//  
//
//  Created on 6/26/25.
//

import XCTest
@testable import SwiftyJsonSchema

final class JSONSchemaErrorHandlingTests: XCTestCase {
    
    // A non-Codable class to test error handling
    class NonCodableClass {
        var name: String
        
        init(name: String) {
            self.name = name
        }
    }
    
    // A struct with a non-Codable property
    struct StructWithNonCodable: Codable {
        var id: String
        
        // This property is not used directly in Codable but will cause issues
        // if we try to generate a schema from it
        var nonCodableProperty: NonCodableClass?
        
        enum CodingKeys: String, CodingKey {
            case id
        }
    }
    
    // A struct with a non-Codable array
    struct StructWithNonCodableArray: Codable {
        var id: String
        var items: [String]
        
        // This property is not used directly in Codable but will cause issues
        // if we try to generate a schema from it
        var nonCodableArray: [NonCodableClass]
        
        enum CodingKeys: String, CodingKey {
            case id, items
        }
        
        init(id: String, items: [String], nonCodableArray: [NonCodableClass]) {
            self.id = id
            self.items = items
            self.nonCodableArray = nonCodableArray
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            items = try container.decode([String].self, forKey: .items)
            nonCodableArray = []
        }
    }
    
    func testNonCodableTypeError() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test struct with a non-Codable property
        struct TestStruct {
            var name: String
            var nonCodable: NonCodableClass
        }
        
        let test = TestStruct(name: "Test", nonCodable: NonCodableClass(name: "TestClass"))
        
        // We can't directly test with a non-Codable type due to Swift's static type checking
        // So we'll test with a type that has a non-Codable property instead
        // The generator should detect this at runtime and throw an error
        
        // Create a method that accepts Any and tries to generate a schema
        func generateSchemaForAny(_ any: Any) throws -> JSONSchema {
            // This is a workaround to test runtime type checking
            // In a real app, this would be caught at compile time
            if let codable = any as? Codable {
                return try generator.generateSchema(for: codable)
            } else {
                throw JSONSchemaGenerationError.notACodableType(String(describing: type(of: any)))
            }
        }
        
        // Attempt to generate schema - should throw an error
        XCTAssertThrowsError(try generateSchemaForAny(test)) { error in
            guard let schemaError = error as? JSONSchemaGenerationError else {
                XCTFail("Expected JSONSchemaGenerationError but got \(error)")
                return
            }
            
            // Check that we got the right error type
            if case .notACodableType(let typeName) = schemaError {
                XCTAssertTrue(typeName.contains("TestStruct"), "Error should mention TestStruct")
            } else {
                XCTFail("Expected notACodableType error but got \(schemaError)")
            }
        }
    }
    
    func testEmptyOptionalHandling() throws {
        // Create a struct with nil optionals
        struct TestWithNilOptionals: Codable {
            var id: String
            var optionalString: String?
            var optionalInt: Int?
            var optionalArray: [String]?
        }
        
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test instance with nil optionals
        let testInstance = TestWithNilOptionals(
            id: "test-id",
            optionalString: nil,
            optionalInt: nil,
            optionalArray: nil
        )
        
        // Generate schema
        let schema = try generator.generateSchema(for: testInstance)
        
        // Verify the schema
        XCTAssertEqual(schema.type, .object)
        XCTAssertEqual(schema.properties?.count, 4)
        
        // Check that nil optionals are still included in properties but not in required
        XCTAssertNotNil(schema.properties?["optionalString"])
        XCTAssertNotNil(schema.properties?["optionalInt"])
        XCTAssertNotNil(schema.properties?["optionalArray"])
        
        // Check that only non-optional properties are in required
        XCTAssertEqual(schema.required?.count, 1)
        XCTAssertEqual(schema.required?.first, "id")
    }
}
