import Foundation
import AppFoundation
import Vapor
import SwiftSoup
import NIO

class FreezersService: ISingleton {

    private let sessionIdKey = "ASP.NET_SessionId"
    private let serviceUrl = URL(string: "http://91.192.175.234/screenmate/ScreenMatePage.aspx")!
    private let loginUrl = URL(string: "http://91.192.175.234/screenmate/LoginPage.aspx")!
    private var sessionCookie: HTTPCookie?

    @Singleton private var parserService: HtmlParserService
    @Singleton private var storage: FreezerStorage

    required init() {}

    func list(_ req: Request, floor: Int) -> EventLoopFuture<[Freezer]> {
        req.logger.info("Get freezers list on floor '\(floor)'")
        return gotoFreezersInfoPage(req, floor: floor)
            .flatMap { doc in
                return self.storage.storage(req)
                    .map { self.parserService.extractFreezers(doc, floor: floor, storage: $0) }
            }
    }

    func enable(_ req: Request, floor: Int, freezer: Int) -> EventLoopFuture<[Freezer]> {
        req.logger.info("Enable freezer '\(freezer)' on floor '\(floor)'")
        return setEnabledState(req, floor: floor, freezer: freezer, isEnabled: true)
    }

    func disable(_ req: Request, floor: Int, freezer: Int) -> EventLoopFuture<[Freezer]> {
        req.logger.info("Disable freezer '\(freezer)' on floor '\(floor)'")
        return setEnabledState(req, floor: floor, freezer: freezer, isEnabled: false)
    }

    func toggle(_ req: Request, floor: Int, freezer: Int) -> EventLoopFuture<[Freezer]> {
        req.logger.info("Toggle freezer '\(freezer)' on floor '\(floor)'")
        return gotoFreezersInfoPage(req, floor: floor)
            .flatMap { doc in
                return self.storage.storage(req)
                    .flatMap { storage in
                        let state = self.parserService.extractState(doc)
                        let freezers = self.parserService.extractFreezers(doc, floor: floor, storage: storage)
                        let freezerObject = freezers.first { $0.floor == floor && $0.id == freezer }
                        if let freezerObject = freezerObject {
                            if freezerObject.isEnabled {
                                req.logger.info("Freezer '\(freezer)' is enabled. Disable it")
                                return self.disable(req, freezer: freezerObject, state: state)
                            } else {
                                req.logger.info("Freezer '\(freezer)' is disabled. Enable it")
                                return self.enable(req, freezer: freezerObject, state: state)
                            }
                        } else {
                            return req.eventLoop.makeFailedFuture(
                                Abort(.internalServerError, reason: "Unable to find freezer '\(freezer)' on floor '\(floor)'")
                            )
                        }
                    }
            }
            .flatMap { doc in
                return self.storage.storage(req)
                    .map { self.parserService.extractFreezers(doc, floor: floor, storage: $0) }
            }
    }

    func edit(_ req: Request, floor: Int, freezer: Int, data: FreezerData) -> EventLoopFuture<Void> {
        req.logger.info("Edit freezer '\(freezer)' on floor '\(floor)'")
        return storage.edit(req, floor: floor, freezer: freezer, data: data)
    }

    private func setEnabledState(_ req: Request, floor: Int, freezer: Int, isEnabled: Bool) -> EventLoopFuture<[Freezer]> {
        return gotoFreezersInfoPage(req, floor: floor)
            .flatMap { doc in
                return self.storage.storage(req)
                    .flatMap { storage in
                        let state = self.parserService.extractState(doc)
                        let freezers = self.parserService.extractFreezers(doc, floor: floor, storage: storage)
                        let freezerObject = freezers.first { $0.floor == floor && $0.id == freezer }
                        if let freezerObject = freezerObject {
                            if isEnabled {
                                return self.enable(req, freezer: freezerObject, state: state)
                            } else {
                                return self.disable(req, freezer: freezerObject, state: state)
                            }
                        } else {
                            return req.eventLoop.makeFailedFuture(
                                Abort(.internalServerError, reason: "Unable to find freezer '\(freezer)' on floor '\(floor)'")
                            )
                        }
                    }
            }
            .flatMap { doc in
                return self.storage.storage(req)
                    .map { self.parserService.extractFreezers(doc, floor: floor, storage: $0) }
            }
    }

