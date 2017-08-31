import Vapor
import HTTP

final class CategoryController: ResourceRepresentable {
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        let userId = try req.userId()
        
        let categories = try Category.makeQuery().filter(Category.Properties.userId, userId).sort(Category.Properties.id, .ascending).all()
        
        return try categories.makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let category = try req.category()
        let userId = try req.userId()
        
        if category.userId != userId {
            throw Abort.unauthorized
        }
        
        try category.save()
        
        return category
    }
    
    func show(_ req: Request, category: Category) throws -> ResponseRepresentable {
        return try category.makeJsonWithSentenes()
    }
    
    func update(_ req: Request, category: Category) throws -> ResponseRepresentable {
        let userId = try req.userId()
        if category.userId != userId {
            throw Abort.unauthorized
        }
        
        try category.update(for: req)
        try category.save()
        
        return category
    }
    
    func delete(_ req: Request, category: Category) throws -> ResponseRepresentable {
        let userId = try req.userId()
        if category.userId != userId {
            throw Abort.unauthorized
        }
        
        try category.sentences.delete()
        
        try category.delete()
        return Response(status: .ok)
    }
    
    func clear(_ req: Request) throws -> ResponseRepresentable {
        let userId = try req.userId()
        
        try Category.makeQuery().filter(Category.Properties.userId, userId).delete()
        return Response(status: .ok)
        
    }
    
    func makeResource() -> Resource<Category> {
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

extension CategoryController: EmptyInitializable {}

extension Request {
    fileprivate func category() throws -> Category {
        guard let json = json else {
            throw Abort.badRequest
        }
        
        return try Category(json: json)
    }
}
