import Vapor
import AuthProvider

extension Droplet {
    func setupRoutes() throws {
        let userController = UserController()
        let authController = AuthController(drop: self)
        
        // able to access without token
        group("v1") { unAuthed in
            unAuthed.post("signup", handler: authController.signUp)
            unAuthed.post("login", handler: authController.login)
        }

        let tokenMiddleware = TokenAuthenticationMiddleware(User.self)
        
        // properly token is required to access
        let authed = grouped(tokenMiddleware).grouped("v1")
        authed.group("me") { me in
            me.get("", handler: userController.index)
            me.patch("", handler: userController.update)
            me.put("", handler: userController.replace)
            me.delete("", handler: userController.delete)
            me.get("notes", handler: userController.notes)
        }
        try authed.resource("notes", NoteController.self)
        try authed.resource("sentences", SentenceController.self)
        try authed.resource("categories", CategoryController.self)
    }
}
