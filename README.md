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

While the terminal pane has focus, Forge has **no shortcuts at all** — every
key goes to the child, so `Ctrl-C` interrupts your build rather than quitting
Forge. That is the point of the tool, and it is why leaving the pane is a
double-tap gesture: no key is left over to bind.

| In the terminal pane | |
|---|---|
| *(anything)* | goes to the process — `Ctrl-C`, `Tab`, arrows, `vim` keys |
| **`Esc` `Esc`** (quick double-tap) | leave the pane |

| In the conversation pane | |
|---|---|
| `Tab` | enter the terminal pane |
| `Enter` | send what you typed to the agent |
| `y` / `n` | answer a pending approval |
| `Ctrl-C` | cancel the turn in flight, or quit when there is none |
| `Ctrl-]` | point the terminal at another process |
| `PgUp` / `PgDn` | scroll the conversation |

The agent reads and edits your tree like any coding agent, but it has no shell.
Every command it runs goes through the process manager the pane reads from, so
ask for a build on the left and it appears on the right, live, without you
asking to see it — there is no way for it to run something you cannot watch. If
you have deliberately switched away with `Ctrl-]`, the pane stays where you put
it.

That is also why a long build does not cost you tokens: the output goes to the
pty and to your eyes, and reaches the model only if it asks, under a cap.

Note that this only holds for **Forge's own** agent, in the left pane. Starting
a second agent *inside* the terminal pane gives you an ordinary child process
with its own tools; anything it backgrounds is invisible to Forge, because
Forge never started it.

## The Claude CLI is a runtime dependency, and is not packaged here

Forge drives the `claude` binary as its agent backend. That binary is not in
nixpkgs and is not vendored by this flake, so the shell **warns rather than
fails** when it is absent: Forge still runs as a terminal, and says in the left
pane why nobody is home there.

Install it separately and either put `claude` on `PATH` or point Forge at it:

```sh
export FORGE_CLAUDE_BIN=/path/to/claude
```

This is deliberate. Forge deliberately does not inherit your Claude
configuration — it runs the CLI with an explicit, minimal environment and its
own `CLAUDE_CONFIG_DIR`, so your `~/.claude` is never read or written. Vendoring
a pinned copy here would work against that.

## Which Forge you get

Forge's source is a flake input, so its revision and hash both live in
`flake.lock` and roll together — there is no `sha256` in `packages/forge.nix`
to keep in step by hand. Bumping to the latest commit is:

```sh
nix flake update forge
```

`flake.lock` pins an exact Forge revision, so a run gives everyone the same
binary — and **a new commit to Forge does not reach you until the lock is
bumped.** That is the trade a lock makes. To follow the tip instead, for a
single run:

```sh
nix run --refresh github:lucianogdittgen/forge.nix
```

The nightly `Update Forge` workflow does the bump: it updates the input,
verifies `nix build .#forge`, publishes the resulting lock as an artifact, and
opens a PR.

Opening that PR needs **Settings → Actions → General → Workflow permissions →
"Allow GitHub Actions to create and approve pull requests"**, which is off for
this repository, so that last step currently fails. The artifact is published
either way and can be landed by hand:

```sh
gh run download <run-id> -n flake-lock && git add flake.lock
```

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
