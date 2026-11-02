# 0005. Security hardening: never overwrite, guarded paste, wider filters

- **Status:** Accepted. Complements [0002](0002-plain-text-and-sensitive-data.md) to
  [0004](0004-copied-images.md).
- **Date:** 2026-11-02

## Context

A security review on 2026-11-02 raised three high-severity points:

1. the whole history could be lost if the Keychain key went missing;
2. a paste could land in the wrong app;
3. password filtering relied only on apps that flag their copies.

## Decision

### 1. Never overwrite unreadable data (`VaultOpener`, at launch)

- A key is created only when no data exists, or after the existing data has been moved aside.
- Unreadable data (missing or different key): `history.enc` and `images/` are moved untouched to
  `quarantaine-<date>/`, and the menu says so.
- Keychain not answering: the app runs without saving, in memory only. Nothing on disk is read or
  written.
- The key is read once at launch, not on every copy.

### 2. Guarded paste (`PasteGuard`)

- <kbd>⌘V</kbd> is sent only if the app in front is the one that was in front when the panel
  opened, and never into a password field (`AXSecureTextField`).
- The event uses a private event source, so a <kbd>⇧</kbd> still held down does not turn
  <kbd>⌘V</kbd> into <kbd>⇧⌘V</kbd>.

### 3. Capture filters

On top of the nspasteboard.org markers, Pressoir never keeps:

- copies made while a known password manager is in front: 1Password, Bitwarden, KeePassXC,
  Passwords, Keychain Access, Dashlane, Enpass;
- Universal Clipboard content (from another Apple device);
- recognisable tokens: GitHub, AWS, JWT, Slack, Anthropic and OpenAI, Stripe, Google, private keys;
- text over 1 MB.

What Pressoir pastes carries a private type, so it is not captured again.

### 4. Images

Raw size (≤ 50 MB) and pixel count (≤ 64 Mpx) are checked on the header before any decoding.
Thumbnails come from ImageIO without decoding the full image.

### 5. Disk and log

`umask 077`, folders 0700, log 0600 rotated at 1 MB. Errors are logged as `domain#code`, never with a
value. The data folder is excluded from Time Machine. The panel is hidden from screenshots and screen
sharing.

### 6. Supply chain

Hardened runtime signature; GitHub Actions pinned by SHA, read-only CI token, Dependabot; gitleaks
also runs in the pre-commit hook.

### 7. Key accessibility

New keys are created as `WhenUnlockedThisDeviceOnly`. An existing key keeps its original attribute.

### 8. Plaintext migration removed

The `history.json` migration from [0003](0003-encrypted-history.md) only ever applied to one Mac. It
bypassed the vault and could overwrite an encrypted history if an old file came back. A leftover
`history.json` is now ignored.

### 9. Responsiveness

Accessibility calls time out after 0.2 s. Images are decoded off the main thread.

## Accepted limits

- **Unknown focused field → paste anyway.** When an app does not expose its accessibility tree (some
  Electron or Java apps), the guard cannot tell whether the field is a password field. Blocking would
  break pasting in Teams, Slack or VS Code. The target app is still checked. This can be flipped in
  `PasteGuard` if usage allows.
- **The source app is read when polling**, up to 0.5 s after the copy. A copy in a password manager
  followed at once by <kbd>⌘⇥</kbd> may be attributed to the other app, and a browser extension copies
  "from the browser". The app filter adds to the nspasteboard.org markers; it does not replace them.
- Two instances launched together would write the same file. Only one is expected (menu-bar agent,
  launched at login).

## Rejected

- **Keychain "Data Protection":** requires a stable Apple signing identity, not ad-hoc signing.
- **Associated data binding each image file to its id:** would change the format and make existing
  files unreadable, for a low local risk (swapping two files).
- **"Random-looking string" heuristic:** too many false positives (hashes, ids, URLs).
- **Restoring the previous clipboard after pasting:** surprising for the user.
- **Automatic expiry of unpinned entries:** left as a possible future option.

## Consequences

- ✅ A lost key or a refused access no longer destroys anything.
- ⚠️ With ad-hoc signing, every rebuild asks again for Keychain access and Accessibility.
- ⚠️ A password copied from an unknown app without a marker is still captured: <kbd>⌘⌫</kbd> or clear
  the history.
