import Foundation

struct DefaultState {
    static let cache =
        [
            // 8 этаж
            FreezerStorable(id: 2, floor: 8, name: "Александр Вадимович", place: "D&R", toggleCommandId: 0),
            FreezerStorable(id: 3, floor: 8, name: "Кирилл", place: "D&R", toggleCommandId: 6),
            FreezerStorable(id: 4, floor: 8, name: "Светлана", place: "Кухня", toggleCommandId: 12),
            FreezerStorable(id: 5, floor: 8, name: "Оксана", place: "HR", toggleCommandId: 18),
            FreezerStorable(id: 6, floor: 8, name: "Камчатка", place: "Камчатка", toggleCommandId: 24),
            FreezerStorable(id: 7, floor: 8, name: "Данил", place: "Core", toggleCommandId: 30),
            FreezerStorable(id: 8, floor: 8, name: "Artöm", place: "CoreNavi", toggleCommandId: 36),
            FreezerStorable(id: 9, floor: 8, name: "Юля", place: "Support", toggleCommandId: 42),
            FreezerStorable(id: 10, floor: 8, name: "Даша", place: "iOS", toggleCommandId: 48),
            FreezerStorable(id: 11, floor: 8, name: "Маша", place: "iOS", toggleCommandId: 54),
            FreezerStorable(id: 12, floor: 8, name: "Вадим", place: "iOS", toggleCommandId: 60),
            FreezerStorable(id: 13, floor: 8, name: "Руслан", place: "Android", toggleCommandId: 66),
            FreezerStorable(id: 14, floor: 8, name: "Сергей", place: "Android", toggleCommandId: 72),
            FreezerStorable(id: 15, floor: 8, name: "Мария", place: "Reception", toggleCommandId: 78),
            // 5 этаж
            FreezerStorable(id: 10, floor: 5, name: "Юра", place: "Unix", toggleCommandId: 48),
            FreezerStorable(id: 11, floor: 5, name: "Евгений", place: "Кухня", toggleCommandId: 54),
            FreezerStorable(id: 12, floor: 5, name: "Анатолий", place: "Карта", toggleCommandId: 60),
            FreezerStorable(id: 14, floor: 5, name: "Стёпа", place: "Карта", toggleCommandId: 72),
        ]
}
