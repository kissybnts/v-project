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
        return try user.makeJSON(token: token)
    }
    
    func login(_ req: Request) throws -> ResponseRepresentable {
        let loginRequest = try req.loginRequest()
        
        guard let user = try User.makeQuery().filter(User.Properties.email, loginRequest.email).first() else {
            throw Abort.unauthorized
        }
        
        let isMatched = try drop.cipher.match(row: loginRequest.password, encrypted: user.password)
        
        if !isMatched {
            throw Abort.badRequest
        }

        let token = try getToken(user: user)
        
        return try user.makeJSON(token: token)
    }
    
    private func encrypt(row: String) throws -> String {
        let encrypted = try drop.cipher.encrypt(row).makeString()
        return encrypted
    }
    
    private func getToken(user: User) throws -> String {
        guard let userId = user.id else {
            throw Abort.badRequest
        }
        let jwtToken = try drop.createJwtToken(userId.wrapped.int!)
        return jwtToken
    }
}

extension Request {
    func userFromJson() throws -> User {
        guard let json = json else {
            throw Abort.badRequest
        }
        
        return try User(json: json)
    }
    
    func loginRequest() throws -> LoginRequest {
        guard let json = json else {
            throw Abort.badRequest
        }
        
        return try LoginRequest(json: json)
    }
}

extension CipherProtocol {
    func match(row: String, encrypted: String) throws-> Bool {
        let decrypted = try decrypt(encrypted).makeString()
        return row == decrypted
    }
}
