# Architecture decisions

Each record explains one decision: the context, what was chosen, and what it costs. Records are not
rewritten when a decision changes; a newer record supersedes the relevant part and says so.

| #                                          | Decision                                                       | Status                          |
| ------------------------------------------ | -------------------------------------------------------------- | ------------------------------- |
| [0001](0001-native-swift-app.md)           | Native Swift app built with SwiftPM, no Xcode project           | Accepted                        |
| [0002](0002-plain-text-and-sensitive-data.md) | Plain text only, password-manager copies skipped               | Partly superseded by 0003, 0004 |
| [0003](0003-encrypted-history.md)          | History encrypted with AES-256-GCM, key in the Keychain         | Accepted                        |
| [0004](0004-copied-images.md)              | Copied images, one sealed file per image                        | Accepted                        |
| [0005](0005-security-hardening.md)         | Security hardening: never overwrite, guarded paste, wider filters | Accepted                        |
| [0006](0006-open-source-release.md)        | Open-source release under a neutral identifier                  | Accepted                        |
| [0007](0007-shortcut-and-languages.md)     | Configurable shortcut and interface languages                   | Accepted                        |

The records were first written in French and translated when the repository went public.
