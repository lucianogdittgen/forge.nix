{ pkgs, ... }:

# Shell for working on Forge's own source tree.
#
# Unlike the default shell this deliberately does *not* pull in the built
# `forge` package: you are building it yourself, and depending on the packaged
# copy would mean every source edit waits on a Nix rebuild first.
pkgs.mkShell {
  packages = with pkgs; [
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # The process tests assert that signals reach grandchildren, which they
    # verify with `pgrep -g`.
    procps

    git
  ];

  env.RUST_BACKTRACE = "1";

  shellHook = ''
    echo "forge dev shell - cargo $(cargo --version | cut -d' ' -f2), rustc $(rustc --version | cut -d' ' -f2)"
    echo "  cargo test      run the suite (54 tests)"
    echo "  cargo run       start Forge from source"
  '';
}
