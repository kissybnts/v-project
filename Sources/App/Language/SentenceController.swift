import Vapor
import HTTP

final class SentenceController: ResourceRepresentable {
    func index(_ req: Request) throws -> ResponseRepresentable {
        let userId = try req.userId()
        let sentences = try Sentence.makeQuery().filter(Sentence.Properties.userId, userId).sort(Sentence.Properties.id, .ascending).all()
        return try sentences.makeJSON()
    }
    
    
    func makeResource() -> Resource<Sentence> {
        return Resource(
            index: index
        )
    }
}

extension SentenceController: EmptyInitializable {}
