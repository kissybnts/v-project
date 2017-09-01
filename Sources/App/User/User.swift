import Vapor
import FluentProvider
import HTTP
import AuthProvider

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
    
    func makeJSON(token: AccessToken) throws -> JSON {
        var json = JSON()
        try json.set("user", makeJSON())
        try json.set("token", token.token)
        return json
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
    public typealias TokenType = AccessToken
}
