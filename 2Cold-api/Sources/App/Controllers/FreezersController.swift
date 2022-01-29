import Foundation
import AppFoundation
import Vapor

class FreezersController: RouteCollection {

    @Singleton private var freezersService: FreezersService

    func boot(routes: RoutesBuilder) throws {
        routes.get("api", "ac", "list", ":floor") { request -> EventLoopFuture<[Freezer]> in
            guard let floor = Int(request.parameters.get("floor") ?? "") else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest))
            }
            guard floor == 5 || floor == 8 else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Unexpected floor '\(floor)'"))
            }
            return try self.list(request, floor: floor)
        }

        routes.post("api", "ac", "enable", ":floor", ":freezer") { request -> EventLoopFuture<[Freezer]> in
            guard let floor = Int(request.parameters.get("floor") ?? ""),
                  let freezer = Int(request.parameters.get("freezer") ?? "") else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest))
            }
            guard floor == 5 || floor == 8 else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Unexpected floor '\(floor)'"))
            }
            return try self.enable(request, floor: floor, freezer: freezer)
        }

        routes.post("api", "ac", "disable", ":floor", ":freezer") { request -> EventLoopFuture<[Freezer]> in
            guard let floor = Int(request.parameters.get("floor") ?? ""),
                  let freezer = Int(request.parameters.get("freezer") ?? "") else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest))
            }
            guard floor == 5 || floor == 8 else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Unexpected floor '\(floor)'"))
            }
            return try self.disable(request, floor: floor, freezer: freezer)
        }

        routes.post("api", "ac", "toggle", ":floor", ":freezer") { request -> EventLoopFuture<[Freezer]> in
            guard let floor = Int(request.parameters.get("floor") ?? ""),
                  let freezer = Int(request.parameters.get("freezer") ?? "") else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest))
            }
            guard floor == 5 || floor == 8 else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Unexpected floor '\(floor)'"))
            }
            return try self.toggle(request, floor: floor, freezer: freezer)
        }

        routes.patch("api", "ac", "edit", ":floor", ":freezer") { request -> EventLoopFuture<EmptyContent> in
            guard let floor = Int(request.parameters.get("floor") ?? ""),
                  let freezer = Int(request.parameters.get("freezer") ?? "") else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest))
            }
            guard floor == 5 || floor == 8 else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Unexpected floor '\(floor)'"))
            }
            let data = try request.content.decode(FreezerData.self)
            return try self.edit(request, floor: floor, freezer: freezer, data: data)
                .map { EmptyContent() }
        }
    }

    func list(_ req: Request, floor: Int) throws -> EventLoopFuture<[Freezer]> {
        return freezersService.list(req, floor: floor)
    }

    func enable(_ req: Request, floor: Int, freezer: Int) throws -> EventLoopFuture<[Freezer]> {
        return freezersService.enable(req, floor: floor, freezer: freezer)
    }

    func disable(_ req: Request, floor: Int, freezer: Int) throws -> EventLoopFuture<[Freezer]> {
        return freezersService.disable(req, floor: floor, freezer: freezer)
    }

    func toggle(_ req: Request, floor: Int, freezer: Int) throws -> EventLoopFuture<[Freezer]> {
        return freezersService.toggle(req, floor: floor, freezer: freezer)
    }

    func edit(_ req: Request, floor: Int, freezer: Int, data: FreezerData) throws -> EventLoopFuture<Void> {
        if data.name.isEmpty {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Name cannot be empty"))
        }
        if data.place.isEmpty {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Place cannot be empty"))
        }
        if data.name.count > 32 {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Name is longer than 32 symbols"))
        }
        if data.place.count > 32 {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Place is longer than 32 symbols"))
        }
        return freezersService.edit(req, floor: floor, freezer: freezer, data: data)
    }
}
