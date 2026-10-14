# arc-playwright-extension-patch

Make [Playwright MCP](https://github.com/microsoft/playwright-mcp) drive a running
[Arc](https://arc.net) browser in `--extension` mode.

## Why

Two Arc behaviours break extension mode:

- **Arc refuses a second process.** Playwright opens the extension's connect page by
  starting the browser binary with the page URL. Arc shows "Arc is already open. Only one
  instance of Arc can be opened at a time." and the page never opens.
  `arc-open-url` replaces the binary: it drops the flags and hands the URL to the running
  Arc with `open -a Arc`.
- **Arc has no tab groups.** The extension puts connected tabs in a "Playwright" tab
  group. In Arc, `chrome.tabs.group`, `chrome.tabs.ungroup`, `chrome.tabGroups.query` and
  `chrome.tabGroups.update` exist but never settle. The connect page waits on an ungroup
  call before it loads the tab list, so it shows no tabs and no "Allow & select" button.
  `arc-shim.js` makes those calls reject at once. Every caller already catches the
  error, and tab attachment does not depend on the group, so the connection works.
  Tabs are not grouped.

## Install

1. Run the install script. It downloads the current extension from the Chrome Web Store,
   removes `_metadata/`, prepends the shim to `lib/background.mjs`, writes the result to
   `~/.local/share/playwright-extension-arc`, and links `arc-open-url` into `~/.local/bin`.

   ```sh
   ./install.sh
   ```

2. In `arc://extensions`, remove the Web Store "Playwright Extension" if it is installed.
   Two extensions cannot share an ID.
3. Turn on "Developer mode". The unpacked extension is disabled while it is off.
4. Click "Load unpacked". Press `Cmd+Shift+G`, enter
   `~/.local/share/playwright-extension-arc`, and select it.
5. Check that the ID is `mmlmfjhmonkocbjadbfplnigmagldckm`. The manifest's `key` field
   keeps the Web Store ID, which Playwright expects.
6. Configure the MCP server:

   ```sh
   claude mcp add playwright -s user -- npx @playwright/mcp@latest --extension \
     --executable-path ~/.local/bin/arc-open-url \
     --user-data-dir "$HOME/Library/Application Support/Arc/User Data"
   ```

   With `--executable-path` set, Playwright skips its check that the extension is in the
   profile, so it accepts the unpacked extension.

## Update

The Web Store does not update an unpacked extension. When the connect page reports a
version mismatch after a `@playwright/mcp` update, run `./install.sh` again, reload the
extension in `arc://extensions`, and reconnect the MCP server.

## Troubleshooting

- **No connect page opens.** The server opens the page one time and then waits for that
  connection. If you closed the page, reconnect the MCP server (`/mcp` in Claude Code).
- **The tab list is empty.** The shim is not active. Check that the unpacked extension is
  enabled and that Developer mode is on.

## License

The files in this repository are under the [WTFPL](LICENSE).

The Playwright Extension is © Microsoft Corporation, Apache License 2.0. This repository
contains no extension code; `install.sh` downloads it from the Chrome Web Store.
