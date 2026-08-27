# Forge, built from the `forge` flake input (see flake.nix for why the source
# is an input rather than a `fetchFromGitHub` here).
{
  pkgs,
  inputs,
  ...
}:

let
  inherit (pkgs) lib;
in
pkgs.rustPlatform.buildRustPackage {
  pname = "forge";
  version = "0.1.0";

  src = inputs.forge;

  # Vendor straight from the committed lock file. This avoids a `cargoHash`
  # that would have to be recomputed — and would silently rot — on every
  # dependency bump.
  cargoLock.lockFile = "${inputs.forge}/Cargo.lock";

  # Forge's dependency tree is pure Rust: `portable-pty`, `vt100`, `ratatui`,
  # `nix` and `tokio` need only libc, so there is no pkg-config/openssl step.
  buildInputs = [ ];
  nativeBuildInputs = [ ];

  # The test suite spawns real PTYs and asserts on process-group signalling
  # (`stty -isig`, `killpg`, `pgrep -g`). That needs a working `/dev/pts` and
  # `procps`, which the build sandbox does not reliably provide, so tests are
  # not part of the package build. Run them in the dev shell instead:
  #
  #     nix develop .#dev --command cargo test
  #
  # CI does exactly that, so the suite is still gated on every change.
  doCheck = false;

  meta = {
    description = "AI development workbench that does not take your terminal away";
    longDescription = ''
      Forge puts an AI coding agent and a real terminal side by side. Long
      running commands stream live to a VT-emulated pane, so a build is watched
      rather than summarised.

      Forge drives the Claude CLI as its agent backend. That binary is not
      packaged here and is not in nixpkgs; install it separately and make sure
      `claude` is on PATH, or point `FORGE_CLAUDE_BIN` at it. Without it Forge
      still runs as a terminal — it says why the agent is absent and carries
      on.
    '';
    homepage = "https://github.com/lucianogdittgen/forge";
    license = lib.licenses.mit;
    mainProgram = "forge";
    platforms = lib.platforms.linux;
  };
}
