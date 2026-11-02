import Foundation
import Testing

@testable import PressoirCore

@Suite("Images en mémoire (Trousseau indisponible)")
struct MemoryImageStoreTests {
    @Test("Garder, relire, puis oublier ce qui ne sert plus")
    func savesLoadsAndPrunes() throws {
        let store = MemoryImageStore()
        let kept = UUID()
        let dropped = UUID()
        try store.save(Data([1]), as: kept)
        try store.save(Data([2]), as: dropped)

        try store.retainOnly([kept])

        #expect(try store.load(kept) == Data([1]))
        #expect(throws: HistoryStoreError.self) { try store.load(dropped) }
    }
}
