import Foundation

// Сервис пользователей
public struct User: Codable, Identifiable, Hashable {
    public let id: Int
    public var name: String
    private(set) var age: Int = 0

    public var isAdult: Bool { age >= 18 }
}

public final class UserService: @unchecked Sendable {
    private var cache: [Int: User] = [:]
    static let shared = UserService()

    public func find(_ id: Int) async throws -> User? {
        guard id > 0 else { throw ServiceError.invalidId(id) }
        if let cached = cache[id] { return cached }
        defer { print("done \(id)") }
        return try await withCheckedThrowingContinuation { cont in
            cont.resume(returning: cache[id])
        }
    }
}

public enum ServiceError: Error, CustomStringConvertible {
    case invalidId(Int)
    case notFound(String)

    public var description: String {
        switch self {
        case .invalidId(let id): return "bad id: \(id)"
        case .notFound(let what): return "не найдено \(what)"
        }
    }
}

@main struct App {
    static func main() async throws {
        let svc = UserService.shared
        let users = try await svc.find(1).map { [$0] } ?? []
        let nums = [1, 2, 3].filter { $0.isMultiple(of: 2) }
        let label = #"raw "path" \#n"#
        print(users, nums, 0x1F, 1_000, 3.14, label)
        for try await u in (0..<3).map({ User(id: $0, name: "u\($0)") }) { print(u) }
    }
}
