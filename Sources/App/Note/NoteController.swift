import Vapor
import HTTP

final class NoteController: ResourceRepresentable {
    func index(_ req: Request) throws -> ResponseRepresentable {
        let userId = try req.userId()
        
        let filterParamPair = getFilterParam(req: req, userId: userId)
        
        let query = try Note.makeQuery()
        
        try filterParamPair.forEach { key, value in
            try query.filter(key, value)
        }
        
        let notes = try query.sort(Note.idKey, .ascending).all()
        return try notes.makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let userId = try req.userId()
        let note = try req.note()
        
        if note.userId != userId {
            throw Abort.unauthorized
        }
        
        try note.save()
        return note
    }
    
    func show(_ req: Request, note: Note) throws -> ResponseRepresentable {
        return note
    }
    
    func delete(_ req: Request, note: Note) throws -> ResponseRepresentable {
        let userId = try req.userId()
        
        if userId != note.userId {
            throw Abort.unauthorized
        }
        
        try note.delete()
        return Response(status: .ok)
    }
 
    func clear(_ req: Request) throws -> ResponseRepresentable {
        guard let userId = try req.user().id else {
            throw Abort.unauthorized
        }
        try Note.makeQuery().filter(User.foreignIdKey, userId).delete()
        return Response(status: .ok)
    }
    
    func update(_ req: Request, note: Note) throws -> ResponseRepresentable {
        let userId = try req.userId()
        try note.update(for: req)
        
        if userId != note.userId {
            throw Abort.unauthorized
        }
        
        try note.save()
        return note
    }
    
    func replace(_ req: Request, note: Note) throws -> ResponseRepresentable {
        let userId = try req.userId()
        if userId != note.userId {
            throw Abort.unauthorized
        }
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
    
    private func getFilterParam(req: Request, userId: Identifier) -> Dictionary<String, NodeRepresentable> {
        var dic = Dictionary<String, NodeRepresentable>()
        
        dic[User.foreignIdKey] = userId
        if let isPinned = req.query?[Note.isPinnedKey]?.bool {
            dic[Note.isPinnedKey] = isPinned
        }
        
        return dic
    }
}

extension Request {
    func userId() throws -> Identifier {
        let user: User = try self.user()
        if let userId = user.id {
            return userId
        }
        throw Abort.unauthorized
    }
    func note() throws -> Note {
        guard let json = json else {
            throw Abort.badRequest
        }
        return try Note(json: json)
    }
}

extension NoteController: EmptyInitializable { }
