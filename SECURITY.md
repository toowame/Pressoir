# Security policy

Pressoir sees everything you copy, so security reports are taken seriously.

## Reporting a vulnerability

Please do not open a public issue. Use
[GitHub private vulnerability reporting](https://github.com/toowame/Pressoir/security/advisories/new)
and include the Pressoir version, your macOS version, the steps to reproduce and what you observed.

You will get an answer within a week. Fixes ship in a new release, with credit if you want it.

## Supported versions

Only the latest release receives fixes.

## Scope

In scope: anything that exposes clipboard content (on disk, in logs, to other apps or users), weakens
the encryption or the Keychain key, records content Pressoir claims to skip, or pastes into an app
other than the one in front when the panel opened.

The design and its known limits are described in [`docs/adr/`](docs/adr), notably
[0003](docs/adr/0003-historique-chiffre.md) and [0005](docs/adr/0005-durcissement-securite.md).
