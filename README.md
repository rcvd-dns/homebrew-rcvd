# rcvd Homebrew Tap  

Homebrew formula for rcvd, privacy-first DNS engine with encrypted egress only, DoQ/DoT/DoH.  

Works on macOS (Apple Silicon and Intel) and Linux (Linuxbrew).

- Project: https://github.com/rcvd-dns/rcvd
- Website: https://rcvd.net
- Alternate (backup) homepage: https://gitlab.com/rcvd-dns/rcvd

## One-Line Install  

```sh
brew install rcvd-dns/rcvd/rcvd
```

Installs the prebuilt release binary.  
The fully qualified name trusts only this formula, which Homebrew 6.0+ requires for third-party taps.  
See https://docs.brew.sh/Tap-Trust

## macOS: run rcvd as the system resolver  

On macOS, run rcvd on port 53. This is the only configuration we recommend on macOS, and the only
one that works as the system resolver. macOS sends DNS only to port 53 (mDNSResponder has no port
setting), so any other port will not be used as intended. This is a macOS limitation, not an rcvd
one.

On macOS the formula installs a ready-to-use config at `$(brew --prefix)/etc/rcvd/rcvd.toml`.  
It listens on `127.0.0.1:53`, forwards to AdGuard (DoQ), Cloudflare (DoT) and Quad9 (DoH) with their IP
addresses pinned, validates DNSSEC, and logs to `$(brew --prefix)/var/log/rcvd/rcvd.log`.

Binding port 53 needs root, so the service runs as a root LaunchDaemon (`sh.brew.rcvd`, also starts
at boot). The upstream IPs are pinned because once the Mac points its DNS at rcvd, rcvd cannot look
up its own upstreams by name.

1. Start the service:

   ```sh
   sudo brew services start rcvd
   ```

   Manage and check the service with `sudo`  
   `sudo brew services list` should show:

   ```
   rcvd      started root /Library/LaunchDaemons/sh.brew.rcvd.plist
   ```

2. Check that rcvd answers before pointing the system at it:

   ```sh
   dig @127.0.0.1 example.com
   sudo rcvd -config "$(brew --prefix)/etc/rcvd/rcvd.toml" -stats
   ```

3. Point your active network service at rcvd. First list the services and find the one your Mac
   actually uses (the name varies: "Wi-Fi", "Ethernet", or a USB adapter such as
   "USB 10/100/1000 LAN"), then set its DNS. Substitute your own service name for `"Wi-Fi"` below:

   ```sh
   networksetup -listallnetworkservices
   sudo networksetup -setdnsservers "Wi-Fi" 127.0.0.1
   scutil --dns | grep nameserver
   ```

   Repeat the `-setdnsservers` line for every service you actually use. Do not set it on a service
   whose link is down: macOS keeps that stale entry, and if rcvd is later removed it can break DNS
   with no working resolver left. While rcvd is the system resolver, stopping it stops DNS on the Mac.

4. Confirm the Mac is really resolving through rcvd (not just configured to). rcvd's query counter
   should climb as the system resolves names:

   ```sh
   sudo lsof -nP -iUDP:53 | grep rcvd        # rcvd owns port 53
   sudo rcvd -config "$(brew --prefix)/etc/rcvd/rcvd.toml" -stats | grep 'Total handled'
   ```

   Resolve something, run the `-stats` line again, and `Total handled` should have increased.

To undo, set the same service you changed, back to automatic (DHCP-provided) DNS, then stop the
service. Confirm name resolution still works afterward; if it does not, set that service to a known
working resolver explicitly.

```sh
sudo networksetup -setdnsservers "Wi-Fi" empty
sudo brew services stop rcvd
```

Running the service with `sudo` makes Homebrew change some rcvd files to root ownership. If a later
`brew upgrade` or `brew uninstall` reports permission errors, stop the service with
`sudo brew services stop rcvd`, run the command, then start the service again with sudo.

Other example configs live in
`$(brew --prefix)/opt/rcvd/share/rcvd/`; see `man rcvd` for every option. The prefix is
`/opt/homebrew` on Apple Silicon and `/usr/local` on Intel.

## Linux  

The formula installs a ready-to-use config at `$(brew --prefix)/etc/rcvd/rcvd.toml`, with the same
upstreams as on macOS, listening on `127.0.0.1:5300` (no root needed). Start the service:

```sh
brew services start rcvd
dig @127.0.0.1 -p 5300 example.com
```

`brew services` on Linux runs rcvd as a systemd user service, which stops when you log out. On a
server, or any box you reach over SSH, enable lingering so rcvd keeps running and starts at boot:

```sh
sudo loginctl enable-linger $USER
```

`brew info rcvd` shows the full caveats, including optional UDP buffer tuning for DoQ.

## Upgrade  

```sh
brew update && brew upgrade rcvd
```

If rcvd runs as a root service, restart it after upgrading:

```sh
sudo brew services restart rcvd
```

Homebrew never overwrites a config you have edited. After an upgrade, the new default appears
beside it as `rcvd.toml.default`.

## Issues  

- Report packaging problems in this repository.

- Report `rcvd` bugs at https://github.com/rcvd-dns/rcvd/issues

