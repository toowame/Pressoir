import Foundation
import Testing

@testable import PressoirCore

@Suite("Politique de capture : apps exclues, jetons, tailles")
struct CapturePolicyTests {
    private let text = "public.utf8-plain-text"

    @Test(
        "Une copie faite dans un gestionnaire de mots de passe n'est jamais gardée",
        arguments: [
            "com.1password.1password", "com.bitwarden.desktop", "org.keepassxc.keepassxc",
            "com.apple.Passwords", "com.apple.keychainaccess",
        ])
    func excludedSourceApps(bundleId: String) {
        let result = PasteboardChangeFilter(lastChangeCount: 1)
            .evaluate(changeCount: 2, types: [text], sourceBundleId: bundleId)

        #expect(result.kind == nil)
        #expect(result.filter.lastChangeCount == 2)
    }

    @Test("Une copie depuis une app ordinaire reste capturée")
    func ordinaryAppCaptured() {
        let result = PasteboardChangeFilter(lastChangeCount: 1)
            .evaluate(changeCount: 2, types: [text], sourceBundleId: "com.apple.TextEdit")

        #expect(result.kind == .text)
    }

    @Test("Ce qui arrive d'un autre appareil Apple (presse-papier universel) est ignoré")
    func remoteClipboardIgnored() {
        let result = PasteboardChangeFilter(lastChangeCount: 1)
            .evaluate(changeCount: 2, types: [text, "com.apple.is-remote-clipboard"])

        #expect(result.kind == nil)
    }

    @Test("Ce que Pressoir remet lui-même dans le presse-papier n'est pas recapturé")
    func ownPasteIgnored() {
        let result = PasteboardChangeFilter(lastChangeCount: 1)
            .evaluate(changeCount: 2, types: [text, PasteboardChangeFilter.ownPasteType])

        #expect(result.kind == nil)
    }

    @Test(
        "Les jetons et clés reconnaissables ne sont pas gardés",
        arguments: [
            "ghp_" + String(repeating: "a", count: 36),
            "github_pat_11ABCDEFG0123456789_abcdefghijklmnopqrstuvwxyz",
            "AKIAIOSFODNN7EXAMPLE",
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NSJ9.c2lnbmF0dXJlLXN1cGVyLXNlY3JldGU",  // gitleaks:allow
            "xoxb-123456789012-abcdefghijkl",
            "sk-ant-api03-" + String(repeating: "x", count: 30),
            "sk-proj-" + String(repeating: "y", count: 30),
            "sk-" + String(repeating: "k", count: 48),
            "sk_live_" + String(repeating: "4", count: 24),
            "AIza" + String(repeating: "B", count: 35),
            "-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END OPENSSH PRIVATE KEY-----",
            "DATABASE_URL=x\nGITHUB_TOKEN=ghp_" + String(repeating: "Z", count: 36),
        ])
    func secretsDetected(secret: String) {
        #expect(SecretDetector.looksLikeSecret(secret))
    }

    @Test(
        "Un texte ordinaire n'est pas pris pour un secret",
        arguments: [
            "Bonjour, la réunion est décalée à 15 h.",
            "https://github.com/example/pressoir/pull/12",
            "skier en février",
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            "<div class=\"sk-loading-spinner-container-large\">",
            "mon_identifiant_tres_longghp_" + String(repeating: "a", count: 36),
            "configAIza" + String(repeating: "B", count: 35),
        ])
    func ordinaryTextKept(text: String) {
        #expect(!SecretDetector.looksLikeSecret(text))
    }

    @Test("ClipIntake écarte un jeton et un texte trop long")
    func intakeDropsSecretAndHugeText() throws {
        let intake = ClipIntake(imageStore: InMemoryImageStore())
        let token = "AKIAIOSFODNN7EXAMPLE"
        let huge = String(repeating: "a", count: ClipIntake.maxTextBytes + 1)

        let history = try intake.ingest(.text(token), into: ClipHistory(), at: Date())
        let after = try intake.ingest(.text(huge), into: history, at: Date())

        #expect(after.items.isEmpty)
    }

    @Test("Images : plafond d'octets bruts et de pixels, avant tout décodage")
    func imageLimits() {
        #expect(ImageLimits.accepts(rawBytes: 1_000, pixelWidth: 1920, pixelHeight: 1080))
        #expect(!ImageLimits.accepts(rawBytes: ImageLimits.maxRawBytes + 1, pixelWidth: 10, pixelHeight: 10))
        #expect(!ImageLimits.accepts(rawBytes: 1_000, pixelWidth: 30_000, pixelHeight: 30_000))
        #expect(!ImageLimits.accepts(rawBytes: 1_000, pixelWidth: Int.max, pixelHeight: 2))
        #expect(!ImageLimits.accepts(rawBytes: 1_000, pixelWidth: 0, pixelHeight: 10))
    }
}
