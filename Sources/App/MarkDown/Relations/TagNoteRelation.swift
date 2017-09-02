import Vapor
import FluentProvider
import HTTP

final class TagNoteRelation: Model {
    let storage = Storage()
    static let entity = "tag_note"
    
    let tagId: Identifier
    let noteId: Identifier
    
    internal struct Properties {
        internal static let id = PropertyKey.id
        internal static let tagId = Tag.foreinIdKey
        internal static let noteId = Note.foreinIdKey
    }
    
    init(tagId: Identifier, noteId: Identifier) {
        self.tagId = tagId
        self.noteId = noteId
    }
    
    convenience init(tag: Tag, note: Note) throws {
        guard let tagId = tag.id else {
            throw Abort.serverError
        }
        guard let noteId = note.id else {
            throw Abort.serverError
        }
        self.init(tagId: tagId, noteId: noteId)
    }

    init(row: Row) throws {
        tagId = try row.get(Properties.tagId)
        noteId = try row.get(Properties.noteId)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.tagId, tagId)
        try row.set(Properties.noteId, noteId)
        return row
    }
}

extension TagNoteRelation: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignKey(for: Tag.self)
            builder.foreignKey(for: Note.self)
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension TagNoteRelation: Timestampable {}

extension TagNoteRelation {
    internal static func delteAllByTag(tag: Tag) throws -> Void {
        guard let tagId = tag.id else {
            return
        }
        try TagNoteRelation.makeQuery().filter(Properties.tagId, tagId).delete()
    }
    
    internal static func deleteAllByNote(note: Note) throws -> Void {
        guard let noteId = note.id else {
            return
        }
        
        try TagNoteRelation.makeQuery().filter(Properties.noteId, noteId).delete()
    }
}
