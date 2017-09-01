import Vapor
import FluentProvider
import HTTP
import MySQLProvider

final class Tag: Model {
    let storage = Storage()
    
    var name: String
    
    public struct Properties {
        public static let id = PropertyKey.id
        public static let name = PropertyKey.name
    }
    
    static let foreinIdKey = "tag_id"
    
    init(id: Identifier?, name: String) {
        self.name = name
        self.id = id
    }
    
    init(row: Row) throws {
        name = try row.get(Properties.name)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.name, name)
        return row
    }
}

extension Tag: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Properties.name, unique: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Tag: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            id: json.get(Properties.id),
            name: json.get(Properties.name)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Properties.id, id)
        try json.set(Properties.name, name)
        return json
    }
    
    func makeJsonWithNotes(userId: Identifier) throws -> JSON {
        var json = try makeJSON()
        let notes = try self.notes.makeQuery().filter(Note.Properties.userId, userId).sort(Note.Properties.id, .ascending).all()
        try json.set(Note.JSONKeys.multi, notes.makeJSON())
        return json
    }
    
    func makeJsonWithNotes() throws -> JSON {
        var json = try makeJSON()
        let notes = try self.notes.sort(Note.Properties.id, .ascending)
        try json.set(Note.JSONKeys.multi, notes)
        return json
    }
    
    internal struct JSONKeys {
        internal static let multi = "tags"
    }
}

extension Tag: Timestampable {}

extension Tag: ResponseRepresentable {}

extension Tag: Updateable {
    public static var updateableKeys: [UpdateableKey<Tag>] {
        return [
            UpdateableKey(Properties.name, String.self) { tag, name in
                tag.name = name
            }
        ]
    }
}

extension Tag {
    var notes: Siblings<Tag, Note, Pivot<Tag, Note>> {
        return siblings()
    }
}
