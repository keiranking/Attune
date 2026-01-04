import Foundation

protocol Storable {
    func data(forKey key: String) -> Data?
    func set(_ value: Any?, forKey key: String)
}
