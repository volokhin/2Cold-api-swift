import Foundation
import Vapor

class FreezerStorage {

    private let logger: Logger
    private let fileName = "Freezers.json"
    private var runtimeStorage: [FreezerStorable]?

    init(logger: Logger) {
        self.logger = logger
    }

    func storage(_ req: Request) -> EventLoopFuture<[FreezerStorable]> {
        if let storage = runtimeStorage {
            return req.eventLoop.makeSucceededFuture(storage)
        }
        return createStorageIfNeeded(req)
            .flatMap {
                return self.readDataFromStorage(req)
                    .map { storage in
                        self.runtimeStorage =  storage
                        return storage
                    }
            }
    }

    func edit(_ req: Request, floor: Int, freezer: Int, data: FreezerData) -> EventLoopFuture<Void> {
        return createStorageIfNeeded(req)
            .flatMap {
                return self.readDataFromStorage(req)
                    .flatMap { storage in
                        let index = storage.firstIndex { $0.floor == floor && $0.id == freezer }
                        if let index = index {
                            var storage = storage
                            storage[index] = storage[index].copy(with: data)
                            return self.writeDataToStorage(req, data: storage)
                                .map {
                                    self.runtimeStorage = storage
                                }
                        } else {
                            return req.eventLoop.makeFailedFuture(
                                Abort(.internalServerError, reason: "Unable to find freezer '\(freezer)' on floor '\(floor)'")
                            )
                        }
                    }
            }
    }

    private func createStorageIfNeeded(_ req: Request) -> EventLoopFuture<Void> {
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileName)
        if attributes == nil {
            logger.info("Create storage file '\(fileName)'")
            return writeDataToStorage(req, data: DefaultState.cache)
        } else {
            return req.eventLoop.makeSucceededFuture(())
        }
    }

    private func readDataFromStorage(_ req: Request) -> EventLoopFuture<[FreezerStorable]> {
        logger.info("Read data from storage file '\(fileName)'")
        var storage: [FreezerStorable]?
        return req.fileio.readFile(at: fileName) { buffer in
            let decoder = JSONDecoder()
            do {
                var buffer = buffer
                let data = buffer.readData(length: buffer.readableBytes) ?? Data()
                storage = try decoder.decode([FreezerStorable].self, from: data)
                return req.eventLoop.makeSucceededFuture(())
            } catch let error {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
        .map {
            return storage ?? DefaultState.cache
        }
    }

    private func writeDataToStorage(_ req: Request, data: [FreezerStorable]) -> EventLoopFuture<Void> {
        logger.info("Write data to storage file '\(fileName)'")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(data)
            return req.fileio.writeFile(ByteBuffer(bytes: data), at: fileName)
        } catch let error {
            logger.report(error: error)
            return req.eventLoop.makeFailedFuture(error)
        }
    }
}
