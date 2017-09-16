import FluentProvider

protocol UserRelationModel {
    var userId: Identifier { get }
}

extension UserRelationModel {
    func checkIsSameUserId(requesterUserId: Int) throws -> Void {
        guard let id = self.userId.wrapped.int else {
            throw AuthError.userIdMisMatch(requestedId: requesterUserId, targetId: nil)
        }
        if id != requesterUserId {
            throw AuthError.userIdMisMatch(requestedId: requesterUserId, targetId: id)
        }
    }
}
