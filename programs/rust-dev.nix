{ config, pkgs, ... }:
let
  toml = pkgs.formats.toml { };
in
{
  # rustup, not a pinned nixpkgs toolchain: work repos pin their toolchain in
  # rust-toolchain.toml. Its proxies cover cargo, rustc and rust-analyzer.
  home.packages = with pkgs; [
    rustup
    sccache
    cargo-nextest
    cargo-outdated
    tokio-console
  ];

  # The cargo config, not an env var, so that GUI-launched editors use the
  # wrapper too.
  home.file.".cargo/config.toml".source = toml.generate "cargo-config.toml" {
    build.rustc-wrapper = "${pkgs.sccache}/bin/sccache";
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
