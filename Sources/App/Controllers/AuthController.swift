import Vapor
import FluentProvider
import HTTP

final class AuthController {
    private let drop: Droplet
    
    init(drop: Droplet) {
        self.drop = drop
    }
    
    func signUp(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.userFromJson()
        user.password = try encrypt(row: user.password)
        try user.save()
        let token = try getToken(user: user)
        try token.save()
        return try user.makeJSON(token: token)
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
            throw Abort.badRequest
        }
        
        if let token = try AccessToken.makeQuery().filter(User.foreignIdKey, user.id!).first() {
            try token.delete()
        }
        
        let token = try getToken(user: user)
        
        try token.save()
        
        return try user.makeJSON(token: token)
    }
    
    private func encrypt(row: String) throws -> String {
        let encrypted = try drop.cipher.encrypt(row).makeString()
        return encrypted
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
}

extension CipherProtocol {
    func match(row: String, encrypted: String) throws-> Bool {
        let decrypted = try decrypt(encrypted).makeString()
        return row == decrypted
    }
}
