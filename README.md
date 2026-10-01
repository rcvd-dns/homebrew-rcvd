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

## Upgrade  

```sh
brew update && brew upgrade rcvd
```

## Issues  

Report packaging problems in this repository. Report rcvd bugs at
https://github.com/rcvd-dns/rcvd/issues.
