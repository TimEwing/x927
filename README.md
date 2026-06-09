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

Each release publishes both downloadable tarballs (on the
[Releases page](https://github.com/TimEwing/x927/releases)) and per-language
**install tags** so you can pull a pinned version straight from the command
line — no manual download.

### Rust

```sh
cargo add --git https://github.com/TimEwing/x927.git --tag rust-vX.Y.Z x927
```

or in `Cargo.toml`:

```toml
x927 = { git = "https://github.com/TimEwing/x927.git", tag = "rust-vX.Y.Z" }
```

It's a crate; its `Cargo.toml` pulls `pdl-runtime` from the pinned pdl commit
and `bytes` from crates.io (cargo resolves those transitively). Not on crates.io
yet — blocked until pdl ships a release with the C++ backend, since the git
`pdl-runtime` pin isn't publishable. (Full rationale for the install-tag scheme:
[`docs/distribution.md`](docs/distribution.md).)

### Python

```sh
pip install "git+https://github.com/TimEwing/x927.git@python-vX.Y.Z"
```

then `import x927`. Pure stdlib, Python 3.8+. (For a public repo you can also
`pip install` the release tarball URL directly.)

### C++

No package manager — grab `x927-cxx-vX.Y.Z.tar.gz` from the Releases page, add
its `include/` to your include path, and `#include "x927.h"`. Needs `-std=c++17`;
the required `packet_runtime.h` ships alongside the generated header.

## Cutting a release

```sh
git tag v1.0.0
git push origin v1.0.0
```

The release workflow stamps that version into the Rust/Python packages,
attaches tarballs to the GitHub Release, and pushes the `rust-vX.Y.Z` /
`python-vX.Y.Z` install tags. Use semver; the protocol is the contract.

## Repo layout

```
spec/x927.pdl              the protocol — the only file you edit to change the wire format
docs/distribution.md       how/why releases + install tags work (read this before changing them)
scripts/generate.sh        runs pdlc for all three backends (used by CI + locally)
third_party/pdl/           vendored packet_runtime.h (the C++ runtime header)
PDL_REV                    pinned google/pdl commit (single source of truth)
.github/workflows/         ci (validate) + release (publish)
```

## Bumping the pdl compiler

We pin to a **commit** of [google/pdl](https://github.com/google/pdl), not a
crates.io release, because the C++ (`cxx`) backend hasn't shipped in a release
yet — it lives only on `main`. To upgrade: put the new sha in `PDL_REV`, then
refresh the vendored C++ runtime header to match (see
[`third_party/pdl/README.md`](third_party/pdl/README.md)). CI re-validates
automatically. (Once pdl cuts a release with `cxx`, switch the pin to that.)

## Generating locally (optional)

Not required, but if you have Rust installed:

```sh
scripts/generate.sh      # installs pdlc on first run, writes to build/
```
