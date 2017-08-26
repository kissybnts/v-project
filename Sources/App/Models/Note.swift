import Vapor
import FluentProvider
import HTTP

final class Note: Model {

    let storage = Storage()
    
    var title: String
    var body: String
    
    static let idKey = "id"
    static let titleKey = "title"
    static let bodyKey = "body"
    
    init(title: String, body: String) {
        self.title = title
        self.body = body
    }
    
    init(row: Row) throws {
        title = try row.get(Note.titleKey)
        body = try row.get(Note.bodyKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Note.titleKey, title)
        try row.set(Note.bodyKey, body)
        return row
    }
}

extension Note: Preparation {
    static func prepare(_ databese: Database) throws {
        try databese.create(self) { builder in
            builder.id()
            builder.string(Note.titleKey)
            builder.custom(Note.bodyKey, type: "text")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Note: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            title: json.get(Note.titleKey),
            body: json.get(Note.bodyKey)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Note.idKey, id)
        try json.set(Note.titleKey, title)
        try json.set(Note.bodyKey, body)
        return json
    }
}

extension Note: ResponseRepresentable {}

extension Note: Timestampable {}

extension Note: Updateable {
    public static var updateableKeys: [UpdateableKey<Note>] {
        return [
            UpdateableKey(Note.titleKey, String.self) { note, title in
                note.title = title
            },
            UpdateableKey(Note.bodyKey, String.self) { note, body in
                note.body = body
            }
        ]
    }
}

