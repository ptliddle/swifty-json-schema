//
//  JSONSchemaMetadataTests.swift
//  
//
//  Created on 6/28/25.
//

import XCTest
@testable import SwiftyJsonSchema

final class JSONSchemaMetadataTests: XCTestCase {
    
    // Test struct with JSONSchemaMetadata property wrappers
    struct ReplicantInfo: Codable, ProducesJSONSchema {
        
        static var exampleValue = ReplicantInfo(
            id: "bob-1",
            name: "Bob Johansson",
            age: 42,
            starSystem: "Epsilon Eridani",
            specialization: "Engineering",
            visitedPlanets: ["Earth", "Eden", "Vulcan"]
        )
        
        static let none = ReplicantInfo()
        
        @JSONSchemaMetadata(description: "Unique identifier for the replicant")
        var id: String = ""
        
        @JSONSchemaMetadata(description: "Full name of the replicant")
        var name: String = ""
        
        @JSONSchemaMetadata(description: "Age in Earth years since replication")
        var age: Int = 0
        
        @JSONSchemaMetadata(description: "Current star system where the replicant is located")
        var starSystem: String = ""
        
        @OptionalJSONSchemaMetadata(description: "Specialized function of this replicant, if any")
        var specialization: String? = nil
        
        @JSONSchemaMetadata(description: "List of planets this replicant has visited")
        var visitedPlanets: [String] = []
    }
    
    // Test struct with nested metadata
    struct HeavenVesselInfo: Codable {
        @JSONSchemaMetadata(description: "Unique identifier for the vessel")
        var id: String = ""
        
        @JSONSchemaMetadata(description: "Name of the vessel")
        var name: String = ""
        
        @JSONSchemaMetadata(description: "Current replicant controlling this vessel")
        var controller: ReplicantInfo = .none
        
        @OptionalJSONSchemaMetadata(description: "Previous replicant controller, if any")
        var previousController: ReplicantInfo? = nil
        
        @JSONSchemaMetadata(description: "Manufacturing date of this vessel")
        var manufactureDate: Date = .now
        
        @JSONSchemaMetadata(description: "List of installed modules")
        var modules: [String] = []
    }
    
    // Test struct with JSONSchemaExclude
    struct ProjectInfo: Codable {
        @JSONSchemaMetadata(description: "Project codename")
        var name: String = ""
        
        @JSONSchemaMetadata(description: "Project description")
        var description: String = ""
        
        @JSONSchemaExclude
        var internalNotes: String = ""
        
        @JSONSchemaMetadata(description: "Lead replicant for this project")
        var leadReplicant: ReplicantInfo = .none
    }
    
    func testBasicMetadataSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Generate schema
        let schema = try generator.generateSchema(from: ReplicantInfo.self)
        
        // Verify the overall structure
        XCTAssertEqual(schema.type, .object)
        XCTAssertNotNil(schema.properties?["id"])
        XCTAssertNotNil(schema.properties?["name"])
        XCTAssertNotNil(schema.properties?["age"])
        XCTAssertNotNil(schema.properties?["starSystem"])
        XCTAssertNotNil(schema.properties?["specialization"])
        XCTAssertNotNil(schema.properties?["visitedPlanets"])
        
        // Verify descriptions are included
        XCTAssertEqual(schema.properties?["id"]?.description, "Unique identifier for the replicant")
        XCTAssertEqual(schema.properties?["name"]?.description, "Full name of the replicant")
        XCTAssertEqual(schema.properties?["age"]?.description, "Age in Earth years since replication")
        XCTAssertEqual(schema.properties?["starSystem"]?.description, "Current star system where the replicant is located")
        XCTAssertEqual(schema.properties?["specialization"]?.description, "Specialized function of this replicant, if any")
        XCTAssertEqual(schema.properties?["visitedPlanets"]?.description, "List of planets this replicant has visited")
        
        // Verify types are correct
        XCTAssertEqual(schema.properties?["id"]?.type, .string)
        XCTAssertEqual(schema.properties?["name"]?.type, .string)
        XCTAssertEqual(schema.properties?["age"]?.type, .integer)
        XCTAssertEqual(schema.properties?["starSystem"]?.type, .string)
        XCTAssertEqual(schema.properties?["specialization"]?.type, .string)
        XCTAssertEqual(schema.properties?["visitedPlanets"]?.type, .array)
        
