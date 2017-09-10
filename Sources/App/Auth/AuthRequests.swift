import JSON

final class LoginRequest {
    let email: String
    let password: String
    
    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    convenience init(json: JSON) throws {
        try self.init(
            email: json.get(User.Properties.email),
            password: json.get(User.Properties.password)
        )
    }
}
