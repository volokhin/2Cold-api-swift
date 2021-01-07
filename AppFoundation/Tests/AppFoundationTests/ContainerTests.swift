import XCTest
import Nimble
@testable import AppFoundation

final class ContainerTests: XCTestCase {

    private let container: IContainer = Container.shared

    override func setUp() {
        super.setUp()
        container.unregisterAll()
    }

    func test_извлекается_один_и_тот_же_экземпляр_для_singleton_на_основе_конструктора() {
        container.register(IService.self, as: Service.self)
        let service1: IService = container.singleton()
        let service2: IService = container.singleton()
        expect(service1) === service2
    }

    func test_извлекается_один_и_тот_же_экземпляр_для_singleton_на_основе_фабрики() {
        container.register(IService.self) { _ in Service() }
        let service1: IService = container.singleton()
        let service2: IService = container.singleton()
        expect(service1) === service2
    }

    func test_извлекается_один_и_тот_же_экземпляр_для_разных_протоколов() {
        let service = ServiceWithManyProtocols()
        container.register(IService1.self) { _ in service }
        container.register(IService2.self) { _ in service }
        let service1: IService1 = container.singleton()
        let service2: IService2 = container.singleton()
        expect(service1) === service2
    }

    func test_извлекаются_разные_экземпляры_для_per_request() {
        let vm1: ViewModel = container.perRequest()
        let vm2: ViewModel = container.perRequest()
        expect(vm1) !== vm2
    }

    func test_аргументы_пробрасываются() {
        let vm: ViewModelWithArgs = container.perRequest(args: 42)
        expect(vm.args) == 42
    }

    func test_разрешается_singleton_зависимость_под_протоколом() {
        container.register(IService.self, as: Service.self)
        let vm1: ViewModelWithSingletonProtocolDependency = container.perRequest()
        let vm2: ViewModelWithSingletonProtocolDependency = container.perRequest()
        expect(vm1.service) === vm2.service
    }

    func test_разрешается_singleton_зависимость_без_протокола() {
        let vm1: ViewModelWithSingletonInstanceDependency = container.perRequest()
        let vm2: ViewModelWithSingletonInstanceDependency = container.perRequest()
        expect(vm1.service) === vm2.service
    }

    func test_разрешается_per_request_зависимость_с_аргументами() {
        let vm1: ViewModelWithPerRequestDependency = container.perRequest(args: 1)
        let vm2: ViewModelWithPerRequestDependency = container.perRequest(args: 2)
        expect(vm1.viewModel) !== vm2.viewModel
        expect(vm1.viewModel?.args) == 1
        expect(vm2.viewModel?.args) == 2
    }

    func test_нет_цикла_если_сервисы_держат_друг_друга_через_обертки_свойств() {
        var vm: ViewModelWithRetainCycle? = container.perRequest()
        let service1: Weak<ServiceWithRetainCycle1> = Weak(vm?.service1)
        let service2: Weak<ServiceWithRetainCycle2> = Weak(vm?.service2)
        vm?.service1.service.test()
        vm?.service2.service.test()
        vm = nil
        container.unregisterAll()
        expect(service1 == nil).to(beTrue())
        expect(service2 == nil).to(beTrue())
    }

    func test_переопределяет_регистрацию_на_основе_конструктора() {
        container.register(IService.self, as: Service1.self)
        container.replace(IService.self, as: Service2.self)
        let service: IService = container.singleton()
        expect(service).to(beAnInstanceOf(Service2.self))
    }

    func test_переопределяет_регистрацию_на_основе_фабрики() {
        container.register(IService.self) { _ in Service1() }
        container.replace(IService.self) { _ in Service2() }
        let service: IService = container.singleton()
        expect(service).to(beAnInstanceOf(Service2.self))
    }
}

// MARK: - Test Data

private protocol IService: AnyObject { }
private protocol IService1: AnyObject { }
private protocol IService2: AnyObject { }

private class Service: IService, ISingleton {
    required init() { }
}

private class Service1: IService, ISingleton {
    required init() { }
}

private class Service2: IService, ISingleton {
    required init() { }
}

private class ServiceWithManyProtocols: IService1, IService2 {}

private class ViewModel: IPerRequest {
    required init(args: Void) { }
}

private class ViewModelWithArgs: IPerRequest {
    let args: Int
    required init(args: Int) {
        self.args = args
    }
}

private class ViewModelWithSingletonProtocolDependency: IPerRequest {
    @Singleton var service: IService
    required init(args: Void) { }
}

private class ViewModelWithSingletonInstanceDependency: IPerRequest {
    @Singleton var service: Service
    required init(args: Void) { }
}

private class ViewModelWithPerRequestDependency: IPerRequest {
    @Singleton var factory: Factory<ViewModelWithArgs>
    var viewModel: ViewModelWithArgs?
    required init(args: Int) {
        self.viewModel = factory.perRequest(args: args)
    }
}

private class ServiceWithRetainCycle1: ISingleton {
    @Singleton var service: ServiceWithRetainCycle2
    required init() {}
    func test() {}
}

private class ServiceWithRetainCycle2: ISingleton {
    @Singleton var service: ServiceWithRetainCycle1
    required init() {}
    func test() {}
}

private class ViewModelWithRetainCycle: IPerRequest {
    @Singleton var service1: ServiceWithRetainCycle1
    @Singleton var service2: ServiceWithRetainCycle2
    required init(args: Void) {}
}
