# 0003. History encrypted with AES-256-GCM, key in the Keychain

- **Status:** Accepted. Replaces the storage part of [0002](0002-plain-text-and-sensitive-data.md).
- **Date:** 2026-10-23

## Context

Mode 0600 protects the history from other accounts, not from a backup (Time Machine, a disk copy) or
from a tool that reads the user's files.

## Decision

- `~/Library/Application Support/Pressoir/history.enc` holds the history as JSON sealed with
  AES-256-GCM (CryptoKit). Every save uses a fresh random nonce, and the file is authenticated: a
  tampered file, or one sealed with another key, is rejected. Mode 0600.
- A random 256-bit key is created on first launch and stored in the login Keychain (service
  `io.github.toowame.Pressoir`, account `history-encryption-key`). It is available after the first
  unlock and bound to this Mac (`ThisDeviceOnly`: no iCloud sync, no restore on another Mac).
- A one-time migration re-encrypts an earlier plaintext `history.json`, then deletes it.
  *Removed later by [0005](0005-security-hardening.md).*
- Search leaves no trace: it filters in memory and writes nothing.

## Consequences

- ✅ No copied text is readable on disk or in a disk backup.
- ⚠️ A lost key (Keychain wiped) makes the history unreadable.
  [0005](0005-security-hardening.md) makes sure nothing is overwritten in that case.
- ⚠️ With ad-hoc signing, macOS may ask for Keychain access again after a rebuild.
- ⚠️ While the app runs, the history is in clear in memory, which is unavoidable to display it.
