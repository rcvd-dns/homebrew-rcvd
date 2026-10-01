# rcvd Homebrew Tap  

Homebrew formula for rcvd, a privacy-first DNS engine with encrypted DoQ/DoT/DoH egress and no
cleartext fallback. Works on macOS (Apple Silicon and Intel) and Linux (Linuxbrew).

- Project: https://github.com/rcvd-dns/rcvd
- Website: https://rcvd.net
- Alternate (backup) homepage: https://gitlab.com/rcvd-dns/rcvd

## Install  

Tap, trust, then install:

```sh
brew tap rcvd-dns/rcvd
brew trust --formula rcvd-dns/rcvd/rcvd
brew install rcvd
```

Homebrew 6.0 and later requires third-party taps to be trusted before install. The command above
trusts only the rcvd formula, not the whole tap. See https://docs.brew.sh/Tap-Trust for the trust
model.

Or as a single command, which taps and trusts just this formula:

```sh
brew install rcvd-dns/rcvd/rcvd
```

## macOS: run rcvd as the system resolver  

On macOS the formula installs a ready-to-use config at `$(brew --prefix)/etc/rcvd/rcvd.toml`. It
listens on `127.0.0.1:53`, forwards to AdGuard (DoQ), Cloudflare (DoT) and Quad9 (DoH) with their IP
addresses pinned, validates DNSSEC, and logs to `$(brew --prefix)/var/log/rcvd/rcvd.log`.

macOS sends DNS only to port 53, and binding port 53 needs root, so the service runs as a root
LaunchDaemon (`sh.brew.rcvd`, also starts at boot). The upstream IPs are pinned because once the Mac
points its DNS at rcvd, rcvd cannot look up its own upstreams by name.

1. Start the service:

   ```sh
   sudo brew services start rcvd
   ```

2. Check that rcvd answers before pointing the system at it:

   ```sh
   dig @127.0.0.1 example.com
   sudo rcvd -config "$(brew --prefix)/etc/rcvd/rcvd.toml" -stats
   ```

3. Point each active network service at rcvd:

   ```sh
   networksetup -listallnetworkservices
   sudo networksetup -setdnsservers "Wi-Fi" 127.0.0.1
   scutil --dns | grep nameserver
   ```

   Repeat the `-setdnsservers` line for other services you use (for example "Ethernet"). If rcvd
   is stopped while this is set, DNS on the Mac stops working.

To undo, restore DHCP-provided DNS first, then stop the service:

```sh
sudo networksetup -setdnsservers "Wi-Fi" empty
sudo brew services stop rcvd
```

Homebrew never overwrites a config you have edited. After an upgrade, the new default appears
beside it as `rcvd.toml.default`. Other example configs live in
`$(brew --prefix)/opt/rcvd/share/rcvd/`; see `man rcvd` for every option. The prefix is
`/opt/homebrew` on Apple Silicon and `/usr/local` on Intel.

## Linux  

The formula installs a ready-to-use config at `$(brew --prefix)/etc/rcvd/rcvd.toml`, with the same
upstreams as on macOS, listening on `127.0.0.1:5300` (no root needed). Start the service:

```sh
brew services start rcvd
dig @127.0.0.1 -p 5300 example.com
```

`brew info rcvd` shows the full caveats, including optional UDP buffer tuning for DoQ.

Running the service with `sudo` makes Homebrew change some rcvd files to root ownership. If a later
`brew upgrade` or `brew uninstall` reports permission errors, stop the service with
`sudo brew services stop rcvd`, run the command, then start the service again with sudo.

## Upgrade  

```sh
brew update && brew upgrade rcvd
```

If rcvd runs as a root service, restart it after upgrading:

```sh
sudo brew services restart rcvd
```

## Issues  

Report packaging problems in this repository. Report rcvd bugs at
https://github.com/rcvd-dns/rcvd/issues.
