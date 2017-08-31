import Vapor
import FluentProvider
import HTTP

final class Note: Model {

    let storage = Storage()
    
    var title: String
    var body: String
    let userId: Identifier
    var isPinned: Bool
    
    static let idKey = "id"
    static let titleKey = "title"
    static let bodyKey = "body"
    static let isPinnedKey = "is_pinned"
    static let foreinIdKey = "note_id"
    
    init(title: String, body: String, userId: Identifier, isPinned: Bool = false) {
        self.title = title
        self.body = body
        self.userId = userId
        self.isPinned = isPinned
    }
    
    init(row: Row) throws {
        title = try row.get(Note.titleKey)
        body = try row.get(Note.bodyKey)
        userId = try row.get(User.foreignIdKey)
        isPinned = try row.get(Note.isPinnedKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Note.titleKey, title)
        try row.set(Note.bodyKey, body)
        try row.set(User.foreignIdKey, userId)
        try row.set(Note.isPinnedKey, isPinned)
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
            builder.bool(Note.isPinnedKey, default: false)
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
            userId: json.get(User.foreignIdKey),
            isPinned: json.get(Note.isPinnedKey)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Note.idKey, id)
        try json.set(Note.titleKey, title)
        try json.set(Note.bodyKey, body)
        try json.set(Note.isPinnedKey, isPinned)
        return json
    }
    
    func makeJsonWithTags() throws -> JSON {
        var json = try self.makeJSON()
        let tags = try self.tags.all()
        try json.set("tags", tags.makeJSON())
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
            },
            UpdateableKey(Note.isPinnedKey, Bool.self) { note, isPinned in
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
