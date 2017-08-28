import Vapor
import FluentProvider

final class AccessToken: Model {
    let storage = Storage()
    
    let token: String
    let userId: Identifier
    
    static let tokenKey = "token"
    
    init(token: String, userId: Identifier) {
        self.token = token
        self.userId = userId
    }
    
    init(row: Row) throws {
        token = try row.get(AccessToken.tokenKey)
        userId = try row.get(User.foreignIdKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(AccessToken.tokenKey, token)
        try row.set(User.foreignIdKey, userId)
        return row
    }
}

extension AccessToken: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(AccessToken.tokenKey)
            builder.parent(User.self, unique: true)
        }
        try database.index(AccessToken.tokenKey, for: AccessToken.self)
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension AccessToken: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            token: json.get(AccessToken.tokenKey),
            userId: json.get(User.foreignIdKey)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(AccessToken.tokenKey, token)
        return json
    }
}

extension AccessToken: ResponseRepresentable {}

extension AccessToken: Timestampable {}
