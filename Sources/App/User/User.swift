import Vapor
import FluentProvider
import HTTP
import AuthProvider

final class User: Model {
    let storage = Storage()
    
    var name: String
    var password: String
    var email: String
    
    static let idKey = "id"
    static let foreignIdKey = "user_id"
    static let nameKey = "name"
    static let passwordKey = "password"
    static let emailKey = "email"
    
    init(name: String, password: String, email: String) {
        self.name = name
        self.password = password
        self.email = email
    }
    
    init(row: Row) throws {
        name = try row.get(User.nameKey)
        password = try row.get(User.passwordKey)
        email = try row.get(User.emailKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(User.nameKey, name)
        try row.set(User.passwordKey, password)
        try row.set(User.emailKey, email)
        return row
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(User.nameKey)
            builder.string(User.passwordKey)
            builder.string(User.emailKey, unique: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            name: json.get(User.nameKey),
            password: json.get(User.passwordKey),
            email: json.get(User.emailKey)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(User.idKey, id)
        try json.set(User.nameKey, name)
        try json.set(User.emailKey, email)
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
            UpdateableKey(User.nameKey, String.self) { user, name in
                user.name = name
            },
            UpdateableKey(User.passwordKey, String.self) { user, password in
                user.password = password
            },
            UpdateableKey(User.emailKey, String.self) { user, email in
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