        // Verify required fields (specialization should not be required as it's optional)
        XCTAssertTrue(schema.required?.contains("id") ?? false)
        XCTAssertTrue(schema.required?.contains("name") ?? false)
        XCTAssertTrue(schema.required?.contains("age") ?? false)
        XCTAssertTrue(schema.required?.contains("starSystem") ?? false)
        XCTAssertTrue(schema.required?.contains("visitedPlanets") ?? false)
        XCTAssertFalse(schema.required?.contains("specialization") ?? true)
    }
    
    func testNestedMetadataSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test replicant
        let bob = ReplicantInfo(
            id: "bob-1",
            name: "Bob Johansson",
            age: 42,
            starSystem: "Epsilon Eridani",
            specialization: "Engineering",
            visitedPlanets: ["Earth", "Eden", "Vulcan"]
        )
        
        // Create a test vessel
        let vessel = HeavenVesselInfo(
            id: "heaven-1",
            name: "Heaven-1",
            controller: bob,
            previousController: nil,
            manufactureDate: Date(),
            modules: ["Mining", "Fabrication", "Defense"]
        )
        
        // Generate schema
        let schema = try generator.generateSchema(for: vessel)
        
        // Verify the overall structure
        XCTAssertEqual(schema.type, .object)
        XCTAssertNotNil(schema.properties?["id"])
        XCTAssertNotNil(schema.properties?["name"])
        XCTAssertNotNil(schema.properties?["controller"])
        XCTAssertNotNil(schema.properties?["previousController"])
        XCTAssertNotNil(schema.properties?["manufactureDate"])
        XCTAssertNotNil(schema.properties?["modules"])
        
        // Verify descriptions are included
        XCTAssertEqual(schema.properties?["id"]?.description, "Unique identifier for the vessel")
        XCTAssertEqual(schema.properties?["name"]?.description, "Name of the vessel")
        XCTAssertEqual(schema.properties?["controller"]?.description, "Current replicant controlling this vessel")
        XCTAssertEqual(schema.properties?["previousController"]?.description, "Previous replicant controller, if any")
        XCTAssertEqual(schema.properties?["manufactureDate"]?.description, "Manufacturing date of this vessel")
        XCTAssertEqual(schema.properties?["modules"]?.description, "List of installed modules")
        
        // Verify controller schema
        let controllerSchema = schema.properties?["controller"]
        XCTAssertEqual(controllerSchema?.type, .object)
        XCTAssertNotNil(controllerSchema?.properties?["id"])
        XCTAssertEqual(controllerSchema?.properties?["id"]?.description, "Unique identifier for the replicant")
        
        // Verify required fields
        XCTAssertTrue(schema.required?.contains("id") ?? false)
        XCTAssertTrue(schema.required?.contains("name") ?? false)
        XCTAssertTrue(schema.required?.contains("controller") ?? false)
        XCTAssertTrue(schema.required?.contains("manufactureDate") ?? false)
        XCTAssertTrue(schema.required?.contains("modules") ?? false)
        XCTAssertFalse(schema.required?.contains("previousController") ?? true)
    }
    
    func testExcludeFieldSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test replicant
        let bob = ReplicantInfo(
            id: "bob-1",
            name: "Bob Johansson",
            age: 42,
            starSystem: "Epsilon Eridani",
            specialization: "Engineering",
            visitedPlanets: ["Earth", "Eden", "Vulcan"]
        )
        
        // Create a test project
        let project = ProjectInfo(
            name: "Project Heaven",
            description: "Create self-replicating probes",
            internalNotes: "This should not appear in the schema",
            leadReplicant: bob
        )
        
        // Generate schema
        let schema = try generator.generateSchema(for: project)
        
        // Verify the overall structure
        XCTAssertEqual(schema.type, .object)
        XCTAssertNotNil(schema.properties?["name"])
        XCTAssertNotNil(schema.properties?["description"])
        XCTAssertNotNil(schema.properties?["leadReplicant"])
        
        // Verify descriptions are included
        XCTAssertEqual(schema.properties?["name"]?.description, "Project codename")
        XCTAssertEqual(schema.properties?["description"]?.description, "Project description")
        XCTAssertEqual(schema.properties?["leadReplicant"]?.description, "Lead replicant for this project")
        
        // Verify excluded field is not present
        XCTAssertNil(schema.properties?["internalNotes"])
        
        // Verify required fields
        XCTAssertTrue(schema.required?.contains("name") ?? false)
        XCTAssertTrue(schema.required?.contains("description") ?? false)
        XCTAssertTrue(schema.required?.contains("leadReplicant") ?? false)
        XCTAssertFalse(schema.required?.contains("internalNotes") ?? true)
    }
}

// Helper extension for Date to make it Codable
extension Date {
    var timeIntervalSinceReferenceDate: TimeInterval {
        return self.timeIntervalSinceReferenceDate
    }
}
