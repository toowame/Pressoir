# 0001. Native Swift app built with SwiftPM, no Xcode project

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

Pressoir is a clipboard history in the spirit of Windows' Win + V: a global shortcut opens the latest
copies under the mouse, you pick one, and it is pasted into the app in front. That needs a global
shortcut, a floating panel that does not steal focus, access to the pasteboard and a synthetic
<kbd>⌘V</kbd>.

## Decision

- Swift 6 (language mode 6, strict concurrency): AppKit for the system side, SwiftUI for the panel.
- A SwiftPM package with no `.xcodeproj`; `Scripts/build-app.sh` assembles the `.app`.
- Two targets: `PressoirCore`, the pure domain with no AppKit, unit-tested with at least 80 % coverage;
  and `PressoirApp`, the system adapters and UI, covered by the [manual test plan](../TESTING.md).
- The global shortcut uses Carbon's `RegisterEventHotKey`, which needs no permission.
- Pasting posts a <kbd>⌘V</kbd> `CGEvent`, which needs the Accessibility permission. Without it the
  entry is still copied and the user pastes by hand.
- No third-party dependency.

## Consequences

- ✅ Small and instant: no runtime to load, one universal binary for arm64 and x86_64.
- ✅ The domain is tested without a screen or a real pasteboard.
- ⚠️ Ad-hoc signing ties permissions to each build, so macOS may ask for Accessibility again after a
  rebuild. A Developer ID signature would fix it.
- ⚠️ macOS sends no "clipboard changed" notification, so the pasteboard is polled every 0.5 s.
