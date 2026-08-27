# forge.nix

A Nix flake that packages [Forge](https://github.com/lucianogdittgen/forge) —
an AI development workbench that puts a coding agent and a **real terminal**
side by side.

## Quick start

You can use the flake directly from GitHub without cloning it:

```sh
nix run github:lucianogdittgen/forge.nix
```

That builds Forge and runs it, with your `$SHELL` in the terminal pane. To run
something else in the pane:

```sh
nix run github:lucianogdittgen/forge.nix -- htop
```

For a shell with `forge` on `PATH`:

```sh
nix develop github:lucianogdittgen/forge.nix
```

To install it into your profile:

```sh
nix profile install github:lucianogdittgen/forge.nix
```

## Outputs

| Output | What it is |
|---|---|
| `packages.default` / `packages.forge` | the `forge` binary |
| `apps.default` | `nix run` entry point |
| `devShells.default` | a shell with `forge` available |
| `devShells.dev` | Rust toolchain for working on Forge's source |
| `formatter` | `treefmt` (nixfmt + statix) |

## Using Forge

Forge starts with the terminal pane focused, so you can type straight away.

| | |
|---|---|
| *(anything)* | goes to the process — including `Ctrl-C`, arrows, `vim` keys |
| **`Esc` `Esc`** (quick double-tap) | leave the terminal pane |
| `Tab` / `Enter` | re-enter the terminal pane |
| `q` or `Ctrl-C` | quit — **only when the terminal is unfocused** |

While the terminal pane has focus, Forge has no shortcuts at all: `Ctrl-C`
interrupts your build rather than quitting Forge. That is the point of the
tool, and it is why leaving the pane is a double-tap gesture — no key is left
over to bind.

## The Claude CLI is a runtime dependency, and is not packaged here

Forge drives the `claude` binary as its agent backend. That binary is not in
nixpkgs and is not vendored by this flake, so the dev shell **warns rather than
fails** when it is absent: Forge's terminal, process and Git features all work
without it, and only the AI pane is unavailable.

Install it separately and make sure `claude` is on `PATH`.

This is deliberate. Forge deliberately does not inherit your Claude
configuration — it runs the CLI with an explicit, minimal environment and its
own `CLAUDE_CONFIG_DIR`, so your `~/.claude` is never read or written. Vendoring
a pinned copy here would work against that.

## Updating Forge

Forge's source is a flake input, so nix records its revision and hash in
`flake.lock` itself. Bumping to the latest commit is:

```sh
nix flake update forge
```

There is no `sha256` in `packages/forge.nix` to keep in step by hand.

## Why tests do not run in the package build

Forge's suite spawns real PTYs and asserts on process-group signalling — it
checks, for instance, that a child which called `stty -isig` ignores a written
`0x03` but still dies to `killpg(SIGINT)`. That needs a working `/dev/pts` and
`procps`, which the Nix build sandbox does not reliably provide, so
`doCheck = false`.

The suite is still gated: CI runs it in the dev shell, which is also how you
run it locally.

```sh
nix develop github:lucianogdittgen/forge.nix#dev
cargo test
```

## Repository layout

```
flake.nix              inputs and output wiring
packages/forge.nix     the Rust package
devshells/default.nix  shell with forge available
devshells/dev.nix      Rust toolchain for hacking on Forge
treefmt.nix            formatter configuration
```

Outputs are discovered by [red-tape](https://github.com/phaer/red-tape), the
same as
[yocto-env.nix](https://github.com/OSSystems/yocto-env.nix): each
`packages/<name>.nix` becomes `packages.<system>.<name>`, and each
`devshells/<name>.nix` becomes `devShells.<system>.<name>`.

## Licence

MIT
