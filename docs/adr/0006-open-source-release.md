# 0006. Open-source release under a neutral identifier

- **Status:** Accepted
- **Date:** 2026-11-02

## Context

The repository goes public under the MIT license, with a downloadable DMG.

## Decision

- A neutral identifier, `io.github.toowame.Pressoir`, is used for the bundle, the Keychain service
  and the private pasteboard type, in place of an identifier that carried a person's name.
- The key created under the earlier identifier is found by its account and label
  (`history-encryption-key`, "Pressoir — clé de l'historique"), copied under the new service, and the
  old entry is deleted only once the copy exists. Existing histories stay readable, and the earlier
  identifier does not appear in the code.
- The git history was rewritten before publication to remove personal mentions. A backup of the
  earlier state is kept outside the repository. This is why [0003](0003-encrypted-history.md) already
  names the new identifier.
- Release builds rewrite source paths and strip debug symbols, so the binary does not carry the
  builder's home folder; `Scripts/build-app.sh` fails if it still does.
- The README exists in English and French. The panel is illustrated with SVG, since the real panel is
  deliberately hidden from screenshots ([0005](0005-security-hardening.md)).
- The icon is drawn in code (`Scripts/make-icon.swift`): reproducible, with no design tool.
- The DMG is published as a GitHub Release, ad-hoc signed and not notarized; the README explains how
  to open it.

## Consequences

- ✅ No personal name in the published code, documentation, history or binary.
- ⚠️ Changing the identifier asks again for Accessibility and Keychain access.
- ⚠️ Without notarization, macOS blocks the first launch (workaround documented).
