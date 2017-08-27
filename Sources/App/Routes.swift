import Vapor

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
        try resource("notes", NoteController.self)
        try resource("users", UserController.self)
        get("users", ":id", "notes") { req in
            return try userController.notes(req)
        }
    }
}
