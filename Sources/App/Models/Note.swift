import Vapor
import FluentProvider
import HTTP

final class Note: Model {

    let storage = Storage()
    
    var title: String
    var body: String
    let userId: Identifier
    
    static let idKey = "id"
    static let titleKey = "title"
    static let bodyKey = "body"
    
    init(title: String, body: String, userId: Identifier) {
        self.title = title
        self.body = body
        self.userId = userId
    }
    
    init(row: Row) throws {
        title = try row.get(Note.titleKey)
        body = try row.get(Note.bodyKey)
        userId = try row.get(User.foreignIdKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Note.titleKey, title)
        try row.set(Note.bodyKey, body)
        try row.set(User.foreignIdKey, userId)
        return row
    }
    
    var owner: Parent<Note, User> {
        return parent(id: userId)
    }
}

extension Note: Preparation {
    static func prepare(_ databese: Database) throws {
        try databese.create(self) { builder in
            builder.id()
            builder.string(Note.titleKey)
            builder.custom(Note.bodyKey, type: "text")
            builder.parent(User.self)
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
            body: json.get(Note.bodyKey),
            userId: json.get(User.foreignIdKey)
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
