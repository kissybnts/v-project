import Vapor
import HTTP

final class UserController {
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try req.user()
    }
    
    func delete(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        try AccessToken.makeQuery().filter(User.foreignIdKey, user.id!).delete()
        try user.delete()
        return Response(status: .ok)
    }
    
    func update(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        try user.update(for: req)
        
        try user.save()
        return user
    }
    
    func replace(_ req: Request) throws -> ResponseRepresentable {
        let new = try req.userFromJson()
        
        let user = try req.user()
        user.name = new.name
        user.password = new.password
        user.email = new.email
        
        try user.save()
        
        return user
    }
    
    func notes(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.user()
        
        let notes = try Note.makeQuery().filter(User.foreignIdKey, user.id).all()
        
        return try notes.makeJSON()
    }
}
