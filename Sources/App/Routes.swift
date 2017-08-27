import Vapor
import AuthProvider

extension Droplet {
    func setupRoutes() throws {
        let userController = UserController()
        get("hello") { req in
            var json = JSON()
            try json.set("hello", "world")
            return json
        }

        get("plaintext") { req in
            return "Hello, world!"
        }

        // response to requests to /info domain
        // with a description of the request
        get("info") { req in
            return req.description
        }

        get("description") { req in return req.description }
        
        try resource("posts", PostController.self)
        
        
        // able to access without token
        group("v1") { unAuthed in
            unAuthed.post("signup", handler: userController.create)
            unAuthed.post("login", handler: userController.login)
        }

        let tokenMiddleware = TokenAuthenticationMiddleware(User.self)
        
        // properly token is required to access
        let authed = grouped(tokenMiddleware).grouped("v1")
        try authed.resource("notes", NoteController.self)
        authed.group("me") { me in
            me.get("", handler: userController.index)
            me.patch("", handler: userController.update)
            me.put("", handler: userController.replace)
            me.delete("", handler: userController.delete)
            me.get("notes", handler: userController.notes)
        }
    }
}
