import Foundation
import Vapor

struct Freezer: Content {
    let toggleCommandId: Int
    let id: Int
    let floor: Int
    let place: String
    let name: String
    let isEnabled: Bool
}
