import Vapor
import FluentProvider

final class SentenceService {
    static func clearSentences(userId: Int) throws -> Void {
        try Sentence.makeQuery().filter(Sentence.Properties.userId, userId).delete()
    }
}
