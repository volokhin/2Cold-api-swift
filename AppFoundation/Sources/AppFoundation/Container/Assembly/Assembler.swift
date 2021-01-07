import Foundation

/// Сборщик, который умеет регистрировать зависимости экземпляров `IAssembly` в контейнере
public final class Assembler {

    /// Глобальный экземпляр сборщика
    public static let shared = Assembler()

    private let container: IContainer
    private var knownAssemblies: Set<ObjectIdentifier> = []

    private init() {
        self.container = Container.shared
    }

    /// Регистрирует зависимости экземпляра `IAssembly` в контейнере
    /// - Parameter assembly: Экземпляр `IAssembly`
    /// - Note: This method is not thread-safe
    public func register(_ assembly: IAssembly) {
        let id  = ObjectIdentifier(type(of: assembly))
        if !knownAssemblies.contains(id) {
            assembly.registerDependencies(container: container)
            knownAssemblies.insert(id)
        }
    }
}

// MARK: - Assembler

extension Assembler {
    /// Регистрирует зависимости экземпляров `IAssembly` в контейнере
    /// - Parameter assembly: Экземпляры `IAssembly`
    /// - Note: This method is not thread-safe
    public func register(_ assemblies: [IAssembly]) {
        assemblies.forEach(register)
    }
}
