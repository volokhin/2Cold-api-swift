import Foundation

/// Обертка вокруг экземпляра ссылочного типа. Экземпляр хранится по слабой ссылке.
public struct Weak<T: AnyObject> {

    public private(set) weak var value: T?

    public init(_ value: T?) {
        self.value = value
    }

    public static func == (lhs: Weak<T>, rhs: _OptionalNilComparisonType) -> Bool {
        return lhs.value == nil
    }

    public static func != (lhs: Weak<T>, rhs: _OptionalNilComparisonType) -> Bool {
        return lhs.value != nil
    }
}
