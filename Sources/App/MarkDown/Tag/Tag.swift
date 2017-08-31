import Vapor
import FluentProvider
import HTTP

final class Tag: Model {
    let storage = Storage()
    
    var name: String
    
    public struct Properties {
        public static let id = "id"
        public static let name = "name"
    }
    
    init(name: String) {
        self.name = name
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
        try self.init(name: json.get(Properties.name))
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Properties.id, id)
        try json.set(Properties.name, name)
        return json
    }
    
    func makeJsonWithNotes(userId: Identifier) throws -> JSON {
        var json = try self.makeJSON()
        let notes = try self.notes.makeQuery().filter(User.foreignIdKey, userId).sort(Note.idKey, .ascending).all()
        try json.set("notes", notes.makeJSON())
        return json
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
