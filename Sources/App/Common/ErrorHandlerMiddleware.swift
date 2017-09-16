import HTTP

final class ErrorHandlerMiddleware: Middleware {
    // TODO: replace print() to logger
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch AuthorizationError.userIdMisMatch (let error) {
            print("UserID mismatch: requestId: \(String(describing: error.requestedId)), targetId: \(String(describing: error.targetId))")
            return try makeErrorResponse(status: .forbidden, message: "Not permitted operation")
        } catch ValidationError.requiredParameterMissing (let parameterName) {
            print("Required field(\(parameterName)) is missing")
            return try makeErrorResponse(status: .badRequest, message: "\(parameterName) is missing")
        } catch ValidationError.invalidData (let error) {
            print("\(error.parameterName) is invalid. requested value is \(error.dataString)")
            return try makeErrorResponse(status: .badRequest, message: "\(error.parameterName) is invalid")
        } catch let error {
            print(error.localizedDescription)
            return try makeErrorResponse(status: .internalServerError, message: "Internal server error occurred")
        }
    }
    
    private func makeErrorResponse(status: Status, message: String) throws -> Response {
        let json = try makeErrorBodyJSON(status: status, message: message)
        return Response(status: status, body: json)
    }
    
    private func makeErrorBodyJSON(status: Status, message: String) throws -> JSON {
        var json = JSON()
        try json.set("status", status.statusCode)
        try json.set("message", message)
        return json
    }
}
