{
  description = "Forge - AI development workbench with a real terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    red-tape.url = "github:phaer/red-tape";
    red-tape.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Forge's source, tracked as a non-flake input.
    #
    # Deliberately an input rather than a `fetchFromGitHub` in
    # `packages/forge.nix`: nix records the revision and hash in `flake.lock`
    # by itself, so a version bump is `nix flake update forge` with no
    # hand-copied `sha256` and no chance of the two drifting apart.
    forge = {
      url = "github:lucianogdittgen/forge";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      base = inputs.red-tape.mkFlake {
        inherit self inputs;
        src = ./.;
        systems = [ "x86_64-linux" ];
      };
    in
    base
    // {
      # red-tape names each `packages/<name>.nix` after its file, so discovery
      # yields `packages.<system>.forge`. Alias it to `default` so
      # `nix run github:lucianogdittgen/forge.nix` needs no `#forge` suffix.
      packages = base.packages // {
        x86_64-linux = base.packages.x86_64-linux // {
          default = base.packages.x86_64-linux.forge;
        };
      };

      apps = (base.apps or { }) // {
        x86_64-linux = (base.apps.x86_64-linux or { }) // {
          default = {
            type = "app";
            program = "${base.packages.x86_64-linux.forge}/bin/forge";
            meta.description = "Run Forge";
          };
        };
      };
    };
}
