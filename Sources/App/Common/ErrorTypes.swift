enum ValidationError: Error {
    case requiredParameterMissing(parameterName: String)
    case invalidData(parameterName: String, dataString: String)
}

enum AuthorizationError: Error {
    case userIdMisMatch(requestedId: Int?, targetId: Int?)
    case badCredential(email: String)
}
