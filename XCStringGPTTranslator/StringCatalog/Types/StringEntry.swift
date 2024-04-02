import CodableWrapper
import Foundation

@Codable
public struct StringEntry: Codable {
    public var comment: String?
    public var extractionState: StringExtractionState?
    public var localizations: [String: StringLocalization] = [:]
}
