# x927

A tiny binary packet protocol so our assorted lighting and music projects can
all talk to each other. The wire format is defined once, in
[`spec/x927.pdl`](spec/x927.pdl), using Google's
[Packet Description Language (pdl)](https://github.com/google/pdl). CI compiles
that spec into ready-to-use **Rust**, **Python**, and **C++** codecs so each
project can just grab the language it needs.

**You don't need Rust (or any toolchain) to use this.** All compilation happens
in GitHub Actions; you download prebuilt sources from the Releases page.

## How it works

```
spec/x927.pdl ──► (GitHub Actions runs pdlc) ──► Rust / Python / C++ codecs
                                                 └─► attached to a Release
```

- **Edit the protocol:** change `spec/x927.pdl`, open a PR.
- **CI** (`.github/workflows/ci.yml`) regenerates all three backends on every
  push and *compiles* each one to prove the spec is valid. Generated sources are
  also uploaded as a workflow artifact so you can eyeball a PR's output.
- **Releasing** (`.github/workflows/release.yml`) on a `v*` tag builds the
  backends and attaches them to a GitHub Release.

## Using it in a project

Grab the artifact for your language from the
[Releases page](https://github.com/TimEwing/x927/releases).

| Language | Artifact                  | Runtime dependency                          |
|----------|---------------------------|---------------------------------------------|
| Rust     | `x927-rust-vX.Y.Z.tar.gz` | crate, depends on `pdl-runtime` + `bytes`   |
| Python   | `x927-python-vX.Y.Z.tar.gz` | none — pure stdlib (Python 3.8+)          |
| C++      | `x927-cxx-vX.Y.Z.tar.gz`  | none — bundled `packet_runtime.h` (C++17)   |

- **Rust:** it's a crate. Drop it in and `path`-depend on it, or `git`-depend on
  a vendored copy. `pdl-runtime` + `bytes` come from crates.io.
- **Python:** `pip install x927-python-vX.Y.Z.tar.gz`, then `import x927`.
- **C++:** add `include/` to your include path, `#include "x927.h"`. Needs
  `-std=c++17`. `packet_runtime.h` ships alongside the generated header.

## Cutting a release

```sh
git tag v1.0.0
git push origin v1.0.0
```

The release workflow stamps that version into the Rust/Python packages and
publishes the assets. Use semver; the protocol is the contract.

## Repo layout

```
spec/x927.pdl              the protocol — the only file you edit to change the wire format
scripts/generate.sh        runs pdlc for all three backends (used by CI + locally)
third_party/pdl/           vendored packet_runtime.h (the C++ runtime header)
PDL_VERSION                pinned pdl-compiler version (single source of truth)
.github/workflows/         ci (validate) + release (publish)
```

## Bumping the pdl compiler

Edit `PDL_VERSION`, then refresh the vendored C++ runtime header to match (see
[`third_party/pdl/README.md`](third_party/pdl/README.md)). CI re-pins and
re-validates automatically.

## Generating locally (optional)

Not required, but if you have Rust installed:

```sh
scripts/generate.sh      # installs pdlc on first run, writes to build/
```
