import Vapor
import HTTP

final class UserController {
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try req.user()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.userFromJson()
        try user.save()
        let token = AccessToken(token: "ramdomString\(user.email)", userId: user.id!)
        try token.save()
        var json = JSON()
        try json.set("user", user.makeJSON())
        try json.set("token", token.makeJSON())
        return json
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
    
    func login(_ req: Request) throws -> ResponseRepresentable {
        guard let json = req.json else {
            throw Abort.badRequest
        }
        guard let email: String = try json.get(User.emailKey) else {
            throw Abort.badRequest
        }
        guard let password: String = try json.get(User.passwordKey) else {
            throw Abort.badRequest
        }
        
        let query = try User.makeQuery().and { and in
            try and.filter(User.emailKey, email)
            try and.filter(User.passwordKey, password)
        }
        
        guard let user = try query.first() else {
            throw Abort.unauthorized
        }
        
        if let token = try AccessToken.makeQuery().filter(User.foreignIdKey, user.id!).first() {
            try token.delete()
        }
        
        let token = AccessToken(token: "newRandomString\(user.email)", userId: user.id!)
        
        try token.save()
        
        return try user.makeJSON(token: token)
    }
}

extension Request {
    func userFromJson() throws -> User {
        guard let json = json else {
            throw Abort.badRequest
        }
        
        return try User(json: json)
    }
    
    func user() throws -> User {
        return try auth.assertAuthenticated()
    }
}

extension UserController: EmptyInitializable {}
