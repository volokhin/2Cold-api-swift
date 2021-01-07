import Foundation
import AppFoundation
import Vapor

public final class AppAssembly: IAssembly {

    private let app: Application

    public init(_ app: Application) {
        self.app = app
    }

    public func registerDependencies(container: IContainer) {
        container.register(HtmlParserService.self) { _ in
            HtmlParserService(logger: self.app.logger)
        }
        container.register(FreezerStorage.self) { _ in
            FreezerStorage(logger: self.app.logger)
        }
    }
}
