import Foundation

/// Фабрика, предназначенная для извлечения per-request сущностей из контейнера
/// без необходимости держать ссылку на сам контейнер
public final class Factory<T: IPerRequest>: ISingleton {

    public init() { }

    /// Создает новый экземпляр типа `T`
    /// - Parameter args: Аргументы, необходимые для инициализации объекта
    public func perRequest(args: T.Arguments) -> T {
        return Container.shared.perRequest(args: args)
    }
}

// MARK: - Helpers

public extension Factory where T.Arguments == Void {

    /// Создает новый экземпляр типа `T`
    func perRequest() -> T {
        return perRequest(args: ())
    }
}