    private func gotoFreezersInfoPage(_ req: Request, floor: Int) -> EventLoopFuture<Document> {
        req.logger.info("Go to freezers info page")
        return get(url: serviceUrl, req: req)
            .flatMap { doc in
                let pageType = self.parserService.pageType(doc)
                let state = self.parserService.extractState(doc)
                req.logger.info("Page type is '\(pageType.rawValue)'")
                switch pageType {
                case .freezersInfo:
                    let currentFloor = self.parserService.floor(doc)
                    if currentFloor == floor {
                        req.logger.info("Current floor is '\(currentFloor ?? 0)'. This is correct")
                        return req.eventLoop.makeSucceededFuture(doc)
                    } else {
                        req.logger.info("Current floor is '\(currentFloor ?? 0)'")
                        req.logger.info("Change floor to '\(floor)'")
                        return self.selectRoom(req, floor: floor, state: state)
                    }
                case .login:
                    req.logger.info("Perform login")
                    return self.login(req, state: state)
                        .flatMap { doc in
                            let state = self.parserService.extractState(doc)
                            req.logger.info("Select floor \(floor)")
                            return self.selectRoom(req, floor: floor, state: state)
                        }
                case .roomSelection, .unknown:
                    return req.eventLoop.makeFailedFuture(
                        Abort(.internalServerError, reason: "Unexpected http page '\(pageType.rawValue)'")
                    )
                }
            }
    }

    private func login(_ req: Request, state: ASPNetState) -> EventLoopFuture<Document> {
        let args = [
            "userName": "8floor",
            "password": "cit4278",
            "userType": "VISTA_USER",
            "loginButton": "Login",
            "__EVENTVALIDATION": state.eventValidation,
            "__VIEWSTATE": state.viewState,
        ]
        return post(url: loginUrl, req: req, args: args)
            .flatMap { doc in
                let pageType = self.parserService.pageType(doc)
                switch pageType {
                case .roomSelection:
                    let session = HTTPCookieStorage.shared.cookies?.first { $0.name == self.sessionIdKey }
                    self.sessionCookie = session
                    return req.eventLoop.makeSucceededFuture(doc)
                case .freezersInfo, .login, .unknown:
                    return req.eventLoop.makeFailedFuture(
                        Abort(.internalServerError, reason: "Unexpected http page '\(pageType.rawValue)'")
                    )
                }
            }
    }

    private func selectRoom(_ req: Request, floor: Int, state: ASPNetState) -> EventLoopFuture<Document> {
        guard floor == 5 || floor == 8 else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Unexpected floor '\(floor)'"))
        }
        let args = [
            "roomId": floor == 5 ? Constants.room5Floor : Constants.room8Floor,
            "__EVENTTARGET": "lookUpRoomId",
            "__EVENTVALIDATION": state.eventValidation,
            "__VIEWSTATE": state.viewState,
        ]
        return post(url: serviceUrl, req: req, args: args)
    }

    private func enable(_ req: Request, freezer: Freezer, state: ASPNetState) -> EventLoopFuture<Document> {
        let args = [
            "roomId": freezer.floor == 5 ? Constants.room5Floor : Constants.room8Floor,
            "__EVENTTARGET": "dataList:_ctl\(freezer.toggleCommandId):next",
            "__EVENTVALIDATION": state.eventValidation,
            "__VIEWSTATE": state.viewState,
        ]
        return post(url: serviceUrl, req: req, args: args)
    }

    private func disable(_ req: Request, freezer: Freezer, state: ASPNetState) -> EventLoopFuture<Document> {
        let args = [
            "roomId": freezer.floor == 5 ? Constants.room5Floor : Constants.room8Floor,
            "__EVENTTARGET": "dataList:_ctl\(freezer.toggleCommandId):previous",
            "__EVENTVALIDATION": state.eventValidation,
            "__VIEWSTATE": state.viewState,
        ]
        return post(url: serviceUrl, req: req, args: args)
    }

    private func get(url: URL, req: Request) -> EventLoopFuture<Document> {
        return execute(url: url, req: req, args: [:], httpMethod: "GET")
    }

    private func post(url: URL, req: Request, args: [String: String]) -> EventLoopFuture<Document> {
        return execute(url: url, req: req, args: args, httpMethod: "POST")
    }

    private func execute(url: URL, req: Request, args: [String: String], httpMethod: String) -> EventLoopFuture<Document> {
        req.logger.info("\(httpMethod) \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        request.httpBody = !args.isEmpty ? args.httpBody() : nil
        if let cookie = sessionCookie {
            request.httpShouldHandleCookies = true
            request.setValue("\(cookie.name)=\(cookie.value)", forHTTPHeaderField: "Cookie")
        }
        let promise = req.eventLoop.makePromise(of: Document.self)
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let data = data {
                let html = String(data: data, encoding: .utf8)
                do {
                    let doc = try SwiftSoup.parse(html ?? "")
                    promise.succeed(doc)
                } catch let error {
                    req.logger.report(error: error)
                    promise.fail(error)
                }
            } else if let error = error {
                req.logger.report(error: error)
                promise.fail(error)
            } else {
                promise.fail(Abort(.internalServerError, reason: "Unexpected error"))
            }
        }
        .resume()
        return promise.futureResult
    }
}

// MARK: - Dictionary

private extension Dictionary where Key == String, Value == String {
    func httpBody() -> Data {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "?&=[];+")
        let string = self.reduce(into: "") { result, item in
            let prefix = result.isEmpty ? "" : "&"
            let key = item.key
            let value = item.value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
            result = result + "\(prefix)\(key)=\(value)"
        }
        return string.data(using: .utf8) ?? Data()
    }
}
