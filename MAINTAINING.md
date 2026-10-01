# Maintaining the rcvd Tap  

`Formula/rcvd.rb` is the only copy of the rcvd formula; the rcvd source repo links here and
carries no Homebrew files. One formula serves macOS (Apple Silicon and Intel) and Linux; per-OS
differences live in `OS.mac?` branches. User-facing install steps are in `README.md`.

## Releases  

The `brew bump` workflow (`.github/workflows/autobump.yml`) runs daily. After a new rcvd tag
is pushed, it opens a PR here with the new `url` and `sha256`. `brew test-bot` builds and tests
the PR on macOS and Linux; review and merge it. No hand-editing of the hash is needed.

To test a formula change locally, install through the tap (Homebrew refuses a file path):

```sh
brew install --build-from-source rcvd-dns/rcvd/rcvd
brew test rcvd && brew audit --strict --new rcvd-dns/rcvd/rcvd
```

## macOS: port 53 for the system resolver  

macOS sends DNS only to IP addresses on port 53. mDNSResponder has no port setting, and
`/etc/resolver/<domain>` accepts a port only per domain. The default port 5300 therefore only
helps when something else forwards to rcvd.

To act as the system resolver, rcvd listens on `127.0.0.1:53`. macOS 26 denies that bind to a
normal user, so the service runs as root with `sudo brew services start rcvd` (LaunchDaemon
`sh.brew.rcvd`, starts at boot; the service block sets `require_root` on macOS).

The formula writes a ready config (`rcvd_config`) to `etc/rcvd/rcvd.toml` on both OSes:
- `listen` is `127.0.0.1:53` on macOS and `127.0.0.1:5300` on Linux.
- Upstream `ip` pinned. Without it rcvd must look up its upstreams through the system resolver,
  which is rcvd itself, so it never starts resolving.
- `[logging] file = "stderr"`. brew services writes stderr to `var/log/rcvd/rcvd.log`. rcvd's
  built-in default `/var/log/rcvd/rcvd.log` is not writable from Homebrew, and rcvd exits.

Homebrew keeps a user-edited etc file and installs the new one as `rcvd.toml.default`. If a
provider changes an upstream IP, update `rcvd_config`.

`rcvd -stats` needs `sudo` on macOS. There is no `/run/rcvd`, so the socket falls back to
`os.TempDir()`: `/tmp` for the root daemon and under `sudo`, but `/var/folders/...` in a user shell.

Linux differs: systemd-resolved owns `127.0.0.53:53` and its `DNS=` accepts `IP:port`, so it
forwards to rcvd on 5300 with no root.

## Homebrew behavior that affects rcvd  

- **Tap trust (Homebrew 6.0+).** Third-party taps must be trusted before their code runs. The
  install docs use `brew trust --formula rcvd-dns/rcvd/rcvd`, which trusts only this formula.
  Untrusted taps are no longer auto-tapped. A Brewfile would need `trusted:` on the tap entry.
  https://brew.sh/2026/06/11/homebrew-6.0.0/ and https://docs.brew.sh/Tap-Trust
- **Formulae must live in a tap (Homebrew 7).** Test through the tap, not a file path.
- **`post_install` is deprecated** in favor of `post_install_steps`.
- **Linux build sandbox (Bubblewrap, 6.0+).** Applies to build, test, and post-install on Linux,
  so the formula must not assume network or file access outside the sandbox.
- **`std_go_args`** already adds `-s -w` and `-trimpath`; do not repeat them in `ldflags`.
- **homebrew-core** needs 90 forks, 90 watchers, or 225 stars for a self-submission
  (https://docs.brew.sh/Package-Acceptance-Policy). Revisit once rcvd meets that.

## Prefixes and tuning  

- Homebrew prefix: `/opt/homebrew` (Apple Silicon), `/usr/local` (Intel),
  `/home/linuxbrew/.linuxbrew` (Linux). The formula uses prefix helpers (`etc`, `var`,
  `opt_bin`), never hardcoded paths.
- DoQ UDP buffer tuning on macOS uses `net.inet.udp.recvspace`, `net.inet.udp.sendspace`, and
  `kern.ipc.maxsockbuf`, not the Linux `net.core.*` keys. The formula caveats print both.

## Tested  

- v0.3.0 on Linuxbrew (Homebrew 7.0) and macOS 26.6 Intel: build, test, and `audit --strict` clean.
- macOS 26.6 Intel: `sudo brew services` on `127.0.0.1:53` as the system resolver.

## Open  

- [ ] Test on Apple Silicon (`/opt/homebrew` prefix). Only Intel is tested so far.