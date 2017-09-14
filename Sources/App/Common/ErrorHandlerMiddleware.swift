import HTTP

final class ErrorHandlerMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            print("middleware")
            return try next.respond(to: request)
        } catch let error {
            print(error.localizedDescription)
            return Response(status: .badRequest, body: error.localizedDescription)
        }
    }
}
