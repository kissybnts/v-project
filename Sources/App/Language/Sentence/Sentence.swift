import Vapor
import FluentProvider
import HTTP

final class Sentence: Model, UserRelationModel {
    let storage = Storage()
    
    let userId: Identifier
    let categoryId: Identifier
    var original: String
    var translation: String
    
    public struct Properties {
        public static let id = PropertyKey.id
        public static let userId = User.foreignIdKey
        public static let categoryId = Category.foreinIdKey
        public static let original = "original"
        public static let translation = "translation"
    }

    init(userId: Identifier, categoryId: Identifier, original: String, translation: String) {
        self.userId = userId
        self.categoryId = categoryId
        self.original = original
        self.translation = translation
    }
    
    init(row: Row) throws {
        userId = try row.get(Properties.userId)
        categoryId = try row.get(Properties.categoryId)
        original = try row.get(Properties.original)
        translation = try row.get(Properties.translation)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.userId, userId)
        try row.set(Properties.categoryId, categoryId)
        try row.set(Properties.original, original)
        try row.set(Properties.translation, translation)
        return  row
    }
}

extension Sentence: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.parent(User.self)
            builder.parent(Category.self)
            builder.text(Properties.original)
            builder.text(Properties.translation)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Sentence: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            userId: json.get(Properties.userId),
            categoryId: json.get(Properties.categoryId),
            original: json.get(Properties.original),
            translation: json.get(Properties.translation)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Properties.id, id)
        try json.set(Properties.categoryId, categoryId)
        try json.set(Properties.original, original)
        try json.set(Properties.translation, translation)
        return json
    }
    
    internal struct JSONKeys {
        internal static let multi = "sentences"
    }
}

extension Sentence: ResponseRepresentable {}

extension Sentence: Timestampable {}

extension Sentence: Updateable {
    public static var updateableKeys: [UpdateableKey<Sentence>] {
        return [
            UpdateableKey(Properties.original, String.self) { sentence, original in
                sentence.original = original
            },
            UpdateableKey(Properties.translation, String.self) { sentence, translation in
                sentence.translation = translation
            }
        ]
    }
}
