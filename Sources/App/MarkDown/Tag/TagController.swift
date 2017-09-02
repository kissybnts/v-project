import Vapor
import HTTP

final class TagController: ResourceRepresentable {
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        let tags = try Tag.makeQuery().sort(Tag.Properties.id, .ascending).all()
        return try tags.makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let tag = try req.tag()
        try tag.save()
        return tag
    }
    
    func show(_ req: Request, tag: Tag) throws -> ResponseRepresentable {
        let own = req.query?["own"]?.bool
        if own == nil {
            return try tag.makeJsonWithNotes()
        }

        let userId = try req.userId()
        return try tag.makeJsonWithNotes(userId: userId)
    }
    
    func update(_ req: Request, tag: Tag) throws -> ResponseRepresentable {
        try tag.update(for: req)
        try tag.save()
        return tag
    }
    
    func delete(_ req: Request, tag: Tag) throws -> ResponseRepresentable {
        try TagNoteRelation.delteAllByTag(tag: tag)
        try tag.delete()
        return Response(status: .ok)
    }
    
    func makeResource() -> Resource<Tag> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: update
        )
    }
}

extension TagController: EmptyInitializable {}

extension Request {
    func tag() throws -> Tag {
        guard let json = json else {
            throw Abort.badRequest
        }
        return try Tag(json: json)
    }
}
