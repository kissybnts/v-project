import Vapor
import HTTP

final class UserController {
    let drop: Droplet
    
    init(drop: Droplet) throws {
        self.drop = drop
    }
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try req.user()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.userFromJson()
        user.password = try drop.cipher.encrypt(user.password).makeString()
        try user.save()
        let token = try getToken(user: user)
        try token.save()
        return try user.makeJSON(token: token)
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
        
        guard let user = try User.makeQuery().filter(User.emailKey, email).first() else {
            throw Abort.unauthorized
        }
        
        let isMatched = try drop.cipher.match(row: password, encrypted: user.password)
        
        if !isMatched {
            throw Abort.unauthorized
        }
        
        if let token = try AccessToken.makeQuery().filter(User.foreignIdKey, user.id!).first() {
            try token.delete()
        }
        
        let token = try getToken(user: user)
        
        try token.save()
        
        return try user.makeJSON(token: token)
    }
    
    private func getToken(user: User) throws -> AccessToken {
        guard let userId = user.id else {
            throw Abort.badRequest
        }
        let hash = try drop.hash.make("sio\(user.email)\(user.updatedAt!.hashValue)").makeString()
        let token = AccessToken(token: hash, userId: userId)
        return token
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

extension CipherProtocol {
    func match(row: String, encrypted: String) throws-> Bool {
        let decrypted = try decrypt(encrypted).makeString()
        return row == decrypted
    }
}
