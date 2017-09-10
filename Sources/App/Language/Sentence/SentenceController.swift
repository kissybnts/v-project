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
            return Response(status: .forbidden, body: "forbbiden")
        }
        
        try sentence.save()
        
        return sentence
    }
    
    func show(_ req: Request, sentence: Sentence) -> ResponseRepresentable {
        return sentence
    }
    
    func update(_ req: Request, sentence: Sentence) throws -> ResponseRepresentable {
        let userId = try req.userId()
        if sentence.userId != userId {
            throw Abort.init(.forbidden)
        }
        try sentence.update(for: req)
        try sentence.save()
        
        return sentence
    }
    
    func delete(_ req: Request, sentence: Sentence) throws -> ResponseRepresentable {
        let userId = try req.userId()
        if sentence.userId != userId {
            throw Abort.init(.forbidden)
        }
        try sentence.delete()
        return Response(status: .ok)
    }
    
    func clear(_ req: Request) throws -> ResponseRepresentable {
        let userId = try req.userId()
        try Sentence.makeQuery().filter(Sentence.Properties.userId, userId).delete()
        return Response(status: .ok)
    }
    
    func makeResource() -> Resource<Sentence> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: update,
            destroy: delete,
            clear: clear
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
