import Vapor
import FluentProvider
import HTTP

final class Category: Model, UserRelationModel {
    let storage = Storage()
    static let entity = "categories"
    
    var name: String
    let userId: Identifier
    
    internal struct Properties {
        public static let id = PropertyKey.id
        public static let name = PropertyKey.name
        public static let userId = User.foreignIdKey
    }
    
    internal static let foreinIdKey = "category_id"
    
    init(name: String, userId: Identifier) {
        self.name = name
        self.userId = userId
    }
    
    init(row: Row) throws {
        name = try row.get(Properties.name)
        userId = try row.get(Properties.userId)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.name, name)
        try row.set(Properties.userId, userId)
        return row
    }
}

extension Category: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Properties.name)
            builder.parent(User.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Category: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(name: json.get(Properties.name), userId: json.get(Properties.userId))
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Properties.id, id)
        try json.set(Properties.name, name)
        return json
    }
    
    func makeJsonWithSentenes() throws -> JSON {
        var json = try makeJSON()
        let sentences = try self.sentences.all().makeJSON()
        try json.set(Sentence.JSONKeys.multi, sentences)
        return json
    }
}

extension Category: ResponseRepresentable {}

extension Category: Timestampable {}

extension Category: Updateable {
    public static var updateableKeys: [UpdateableKey<Category>] {
        return [
            UpdateableKey(Properties.name, String.self) { category, name in
                category.name = name
            }
        ]
    }
}

extension Category {
    var sentences: Children<Category, Sentence> {
        return children()
    }
}
