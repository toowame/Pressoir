# Changelog

All notable changes to Pressoir. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-11-02

First stable release: the storage format, the settings and the menu are not expected to change in a
breaking way from here.

### Added

- Configurable shortcut: menu → **Shortcut…**, press the new combination. Combinations that belong
  to macOS are refused, and a shortcut already taken by another app keeps the previous one.
- English interface. The app follows the language of macOS (English or French).
- Social preview image for the repository.

### Changed

- CI actions updated to their Node 24 versions (`actions/checkout` v7, `gitleaks-action` v3).

## [0.2.1] - 2026-11-02

### Changed

- Documentation rewritten in English: architecture decisions with an index, manual test plan,
  contributing guide and this changelog.

### Fixed

- Release builds no longer embed the builder's home folder path; the build fails if they do.

## [0.2.0] - 2026-11-02

First public release.

### Added

- Copied images and screenshots: thumbnails in the panel, pasted back as images, one sealed file per
  image.
- App icon.
- Never recorded: copies made in known password managers, Universal Clipboard content, recognisable
  tokens (GitHub, AWS, Slack, Stripe, Google, OpenAI, Anthropic, JWT, private keys), text over 1 MB.
- README in English and French, MIT license, security policy.

### Changed

- New app identifier `io.github.toowame.Pressoir`. The existing encryption key is picked up
  automatically; macOS asks once again for Keychain and Accessibility access.
- Pasting goes only to the app that was in front when the panel opened, and never into a password
  field.

### Security

- Unreadable data is moved aside to `quarantaine-<date>/`, never overwritten. If the Keychain does
  not answer, nothing is written to disk.
- Private folders and log, log rotation, data excluded from Time Machine, panel hidden from screen
  sharing.

## [0.1.0] - 2026-10-23

### Added

- Clipboard history opened with <kbd>⇧⌘V</kbd> under the mouse, on every display.
- Search (case and accent insensitive), pins, <kbd>⌘1</kbd>…<kbd>⌘9</kbd>, delete, automatic paste.
- History encrypted with AES-256-GCM, key in the Keychain.
- Menu bar item with **Launch at login** and **Clear history**.

[1.0.0]: https://github.com/toowame/Pressoir/compare/v0.2.1...v1.0.0
[0.2.1]: https://github.com/toowame/Pressoir/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/toowame/Pressoir/releases/tag/v0.2.0
[0.1.0]: https://github.com/toowame/Pressoir/blob/main/CHANGELOG.md#010---2026-10-23
