import Vapor
import HTTP

final class UserController: ResourceRepresentable {
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try User.all().makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        try user.save()
        return user
    }
    
    func show(_ req: Request, user: User) -> ResponseRepresentable {
        return user
    }
    
    func delete(_ req: Request, user: User) throws -> ResponseRepresentable {
        try user.delete()
        return Response(status: .ok)
    }
    
    func clear(_ req: Request) throws -> ResponseRepresentable {
        try User.makeQuery().delete()
        return Response(status: .ok)
    }
    
    func update(_ req: Request, user: User) throws -> ResponseRepresentable {
        try user.update(for: req)
        
        try user.save()
        return user
    }
    
    func replace(_ req: Request, user: User) throws -> ResponseRepresentable {
        let new = try req.user()
        
        user.name = new.name
        user.password = new.password
        user.email = new.email
        
        try user.save()
        
        return user
    }
    
    func notes(_ req: Request) throws -> ResponseRepresentable {
        
        guard let userId = req.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        let notes = try Note.makeQuery().filter(User.foreignIdKey, userId).all()
        
        return try notes.makeJSON()
    }
    
    func makeResource() -> Resource<User> {
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
    func user() throws -> User {
        guard let json = json else {
            throw Abort.badRequest
        }
        
        return try User(json: json)
    }
}

extension UserController: EmptyInitializable {}
