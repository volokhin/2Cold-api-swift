// Delo © 2GIS

import Foundation

public final class FoundationAssembly: IAssembly {

    public init() {}

    public func registerDependencies(container: IContainer) {
        container.register(ILogger.self, as: NullLogger.self)
    }
}
