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

## Configure and run  

rcvd does nothing until it has a config. Copy a bundled example, then start the service:

```sh
cp "$(brew --prefix)/opt/rcvd/share/rcvd/mode1-forwarder-3providers.toml" \
   "$(brew --prefix)/etc/rcvd/rcvd.toml"
brew services start rcvd
```

The default listen port is 5300, which needs no root. `brew info rcvd` shows the full caveats,
including optional UDP buffer tuning for DoQ. See `man rcvd` for every config option.

The bundled examples live in `$(brew --prefix)/opt/rcvd/share/rcvd/`. Homebrew never writes a
config for you; `$(brew --prefix)/etc/rcvd/` starts empty. The prefix is `/opt/homebrew` on Apple
Silicon, `/usr/local` on Intel, and `/home/linuxbrew/.linuxbrew` on Linux.

## macOS: use rcvd as the system resolver (port 53)  

macOS sends DNS only to IP addresses on port 53. There is no port setting in System Settings or
`networksetup`, so for rcvd to handle every app's queries it must listen on `127.0.0.1:53`. Port
5300 is only useful when something else forwards to rcvd. Binding port 53 needs root on macOS, so
the service runs as a root LaunchDaemon.

1. Install (see above), then copy an example config:

   ```sh
   cp "$(brew --prefix)/opt/rcvd/share/rcvd/mode1-forwarder-3providers.toml" \
      "$(brew --prefix)/etc/rcvd/rcvd.toml"
   ```

2. Edit `$(brew --prefix)/etc/rcvd/rcvd.toml`. Under `[resolver]`, change the listen address:

   ```toml
   listen = "127.0.0.1:53"
   ```

   Under `[logging]`, set a log file inside the Homebrew prefix (the built-in default,
   `/var/log/rcvd/rcvd.log`, does not exist on macOS). Use your real prefix:

   ```toml
   file = "/opt/homebrew/var/log/rcvd/rcvd.log"   # Intel: /usr/local/var/log/rcvd/rcvd.log
   ```

3. Start the service as root. This installs the LaunchDaemon `sh.brew.rcvd`, which also starts at
   boot:

   ```sh
   sudo brew services start rcvd
   ```

4. Check that rcvd answers before pointing the system at it:

   ```sh
   dig @127.0.0.1 example.com
   sudo rcvd -config "$(brew --prefix)/etc/rcvd/rcvd.toml" -stats
   ```

5. Point each active network service at rcvd:

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
