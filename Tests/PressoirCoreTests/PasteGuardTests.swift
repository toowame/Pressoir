import Testing

@testable import PressoirCore

@Suite("Garde du collage automatique")
struct PasteGuardTests {
    @Test("Même app au premier plan, champ ordinaire : on colle")
    func pastesIntoSameApp() {
        #expect(PasteGuard.decide(expectedPid: 42, currentPid: 42, focusedRole: "AXTextArea") == .paste)
    }

    @Test("Rôle inconnu (app non accessible) dans la même app : on colle")
    func pastesWhenRoleUnknown() {
        #expect(PasteGuard.decide(expectedPid: 42, currentPid: 42, focusedRole: nil) == .paste)
    }

    @Test("Une autre app a pris la main entre-temps : on ne colle pas")
    func skipsWhenTargetChanged() {
        #expect(PasteGuard.decide(expectedPid: 42, currentPid: 7, focusedRole: nil) == .skip(.targetChanged))
    }

    @Test("Aucune app connue à l'ouverture : on ne colle pas")
    func skipsWithoutTarget() {
        #expect(PasteGuard.decide(expectedPid: nil, currentPid: 7, focusedRole: nil) == .skip(.noTarget))
        #expect(PasteGuard.decide(expectedPid: 42, currentPid: nil, focusedRole: nil) == .skip(.noTarget))
    }

    @Test("Champ mot de passe focalisé : on ne colle jamais")
    func skipsSecureField() {
        #expect(
            PasteGuard.decide(expectedPid: 42, currentPid: 42, focusedRole: "AXSecureTextField")
                == .skip(.secureField))
    }
}
