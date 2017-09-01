import Vapor
import FluentProvider
import HTTP

final class Note: Model {

    let storage = Storage()
    
    let userId: Identifier
    var title: String
    var body: String
    var isPinned: Bool
    
    internal struct Properties {
        internal static let id = PropertyKey.id
        internal static let userId = User.foreignIdKey
        internal static let title = PropertyKey.title
        internal static let body = "body"
        internal static let isPinned = "is_pinned"
    }
    
    static let foreinIdKey = "note_id"
    
    init(title: String, body: String, userId: Identifier, isPinned: Bool = false) {
        self.title = title
        self.body = body
        self.userId = userId
        self.isPinned = isPinned
    }
    
    init(row: Row) throws {
        title = try row.get(Properties.title)
        body = try row.get(Properties.body)
        userId = try row.get(Properties.userId)
        isPinned = try row.get(Properties.isPinned)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.title, title)
        try row.set(Properties.body, body)
        try row.set(Properties.userId, userId)
        try row.set(Properties.isPinned, isPinned)
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
            builder.string(Properties.title)
            builder.custom(Properties.body, type: "text")
            builder.parent(User.self)
            builder.bool(Properties.isPinned, default: false)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Note: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            title: json.get(Properties.title),
            body: json.get(Properties.body),
            userId: json.get(Properties.userId),
            isPinned: json.get(Properties.isPinned)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Properties.id, id)
        try json.set(Properties.title, title)
        try json.set(Properties.body, body)
        try json.set(Properties.isPinned, isPinned)
        return json
    }
    
    func makeJsonWithTags() throws -> JSON {
        var json = try self.makeJSON()
        let tags = try self.tags.all()
        try json.set(Tag.JSONKeys.multi, tags.makeJSON())
        return json
    }
    
    internal struct JSONKeys {
        internal static let multi = "notes"
    }
}

extension Note: ResponseRepresentable {}

extension Note: Timestampable {}

extension Note: Updateable {
    public static var updateableKeys: [UpdateableKey<Note>] {
        return [
            UpdateableKey(Properties.title, String.self) { note, title in
                note.title = title
            },
            UpdateableKey(Properties.body, String.self) { note, body in
                note.body = body
            },
            UpdateableKey(Properties.isPinned, Bool.self) { note, isPinned in
                note.isPinned = isPinned
            }
        ]
    }
}

extension Note {
    var tags: Siblings<Note, Tag, Pivot<Tag, Note>> {
        return siblings()
    }
    func addTags(tags: [Tag]) throws -> Void {
        guard let noteId = self.id else {
            return
        }
        try tags.forEach { tag in
            guard let tagId = tag.id else {
                return
            }
            var row = Row()
            try row.set(Note.foreinIdKey, noteId)
            try row.set(Tag.foreignIdKey, tagId)
            try Pivot<Tag, Note>(row: row).save()
        }
    }
}
