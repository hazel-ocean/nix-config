{ config, pkgs, ... }:
let
  toml = pkgs.formats.toml { };
in
{
  # rustup, not a pinned nixpkgs toolchain: work repos pin their toolchain in
  # rust-toolchain.toml. Its proxies cover cargo, rustc and rust-analyzer.
  # Each toolchain needs `rustup component add rust-analyzer`: without it, this
  # proxy and the one in ~/.cargo/bin fall back to each other and recurse.
  home.packages = with pkgs; [
    cargo-audit
    cargo-bloat
    cargo-clean-all
    cargo-clone
    cargo-edit
    cargo-expand
    cargo-flamegraph
    cargo-generate
    cargo-info
    cargo-nextest
    cargo-outdated
    cargo-watch
    cargo-workspaces
    rustup
    sccache
    tokio-console
  ];

  # The cargo config, not an env var, so that GUI-launched editors use the
  # wrapper too.
  home.file.".cargo/config.toml".source = toml.generate "cargo-config.toml" {
    build.rustc-wrapper = "${pkgs.sccache}/bin/sccache";
    # The default openssl output has no headers or .pc file.
    env.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  home.file."Library/Application Support/Mozilla.sccache/config".source =
    toml.generate "sccache-config.toml"
      {
        cache.disk = {
          dir = "${config.home.homeDirectory}/Library/Caches/Mozilla.sccache";
          size = 80 * 1024 * 1024 * 1024;
        };
      };
}
