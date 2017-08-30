import HTTP

extension Request {
    func user() throws -> User {
        return try auth.assertAuthenticated()
    }
    func userId() throws -> Identifier {
        let user: User = try self.user()
        if let userId = user.id {
            return userId
        }
        throw Abort.unauthorized
    }
}
