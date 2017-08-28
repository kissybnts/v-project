import Vapor
import HTTP

final class NoteController: ResourceRepresentable {
    func index(_ req: Request) throws -> ResponseRepresentable {
        guard let userId = try req.user().id else {
            throw Abort.unauthorized
        }
        let notes = try Note.makeQuery().filter(User.foreignIdKey, userId).sort(Note.idKey, .ascending).all()
        return try notes.makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let note = try req.note()
        try note.save()
        return note
    }
    
    func show(_ req: Request, note: Note) throws -> ResponseRepresentable {
        return note
    }
    
    func delete(_ req: Request, note: Note) throws -> ResponseRepresentable {
        try note.delete()
        return Response(status: .ok)
    }
 
    func clear(_ req: Request) throws -> ResponseRepresentable {
        try Note.makeQuery().delete()
        return Response(status: .ok)
    }
    
    func update(_ req: Request, note: Note) throws -> ResponseRepresentable {
        try note.update(for: req)
        
        try note.save()
        return note
    }
    
    func replace(_ req: Request, note: Note) throws -> ResponseRepresentable {
        let new = try req.note()
        
        note.title = new.title
        note.body = new.body
        
        try note.save()
        
        return note
    }
    
    func makeResource() -> Resource<Note> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: update,
            replace: replace,
            destroy: delete,
            clear: clear
        )
    }
}

extension Request {
    func note() throws -> Note {
        guard let json = json else {
            throw Abort.badRequest
        }
        return try Note(json: json)
    }
}

extension NoteController: EmptyInitializable { }
