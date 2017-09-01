import Vapor
import FluentProvider

final class AccessToken: Model {
    let storage = Storage()
    
    let token: String
    let userId: Identifier
    
    internal struct Properties {
        internal static let token = "token"
        internal static let userId = User.foreignIdKey
    }
    
    init(token: String, userId: Identifier) {
        self.token = token
        self.userId = userId
    }
    
    init(row: Row) throws {
        token = try row.get(Properties.token)
        userId = try row.get(Properties.userId)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Properties.token, token)
        try row.set(Properties.userId, userId)
        return row
    }
}

extension AccessToken: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Properties.token)
            builder.parent(User.self, unique: true)
        }
        try database.index(Properties.token, for: AccessToken.self)
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension AccessToken: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            token: json.get(Properties.token),
            userId: json.get(Properties.userId)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(JSONKeys.single, token)
        return json
    }
    
    internal struct JSONKeys {
        internal static let single = "token"
    }
}

extension AccessToken: ResponseRepresentable {}

extension AccessToken: Timestampable {}
