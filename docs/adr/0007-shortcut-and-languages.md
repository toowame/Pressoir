# 0007. Configurable shortcut and interface languages

- **Status:** Accepted
- **Date:** 2026-11-02

## Context

<kbd>⇧⌘V</kbd> clashes with "Paste and Match Style" in some apps, and the interface was French only
while the project is published for everyone.

## Decision

### Shortcut

- The rules live in the domain (`Shortcut`, tested): at least ⌘, ⌃ or ⌥; combinations that belong to
  macOS and every app are refused (⌘ alone with A, C, V, X, Z, Q, W, H, M, Tab or Space; ⇧⌘3/4/5/6;
  ⇧⌘Q; ⌃Space and ⌃⌥Space). macOS can accept registering some of these and never deliver them.
- The key is stored by its layout-independent key code, with the label it printed when recorded,
  since the same key shows a different letter on AZERTY and QWERTY. Special keys (arrows, F1–F20,
  Space…) have fixed names (`KeyName`).
- The choice is kept in the app's user defaults. It is not a secret, and it is validated again when
  read back: a damaged value falls back to <kbd>⇧⌘V</kbd>.
- While the recorder window is open, the current shortcut is suspended so it can be recorded again.
  If macOS refuses the new one (already taken by another app), the previous one is registered again
  and the window says why.

### Languages

- Interface texts live in `Resources/Localization/<language>.lproj/Localizable.strings` (English and
  French), copied into the app bundle; macOS picks the language, English being the fallback.
- A test checks that every language has the same keys and the same format placeholders.

## Consequences

- ✅ The shortcut can be moved away from a clash without editing anything by hand.
- ✅ The app speaks the language of the system, and a new language is one folder.
- ⚠️ The default label "V" is written for QWERTY and AZERTY; on another layout it may not match the
  key until the user records their own shortcut.
- ⚠️ A combination intercepted by another tool after Pressoir registered it is not detected.
