import FluentProvider

protocol UserRelationModel {
    var userId: Identifier { get }
}

extension UserRelationModel {
    func checkIsSameUserId(requestedUserId: Int) throws -> Void {
        guard let id = self.userId.wrapped.int else {
            throw AuthorizationError.userIdMisMatch(requestedId: requestedUserId, targetId: nil)
        }
        if id != requestedUserId {
            throw AuthorizationError.userIdMisMatch(requestedId: requestedUserId, targetId: id)
        }
    }
}
