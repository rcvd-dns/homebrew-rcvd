# Homebrew formula for rcvd
# privacy-first DNS engine. DoQ/DoT/DoH, ACME Certmagic, blocklists and allowlists)
#
# One formula for both macOS and Linux (Linuxbrew); per-OS differences live in
# OS.mac? branches below. Maintenance notes: MAINTAINING.md.
#
# This formula installs the prebuilt release binary for each OS/arch (built once
# by the rcvd release CI, checksummed in the release SHA256SUMS). No Go toolchain
# and no compile on the user's machine: the download is from the official release CI. 
# The man page and rcvd config toml are pulled from the matching source tag as a
# resource (data only, nothing is built from it).
class Rcvd < Formula
  desc "Privacy-first DNS engine with encrypted DoQ/DoT/DoH egress and no cleartext"
  homepage "https://rcvd.net"
  version "0.3.1"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/rcvd-dns/rcvd/releases/download/v0.3.1/rcvd-macos-arm64"
      sha256 "0bbe4a381e83c9d41a7f4c2ff93010e85d9cb4c633ea3238bb2aee7fe1c44c33"
    end
    on_intel do
      url "https://github.com/rcvd-dns/rcvd/releases/download/v0.3.1/rcvd-macos-amd64"
      sha256 "f0a05401236604ea89adf907a72061fe95417ba2fa46c290b378fb4e38ee0b88"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/rcvd-dns/rcvd/releases/download/v0.3.1/rcvd-linux-arm64"
      sha256 "1d1dfbc2e4cec83e9a2a14cf30cab2fc11d21294b3086d960590141625da66f7"
    end
    on_intel do
      url "https://github.com/rcvd-dns/rcvd/releases/download/v0.3.1/rcvd-linux-amd64"
      sha256 "4906f1c1ad32e86aa1ee4724ca48650c1e8342e9d5ed796f22a74d11ef22ce02"
    end
  end

  # Man page + example configs from the matching source tag. Not compiled; only
  # the man/ and etc/ data files are installed from it.
  resource "extras" do
    url "https://github.com/rcvd-dns/rcvd/archive/refs/tags/v0.3.1.tar.gz"
    sha256 "e633c926c97d9642cf6dcdd9582a2edaaaec5d2e822d3cbe5c91b95c6f14cd18"
  end

  def install
    # The downloaded file is the prebuilt binary itself; install it as `rcvd`.
    bin.install stable.url.split("/").last => "rcvd"

    resource("extras").stage do
      man1.install "man/rcvd.1"
      pkgshare.install Dir["etc/*.toml"]
    end

    # A ready-to-run config. Homebrew never overwrites an existing etc file; an
    # edited copy is kept and the new one lands beside it as rcvd.toml.default.
    (buildpath/"rcvd.toml").write rcvd_config
    (etc/"rcvd").install "rcvd.toml"
  end

  post_install_steps do
    mkdir_p "rcvd", base: :etc
    mkdir_p "log/rcvd", base: :var
  end

  # macOS only sends DNS to port 53, which needs root, so the service runs as a
  # LaunchDaemon via sudo brew services. On Linux the default port 5300 runs as
  # the invoking user (systemd user unit).
  service do
    run [opt_bin/"rcvd", "-config", etc/"rcvd/rcvd.toml"]
    keep_alive true
    require_root true if OS.mac?
    log_path var/"log/rcvd/rcvd.log"
    error_log_path var/"log/rcvd/rcvd.log"
    working_dir var
  end

  # macOS listens on port 53 as the system resolver; Linux on the default 5300.
  # Upstreams pin `ip`, so rcvd never makes a cleartext lookup for them (and on
  # macOS, once DNS points at 127.0.0.1, it could not look them up at all).
  # Logging goes to stderr, which brew services writes to var/log/rcvd/rcvd.log;
  # rcvd's built-in default /var/log/rcvd/rcvd.log is not writable from Homebrew.
  def rcvd_config
    listen = OS.mac? ? "127.0.0.1:53" : "127.0.0.1:5300"
    <<~TOML
      # rcvd config (installed by Homebrew).
      # Examples for other setups: #{opt_pkgshare}
      # All options: man rcvd

      stats_enabled = true

      [resolver]
      enabled = true
      listen = "#{listen}"

      [[upstreams]]
      name = "AdGuard DoQ"
      host = "dns.adguard.com"
      ip = "94.140.14.14"
      port = 853
      doq = true

      [[upstreams]]
      name = "Cloudflare DoT"
      host = "cloudflare-dns.com"
      ip = "1.1.1.1"
      port = 853
      dot = true

      [[upstreams]]
      name = "Quad9 DoH"
      host = "dns.quad9.net"
      ip = "9.9.9.9"
      port = 443
      doh = true

      [dnssec]
      enabled = true

      [cache]
      enabled = true
      type = "aggressive"
      max_size = 4096

      [logging]
      file = "stderr"
      level = "info"
      format = "text"
    TOML
  end

  def caveats
    sysctl = if OS.mac?
      %w[net.inet.udp.recvspace=7340032 net.inet.udp.sendspace=7340032 kern.ipc.maxsockbuf=8388608]
    else
      %w[net.core.rmem_max=7340032 net.core.wmem_max=7340032]
    end
    persist = OS.mac? ? "/etc/sysctl.conf" : "/etc/sysctl.d/30-rcvd.conf"

    setup = if OS.mac?
      <<~EOS
        #{etc}/rcvd/rcvd.toml is ready to use as the macOS system resolver
        (127.0.0.1:53). Port 53 needs root, so start the service with sudo:

          sudo brew services start rcvd

        Then point macOS DNS at it (repeat for each network service you use):

          sudo networksetup -setdnsservers "Wi-Fi" 127.0.0.1

        Undo with: sudo networksetup -setdnsservers "Wi-Fi" empty
        After brew upgrade rcvd, restart it: sudo brew services restart rcvd
        Full steps: https://github.com/rcvd-dns/homebrew-rcvd
      EOS
    else
      <<~EOS
        #{etc}/rcvd/rcvd.toml is ready to use and listens on 127.0.0.1:5300.
        Start the service:

          brew services start rcvd

        Other example configs are in #{opt_pkgshare}.
      EOS
    end

    <<~EOS
      #{setup}
      rcvd speaks QUIC (DoQ) by default. If quic-go warns "failed to sufficiently
      increase receive buffer size", raise the kernel UDP buffer limits. rcvd still
      works without this, with slightly lower throughput.

      #{sysctl.map { |kv| "  sudo sysctl -w #{kv}" }.join("\n")}

      To persist across reboots, add the same keys to #{persist}.
    EOS
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/rcvd -version")
    assert_path_exists pkgshare/"mode1-forwarder-3providers.toml"
  end
end
