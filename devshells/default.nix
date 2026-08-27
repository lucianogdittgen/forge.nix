{ pkgs, flake, ... }:

# The shell you get from `nix develop github:lucianogdittgen/forge.nix`:
# Forge itself, ready to run, plus the tools it shells out to.
#
# For hacking on Forge's source, use `nix develop .#dev` instead.
let
  forge = flake.packages.${pkgs.system}.forge;
in
pkgs.mkShellNoCC {
  packages = [
    forge
    pkgs.git
  ];

  shellHook = ''
    # NB: no `forge --version` here. Forge currently treats its arguments as
    # the command to run in the terminal pane, so `--version` would be spawned
    # as a program and fail. Revisit once it grows real flag parsing.
    echo "forge 0.1.0 - run 'forge' to start, or 'forge <cmd>' to run a command"

    # Forge drives the Claude CLI as its agent backend. It is not in nixpkgs,
    # so warn rather than fail: Forge is still a usable terminal without it,
    # and a missing binary should not block the shell.
    if ! command -v claude >/dev/null 2>&1 && [ -z "''${FORGE_CLAUDE_BIN:-}" ]; then
      echo "note: 'claude' is not on PATH - Forge will start without an agent."
      echo "      Put it on PATH, or set FORGE_CLAUDE_BIN=/path/to/claude."
      echo "      The terminal pane works regardless."
    fi
  '';
}
