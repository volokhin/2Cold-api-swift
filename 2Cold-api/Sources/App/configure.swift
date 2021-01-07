import Vapor
import AppFoundation

// configures your application
public func configure(_ app: Application) throws {
    Assembler.shared.register([
        FoundationAssembly(),
        AppAssembly(app)
    ])
//    app.middleware.use(SessionsMiddleware(session: app.sessions.driver))
    try routes(app)
}
