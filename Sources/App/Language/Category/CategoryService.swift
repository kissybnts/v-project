import Vapor
import FluentProvider

internal final class CategoryService {
    static func checkIsUsers(categoryId: Identifier, userId: Identifier) throws -> Void {
        // TODO: Move this kind of db access part to other repository class
        let category = try Category.makeQuery().filter(Category.Properties.id, categoryId).filter(Category.Properties.userId, userId).first()
        if category == nil {
            throw AuthorizationError.userIdMisMatch(requestedId: categoryId.wrapped.int, targetId: userId.wrapped.int)
        }
    }
    
    static func createNote(category: Category) throws -> Note {
        let sentences = try category.sentences.all()
        
        let originals = sentences.map { sentence in
                return sentence.original
            }.joined(separator: "\n")
        
        let translations = sentences.map { sentence in
                return sentence.translation
            }.joined(separator: "\n")
        
        let originalHeader = "# Original text\n"
        let translationHeader = "# Translation text\n"
        
        let body = "\(originalHeader)\n\(originals)\n\n\(translationHeader)\n\(translations)"
        
        let note = Note(title: category.name, body: body, userId: category.userId)
        return note
    }
}
