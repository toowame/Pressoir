# Manual test plan

`swift test` covers the domain (`PressoirCore`). The system side (pasteboard, shortcut, panel,
Keychain, Accessibility) is checked by hand before each release, with a fresh build:

```bash
Scripts/build-app.sh release native && open Pressoir.app
```

## Launch

- [ ] A clipboard icon appears in the menu bar, and no icon appears in the Dock.
- [ ] Quit and relaunch: the history is still there, and `strings history.enc` shows no copied text.

## Text

- [ ] Copy three texts in different apps, then press <kbd>⇧⌘V</kbd> in TextEdit: the panel opens under
      the mouse with three entries, the newest on top.
- [ ] First paste: macOS asks for Accessibility. Enable Pressoir in **System Settings → Privacy &
      Security → Accessibility**.
- [ ] <kbd>↓</kbd> then <kbd>↩</kbd>: the second entry is pasted into TextEdit and the panel closes.
- [ ] <kbd>⌘1</kbd> pastes the first entry. Typing a word filters the list.
- [ ] <kbd>⌘P</kbd> pins an entry; it stays on top after new copies.

## Panel

- [ ] With the mouse near the right or bottom edge of the screen, the panel stays fully visible.
- [ ] A click elsewhere or <kbd>Esc</kbd> closes the panel.

## Images

- [ ] A screenshot to the clipboard (<kbd>⌃⇧⌘4</kbd>) shows a thumbnail and "Image · W × H";
      <kbd>↩</kbd> pastes it into Preview (**File → New from Clipboard**).
- [ ] Copying the same image again moves it to the top, with no duplicate.
- [ ] Copying a file in the Finder adds nothing.
- [ ] Deleting the image (<kbd>⌘⌫</kbd>) removes its file from `images/`.

## Sensitive content

- [ ] A password copied from 1Password or Keychain Access does not appear.
- [ ] Copying `AKIAIOSFODNN7EXAMPLE` (a sample AWS key) does not add it.

## Guarded paste

- [ ] Open the panel in TextEdit, click into another app, then press <kbd>↩</kbd> in the panel:
      nothing is pasted elsewhere.
- [ ] With a password field focused (Safari), <kbd>↩</kbd> does not paste automatically.

## Keychain

- [ ] Deny Keychain access: the menu shows that the history is locked, and the existing history is
      intact at the next launch.
