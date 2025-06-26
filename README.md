# SwiftyJsonSchema

SwiftyJsonSchema is a lightweight Swift library for generating JSON Schema from Swift structs and classes. It provides an easy way to create JSON Schema documentation for your data models.

## Features

- Generate JSON Schema from Swift structs and classes
- Support for nested objects and arrays
- Property descriptions via property wrappers
- Automatic type mapping from Swift types to JSON Schema types
- Draft-07 JSON Schema compatibility

## Installation

### Swift Package Manager

Add SwiftyJsonSchema to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/ptliddle/swifty-json-schema.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftyJsonSchema"]
)
```

## Usage

### Basic Usage

1. Import the library:

```swift
import SwiftyJsonSchema
```

1. Make your struct or class conform to `ProducesJSONSchema`:

```swift
struct PersonInfo: ProducesJSONSchema {
    // Required by ProducesJSONSchema protocol
    static var exampleValue = PersonInfo(name: "John Doe", age: 30, hobbies: ["Reading", "Coding"])
    
    var name: String
    var age: Int
    var hobbies: [String]
}
```

1. Generate JSON Schema:

```swift
let schema = JsonSchemaCreator.createJSONSchema(from: PersonInfo.self)
```

1. Convert to JSON:

```swift
let jsonData = try JSONEncoder().encode(schema)
let jsonString = String(data: jsonData, encoding: .utf8)
```

### Adding Property Descriptions

You can add descriptions to properties using the `JSONSchemaMetadata` property wrapper:

```swift
struct UserProfile: ProducesJSONSchema {
    static var exampleValue = UserProfile(
        username: "johndoe",
        email: "john@example.com",
        age: 30
    )
    
    @JSONSchemaMetadata(description: "The user's unique username")
    var username: String
    
    @JSONSchemaMetadata(description: "The user's email address")
    var email: String
    
    @JSONSchemaMetadata(description: "The user's age in years")
    var age: Int
}
```

### Nested Objects

SwiftyJsonSchema supports nested objects as long as they conform to `Codable`:

```swift
struct Address: Codable {
    var street: String
    var city: String
    var zipCode: String
}

struct Customer: ProducesJSONSchema {
    static var exampleValue = Customer(
        id: "C12345",
        name: "Jane Smith",
        address: Address(street: "123 Main St", city: "Anytown", zipCode: "12345")
    )
    
    var id: String
    var name: String
    var address: Address
}
```

### Working with Arrays

Arrays of objects are also supported:

```swift
struct Team: ProducesJSONSchema {
    static var exampleValue = Team(
        name: "Engineering",
        members: [
            PersonInfo(name: "Alice", age: 28, hobbies: ["Coding", "Hiking"]),
            PersonInfo(name: "Bob", age: 35, hobbies: ["Reading", "Gaming"])
        ]
    )
    
    var name: String
    var members: [PersonInfo]
}
```

## Complete Example

Here's a complete example showing how to create and use JSON Schema:

```swift
import SwiftyJsonSchema

// Define your data model
struct Product: ProducesJSONSchema {
    static var exampleValue = Product(
        id: "P12345",
        name: "Awesome Widget",
        price: 29.99,
        tags: ["electronics", "gadget"],
        inStock: true
    )
    
    @JSONSchemaMetadata(description: "Unique product identifier")
    var id: String
    
    @JSONSchemaMetadata(description: "Product name")
    var name: String
    
    @JSONSchemaMetadata(description: "Product price in USD")
    var price: Double
    
    @JSONSchemaMetadata(description: "Product categories")
    var tags: [String]
    
    @JSONSchemaMetadata(description: "Whether the product is in stock")
    var inStock: Bool
}

// Generate JSON Schema
let schema = JsonSchemaCreator.createJSONSchema(from: Product.self)

// Print the schema as JSON
print(schema.debugDescription)
```

This will output a JSON Schema that looks like:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique product identifier"
    },
    "name": {
      "type": "string",
      "description": "Product name"
    },
    "price": {
      "type": "number",
      "description": "Product price in USD"
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Product categories"
    },
    "inStock": {
      "type": "boolean",
      "description": "Whether the product is in stock"
    }
  },
  "required": ["id", "name", "price", "tags", "inStock"]
}
```

## License

SwiftyJsonSchema is available under the MIT license. See the LICENSE file for more info.
