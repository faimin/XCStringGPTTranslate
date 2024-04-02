import Foundation

extension String: Identifiable {
    public var id: String {
        self
    }
}

public struct StringCatalog: Codable {
    public var sourceLanguage: String
    public var strings: [String: StringEntry]
    public var version: String // TODO: Use a Version type?
}

// MARK: - Init

public extension StringCatalog {
    init(contentsOf fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}
