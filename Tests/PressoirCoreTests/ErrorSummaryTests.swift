import Foundation
import Testing

@testable import PressoirCore

@Suite("Résumé d'erreur sans contenu, pour le journal")
struct ErrorSummaryTests {
    @Test("Une erreur de décodage ne laisse jamais passer la valeur fautive")
    func decodingErrorHidesValue() {
        let json = Data(#"{"montant":"MOT-DE-PASSE-SECRET"}"#.utf8)
        do {
            _ = try JSONDecoder().decode([String: Int].self, from: json)
            Issue.record("le décodage aurait dû échouer")
        } catch {
            let summary = ErrorSummary.of(error)
            #expect(!summary.contains("SECRET"))
            #expect(!summary.isEmpty)
        }
    }

    @Test("Une erreur système garde domaine et code")
    func nsErrorKeepsDomainAndCode() {
        let error = NSError(domain: NSCocoaErrorDomain, code: 513, userInfo: [NSFilePathErrorKey: "/secret/path"])

        #expect(ErrorSummary.of(error) == "NSCocoaErrorDomain#513")
    }
}
