import Vapor
import HTTP

final class SentenceController: ResourceRepresentable {
    func index(_ req: Request) throws -> ResponseRepresentable {
        let userId = try req.userId()
        let sentences = try Sentence.makeQuery().filter(Sentence.Properties.userId, userId).sort(Sentence.Properties.id, .ascending).all()
        return try sentences.makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let sentence = try req.sentence()
        let userId = try req.userId()
        if sentence.userId != userId {
            throw Abort.unauthorized
        }
        
        try sentence.save()
        
        return sentence
    }
    
    
    func makeResource() -> Resource<Sentence> {
        return Resource(
            index: index,
            store: create
        )
    }
}

extension SentenceController: EmptyInitializable {}

extension Request {
    fileprivate func sentence() throws -> Sentence {
        guard let json = json else {
            throw Abort.badRequest
        }
        return try Sentence(json: json)
    }
}
