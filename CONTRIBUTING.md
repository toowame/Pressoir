# Contributing

Thanks for helping. Bug reports, ideas, translations and pull requests are all welcome.

## Report a bug or suggest a feature

[Open an issue](https://github.com/toowame/Pressoir/issues) with your macOS version, the Pressoir
version (the name of the DMG you installed) and the steps to reproduce. The log at
`~/Library/Logs/Pressoir.log` never contains what you copied, so you can attach it.

Security problems go through [SECURITY.md](SECURITY.md), not public issues.

## Set up

Requirements: macOS 14+, Xcode 16+ (Swift 6).

```bash
git clone https://github.com/toowame/Pressoir.git
cd Pressoir
brew install lefthook gitleaks && lefthook install
swift test
Scripts/build-app.sh release native && open Pressoir.app
```

The hooks run the same checks as the CI: format, build with warnings as errors and secret scan before
each commit; tests and the 80 % coverage gate before each push.

## Where things go

- `Sources/PressoirCore`: domain logic, no AppKit. Anything with a rule or a decision lives here and
  is written test first, with [Swift Testing](https://developer.apple.com/documentation/testing).
- `Sources/PressoirApp`: thin adapters for the pasteboard, Keychain, shortcut, menu bar and panel.
  These are checked with the [manual test plan](docs/TESTING.md).
- A choice that changes behaviour, storage or security gets a short record in [`docs/adr/`](docs/adr).

## Pull requests

- One topic per pull request, based on `dev`.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`…).
- Run `swift format lint --strict -r Sources Tests` and `swift test` before pushing.
- Describe what you checked by hand when the change touches the app side.
