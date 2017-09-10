import Vapor
import FluentProvider
import HTTP
import AuthProvider
import JWT
import JWTProvider

final class User: Model {
    let storage = Storage()
    
    var name: String
    var password: String
    var email: String
    
    internal struct Properties {
        internal static let id = PropertyKey.id
        internal static let name = PropertyKey.name
        internal static let password = PropertyKey.password
        internal static let email = PropertyKey.email
    }
    
    static let foreignIdKey = "user_id"
    
    init(name: String, password: String, email: String) {
        self.name = name
        self.password = password
        self.email = email
    }
    
    init(row: Row) throws {
        name = try row.get(Properties.name)
        password = try row.get(Properties.password)
        email = try row.get(Properties.email)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.name, name)
        try row.set(Properties.password, password)
        try row.set(Properties.email, email)
        return row
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Properties.name)
            builder.string(Properties.password)
            builder.string(Properties.email, unique: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            name: json.get(Properties.name),
            password: json.get(Properties.password),
            email: json.get(Properties.email)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Properties.id, id)
        try json.set(Properties.name, name)
        try json.set(Properties.email, email)
        return json
    }
    
    func makeJSON(token: String) throws -> JSON {
        var json = JSON()
        try json.set(JSONKeys.single, makeJSON())
        try json.set("token", token)
        return json
    }
    
    internal struct JSONKeys {
        internal static let single = "user"
    }
}

extension User: ResponseRepresentable {}

extension User: Timestampable {}

extension User: Updateable {
    public static var updateableKeys: [UpdateableKey<User>] {
        return [
            UpdateableKey(Properties.name, String.self) { user, name in
                user.name = name
            },
            UpdateableKey(Properties.password, String.self) { user, password in
                user.password = password
            },
            UpdateableKey(Properties.email, String.self) { user, email in
                user.email = email
            }
        ]
    }
}

extension User {
    var notes: Children<User, Note> {
        return children()
    }
}

extension User: TokenAuthenticatable {
    public typealias TokenType = User
    
    static func authenticate(_ token: Token) throws -> User {
        let jwt = try JWT(token: token.string)
        // TODO: need to update to use
        try jwt.verifySignature(using: HS256(key: "SIGNING_KEY".makeBytes()))
        let time = ExpirationTimeClaim(date: Date())
        try jwt.verifyClaims([time])
        guard let userId = jwt.payload.object?[SubjectClaim.name]?.int else {
            throw AuthenticationError.invalidCredentials
        }
        guard let user = try User.makeQuery().find(userId) else {
            throw AuthenticationError.invalidCredentials
        }
        return user
    }
}

extension User: PayloadAuthenticatable {
    typealias PayloadType = Claims
    static func authenticate(_ payload: Claims) throws -> User {
        if payload.expirationTimeClaimValue < Date().timeIntervalSince1970 {
            throw AuthenticationError.invalidCredentials
        }
        
        let userId = payload.subjectClaimValue
        guard let user = try User.makeQuery().find(userId) else {
            throw AuthenticationError.invalidCredentials
        }
        
        return user
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
