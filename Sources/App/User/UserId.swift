import Vapor
import HTTP
import AuthProvider
import JWTProvider
import JWT

final class UserId: PayloadAuthenticatable, TokenAuthenticatable {
    typealias PayloadType = Claims
    typealias TokenType = UserId
    
    let value: Int
    init(id: Int) {
        self.value = id
    }
    
    static func authenticate(_ payload: Claims) throws -> UserId {
        if payload.expirationTimeClaimValue < Date().timeIntervalSince1970 {
            throw AuthenticationError.invalidCredentials
        }
        
        let userId = payload.subjectClaimValue
        return UserId(id: userId)
    }
    
    static func authenticate(_ token: Token) throws -> UserId {
        let jwt = try JWT(token: token.string)
        // TODO: need to update to use
        try jwt.verifySignature(using: HS256(key: "SIGNING_KEY".makeBytes()))
        let time = ExpirationTimeClaim(date: Date())
        do {
            try jwt.verifyClaims([time])
        } catch JWTError.verificationFailedForClaim {
            throw AuthError.tokenExpired
        }
        guard let userId = jwt.payload.object?[SubjectClaim.name]?.int else {
            throw AuthenticationError.invalidCredentials
        }
        return UserId(id: userId)
    }
}

class Claims: JSONInitializable {
    var subjectClaimValue: Int
    var expirationTimeClaimValue: Double
    
    public required init(json: JSON) throws {
        guard let subjectClaimValue = try json.get(SubjectClaim.name) as Int? else {
            throw AuthenticationError.invalidCredentials
        }
        self.subjectClaimValue = subjectClaimValue
        
        guard let expirationTimeClaimValue = try json.get(ExpirationTimeClaim.name) as Double? else {
            throw AuthenticationError.invalidCredentials
        }
        self.expirationTimeClaimValue = expirationTimeClaimValue
    }
}
