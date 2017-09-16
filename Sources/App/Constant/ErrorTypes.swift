enum ValidationError: Error {
    case requiredParameterMissing(parameterName: String)
    case invalidData(parameterName: String, dataString: String)
}

enum AuthError: Error {
    case userIdMisMatch(requestedId: Int?, targetId: Int?)
    case badCredential(email: String)
    case tokenExpired
}
