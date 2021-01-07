import Foundation

struct FreezerStorable: Codable {
    let id: Int
    let floor: Int
    let place: String
    let name: String
    let toggleCommandId: Int

    init(id: Int,
         floor: Int,
         name: String,
         place: String,
         toggleCommandId: Int
    ) {
        self.id = id
        self.floor = floor
        self.name = name
        self.place = place
        self.toggleCommandId = toggleCommandId
    }
}

// MARK: - Extensions

extension FreezerStorable {

    func makeFreezer(isEnabled: Bool) -> Freezer {
        return Freezer(
            toggleCommandId: self.toggleCommandId,
            id: self.id,
            floor: self.floor,
            place: self.place,
            name: self.name,
            isEnabled: isEnabled
        )
    }

    func copy(with data: FreezerData) -> FreezerStorable {
        return FreezerStorable(
            id: self.id,
            floor: self.floor,
            name: data.name,
            place: data.place,
            toggleCommandId: self.toggleCommandId
        )
    }
}
