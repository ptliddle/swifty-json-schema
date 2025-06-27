//
//  JSONSchemaBasicTypeTests.swift.swift
//  SwiftyJsonSchema
//
//  Created by Peter Liddle on 6/27/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema


final class JSONSchemaBasicTypeTests_swift: XCTestCase {

    
    func testBasicOptionalSchemaGenerationForSome() throws {
        
        let generator = JSONSchemaGenerator()
        
        let optionalString: String? = "Bobiverse"
        let schema = try generator.generateSchema(for: optionalString)
        
        XCTAssertEqual(schema.type!, .object)
        XCTAssertEqual(schema.properties!["type"]!.type, .string)
        XCTAssertEqual(schema.required!, [])
    }
    
    func testBasicOptionalSchemaGenerationForNone() throws {
        
        let generator = JSONSchemaGenerator()
        
        let optionalString: String? = nil
        try generator.generateSchema(for: optionalString)
    }

}
