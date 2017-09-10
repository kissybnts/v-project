import FluentProvider

protocol UserRelationModel {
    var userId: Identifier { get }
}

extension UserRelationModel {
    func checkIsSameUserId(requestedUserId: Int) throws -> Void {
        guard let id = self.userId.wrapped.int else {
            throw Abort.notFound
        }
        if id != requestedUserId {
            throw Abort(.forbidden)
        }
    }
}
