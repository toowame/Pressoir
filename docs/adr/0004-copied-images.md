# 0004. Copied images, one sealed file per image

- **Status:** Accepted. Replaces "plain text only" in [0002](0002-plain-text-and-sensitive-data.md).
- **Date:** 2026-11-02

## Context

A screenshot weighs several megabytes. Putting it inside `history.enc` would mean re-encrypting and
rewriting the whole history, tens of megabytes, on every copy.

## Decision

- Each image is stored on its own, in `Application Support/Pressoir/images/<id>.enc`, sealed with
  AES-256-GCM using the Keychain key from [0003](0003-encrypted-history.md). Mode 0600.
- The file name is a random identifier and reveals nothing about the image. The SHA-256 digest used
  to spot a re-copied image lives only inside the encrypted history.
- Images are stored as PNG: lossless and much lighter than the TIFF that screenshots produce.
- Images over 20 MB are skipped.
- After every change, image files the history no longer references (evicted, deleted, cleared) are
  removed from disk.
- When a copy holds both text and an image (Word, Excel), the text wins. A file copied in the Finder
  (a file URL plus a TIFF icon) is not taken for an image.
- Search only matches text; images stay visible when the search field is empty.
- When pasted, an image is put back as PNG and TIFF, for older apps.
- Images count toward the 50 unpinned entries.

## Consequences

- ✅ Copying text stays instant even with images in the history.
- ✅ No pixel in clear on disk, no telling file name.
- ⚠️ Worst case around 50 images × 20 MB; in practice a few megabytes per screenshot.
- ⚠️ Thumbnails are decrypted and kept in memory while the app runs.
