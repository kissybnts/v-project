import Vapor
import FluentProvider

internal final class CategoryService {
    static func checkIsUsers(categoryId: Identifier, userId: Identifier) throws -> Void {
        // TODO: Move this kind of db access part to other repository class
        let category = try Category.makeQuery().filter(Category.Properties.id, categoryId).filter(Category.Properties.userId, userId).first()
        if category == nil {
            throw Abort.badRequest
        }
    }
}
