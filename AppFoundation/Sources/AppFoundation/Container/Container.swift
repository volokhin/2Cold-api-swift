import Foundation

// MARK: - ISingleton

public protocol ISingleton: AnyObject {
    init()
}

// MARK: - IPerRequest

public protocol IPerRequest: AnyObject {
    associatedtype Arguments
    init(args: Arguments)
}

// MARK: - AnyResolvable

private struct AnyResolvable: Equatable {
    private let factory: (IContainer) -> Any
    fileprivate let identifier: ObjectIdentifier

    init<T: ISingleton>(type: T.Type) {
        self.identifier = ObjectIdentifier(type)
        self.factory = { _ in return T() }
    }

    init(factory: @escaping (IContainer) -> Any) {
        self.identifier = ObjectIdentifier(Any.self)
        self.factory = factory
    }

    func resolve(_ container: IContainer) -> Any {
        return factory(container)
    }

    static func == (lhs: AnyResolvable, rhs: AnyResolvable) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - Container

public protocol IContainer: AnyObject {

    /// Регистрирует singleton зависимость в контейнере на основе протокола и реализации
    /// - Parameters:
    ///   - protocol: Протокол
    ///   - service: Реализация
    func register<Protocol, Service: ISingleton>(_ protocol: Protocol.Type, as service: Service.Type)

    /// Переопределяет регистрацию singleton зависимости в контейнере на основе протокола и реализации
    /// - Parameters:
    ///   - protocol: Протокол
    ///   - service: Реализация
    func replace<Protocol, Service: ISingleton>(_ protocol: Protocol.Type, as service: Service.Type)

    /// Регистрирует singleton зависимость в контейнере на основе фабрики
    /// - Parameters:
    ///   - protocol: Протокол
    ///   - factory: Фабрика
    func register<Protocol>(_ protocol: Protocol.Type, factory: @escaping (IContainer) -> Protocol)

    /// Переопределяет регистрацию singleton зависимости в контейнере на основе фабрики
    /// - Parameters:
    ///   - protocol: Протокол
    ///   - factory: Фабрика
    func replace<Protocol>(_ protocol: Protocol.Type, factory: @escaping (IContainer) -> Protocol)

    /// Очищает список всех регистраций
    func unregisterAll()

    /// Извлекает зависимость из контейнера. Каждый раз будет возвращаться один и тот же экземпляр объекта
    func singleton<T>() -> T

    /// Извлекает зависимость из контейнера. Каждый раз будет возвращаться новый экземпляр объекта
    /// - Parameter args: Аргументы, необходимые для инициализации объекта
    func perRequest<T: IPerRequest>(args: T.Arguments) -> T
}

final class Container {
    static let shared: IContainer = Container()
    private let queue = DispatchQueue(label: "Container Queue")
    private var registrations: [ObjectIdentifier: AnyResolvable] = [:]
    private var singletons: [ObjectIdentifier: AnyObject] = [:]
    private init() { }
}

// MARK: - IContainer

extension Container: IContainer {

    func register<Protocol, Service: ISingleton>(_ protocol: Protocol.Type, as service: Service.Type) {
        queue.sync {
            let key = ObjectIdentifier(`protocol`)
            let value = AnyResolvable(type: service)
            assert(
                registrations[key] == nil || registrations[key] == value,
                .alreadyRegisteredAssertion(`protocol`, service)
            )
            registrations[key] = value
        }
    }

    func register<Protocol>(_ protocol: Protocol.Type, factory: @escaping (IContainer) -> Protocol) {
        queue.sync {
            let key = ObjectIdentifier(`protocol`)
            let value = AnyResolvable(factory: factory)
            assert(
                registrations[key] == nil,
                .alreadyRegisteredAssertion(`protocol`)
            )
            registrations[key] = value
        }
    }

    func replace<Protocol, Service: ISingleton>(_ protocol: Protocol.Type, as service: Service.Type) {
        queue.sync {
            let key = ObjectIdentifier(`protocol`)
            let value = AnyResolvable(type: service)
            registrations[key] = value
        }
    }

    func replace<Protocol>(_ protocol: Protocol.Type, factory: @escaping (IContainer) -> Protocol) {
        queue.sync {
            let key = ObjectIdentifier(`protocol`)
            let value = AnyResolvable(factory: factory)
            registrations[key] = value
        }
    }

    func unregisterAll() {
        queue.sync {
            registrations.removeAll()
            singletons.removeAll()
        }
    }

    func perRequest<T: IPerRequest>(args: T.Arguments) -> T {
        return T(args: args)
    }

    func singleton<T>() -> T {
        let key = ObjectIdentifier(T.self)
        if let cached: T = cachedInstance(forKey: key) {
            // Если по ключу что-то есть в кэше, возвращаем
            return cached
        } else if let singleton = T.self as? ISingleton.Type, let instance = singleton.init() as? T {
            // Если пытаемся резолвить полноценный тип (не протокол)
            // и он конформит ISingleton, создаем экземпляр на лету
            cacheInstance(instance as AnyObject, forKey: key)
            return instance
        } else if let resolvable = registration(forKey: key), let instance = resolvable.resolve(self) as? T {
            // Если пытаемся резолвить протокол и в списке регистраций
            // есть соответствующая ему реализация, создаем экземпляр на лету
            cacheInstance(instance as AnyObject, forKey: key)
            return instance
        } else {
            // Сорян, мы пытались
            fatalError(.notRegisteredAssertion(T.self))
        }
    }
}

// MARK: - IContainer Extensions

public extension IContainer {

    /// Извлекает зависимость из контейнера. Каждый раз будет возвращаться новый экземпляр объекта
    func perRequest<T: IPerRequest>() -> T where T.Arguments == Void {
        return perRequest(args: ())
    }
}

// MARK: - IPerRequest Extensions

public extension IPerRequest where Arguments == Void {
    init() {
        self.init(args: ())
    }
}

// MARK: - Private

private extension Container {

    func registration(forKey key: ObjectIdentifier) -> AnyResolvable? {
        queue.sync {
            return registrations[key]
        }
    }

    func cachedInstance<T>(forKey key: ObjectIdentifier) -> T? {
        queue.sync {
            return singletons[key] as? T
        }
    }

    func cacheInstance(_ instance: AnyObject, forKey key: ObjectIdentifier) {
        queue.sync {
            singletons[key] = instance
        }
    }
}

// MARK: - String Extensions

private extension String {

    static func alreadyRegisteredAssertion(_ protocol: Any, _ service: Any) -> String {
        return "Instance '\(service)' for protocol '\(`protocol`)' already registered in the Container"
    }

    static func alreadyRegisteredAssertion(_ protocol: Any) -> String {
        return "Protocol '\(`protocol`)' already registered in the Container"
    }

    static func notRegisteredAssertion(_ service: Any) -> String {
        return "Service \(service) is not registered in the Container"
    }
}
