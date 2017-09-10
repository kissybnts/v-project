import Vapor
import HTTP
import JWT

extension Droplet {
    func createJwtToken(_ userId: Int) throws -> String {
        guard let sig = self.signers?.first?.value else {
            throw Abort.unauthorized
        }
        
        let timeToLive = 60 * 60.0 // 60min
        let claims:[Claim] = [
            ExpirationTimeClaim(date: Date().addingTimeInterval(timeToLive)),
            SubjectClaim(string: String(userId))
        ]
        
        let payload = JSON(claims)
        let jwt = try JWT(payload: payload, signer: sig)
        
        return try jwt.createToken()
    }
}
