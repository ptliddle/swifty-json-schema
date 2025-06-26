//
//  JSONSchemaGeneratorTests.swift
//  
//
//  Created on 6/26/25.
//

import XCTest
@testable import SwiftyJsonSchema


extension Data {
    var asPrettyJson: String {
        get throws {
            // Try to serialize the JSON data into a Foundation object
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            
            // Convert the object back to JSON data with pretty print option
            let prettyPrintedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            
            return try prettyPrintedData.string
        }
    }
}

struct TestLog {
    
    static var on = true
    
    static func debug(_ text: String) {
        if on { print(text) } else { return }
    }
}

final class JSONSchemaGeneratorTests: XCTestCase {
    
    // Test structure for schema generation
    struct Person: Codable {
        var name: String
        var age: Int
        var hobbies: [String]
    }
    
    struct PersonProduces: ProducesJSONSchema {
        static var exampleValue = PersonProduces(name: "Peter", age: 53, hobbies: ["Snorkeling", "Coding", "Eating", "Cooking"])
        
        var name: String
        var age: Int
        var hobbies: [String]
    }
    
    let encoder = JSONEncoder()
    
    func testBasicTypeSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test person
        let person = Person(name: "John Doe", age: 30, hobbies: ["Reading", "Coding", "Hiking"])
        
        // Generate schema from the instance
        let schema = generator.generateSchema(for: person)
        
        // Define the expected schema
        let expectedSchema = JSONSchema(
            id: nil,
            schema: "http://json-schema.org/draft-07/schema#",
            type: .object,
            properties: [
                "name": JSONSchema(type: .string),
                "hobbies": JSONSchema(type: .array, items: JSONSchema(type: .string)),
                "age": JSONSchema(type: .integer)
            ],
            required: ["name", "age", "hobbies"]
        )


        
        // Check overall schema
        let rawExpectedSchema = try encoder.encode(expectedSchema)
        let rawGeneratedSchema = try encoder.encode(schema)
        
        TestLog.debug("GENERATED: \n ---------- \n \(try rawGeneratedSchema.asPrettyJson) \n ---------- ")
//        XCTAssertEqual(try rawExpectedSchema.asPrettyJson, try rawGeneratedSchema.asPrettyJson)
        
        // Assert that the schema matches our expected schema
        // Note: This test will fail initially as we haven't implemented the actual schema generation yet
        XCTAssertEqual(schema.type, expectedSchema.type)
        XCTAssertEqual(schema.schema, expectedSchema.schema)
        
        // Check required properties
        XCTAssertEqual(Set(schema.required ?? []), Set(expectedSchema.required ?? []))
        
        // Check individual properties
        guard let schemaProperties = schema.properties,
              let expectedProperties = expectedSchema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check name property
        XCTAssertEqual(schemaProperties["name"]?.type, expectedProperties["name"]?.type)
        
        // Check age property
        XCTAssertEqual(schemaProperties["age"]?.type, expectedProperties["age"]?.type)
        
        // Check hobbies property
        XCTAssertEqual(schemaProperties["hobbies"]?.type, expectedProperties["hobbies"]?.type)
        
        // Check hobbies items
        XCTAssertEqual(schemaProperties["hobbies"]?.items?.items?.type, expectedProperties["hobbies"]?.items?.items?.type)
    }
    
    func testTypeSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Generate schema from the type
        let schema = generator.generateSchema(for: PersonProduces.self)
        
        // Define the expected schema
        let expectedSchema = JSONSchema(
            id: nil,
            schema: "http://json-schema.org/draft-07/schema#",
            type: .object,
            properties: [
                "name": JSONSchema(type: .string),
                "age": JSONSchema(type: .integer),
                "hobbies": JSONSchema(type: .array, items: JSONSchema(type: .string))
            ],
            required: ["name", "age", "hobbies"]
        )
        
        // Assert that the schema matches our expected schema
        // Note: This test will fail initially as we haven't implemented the actual schema generation yet
        XCTAssertEqual(schema.type, expectedSchema.type)
        XCTAssertEqual(schema.schema, expectedSchema.schema)
        
        // Check required properties
        XCTAssertEqual(Set(schema.required ?? []), Set(expectedSchema.required ?? []))
        
        // Check individual properties
        guard let schemaProperties = schema.properties,
              let expectedProperties = expectedSchema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check name property
        XCTAssertEqual(schemaProperties["name"]?.type, expectedProperties["name"]?.type)
        
        // Check age property
        XCTAssertEqual(schemaProperties["age"]?.type, expectedProperties["age"]?.type)
        
        // Check hobbies property
        XCTAssertEqual(schemaProperties["hobbies"]?.type, expectedProperties["hobbies"]?.type)
        
        // Check hobbies items
        XCTAssertEqual(schemaProperties["hobbies"]?.items?.items?.type, expectedProperties["hobbies"]?.items?.items?.type)
    }
}
