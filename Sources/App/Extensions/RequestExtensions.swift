import HTTP

extension Request {
    func user() throws -> User {
        let userId = try self.userId()
        guard let user = try User.makeQuery().find(userId) else {
            throw Abort.notFound
        }
        return user
    }
    func userId() throws -> Int {
        let userId: UserId = try auth.assertAuthenticated()
        return userId.value
    }
}
