# How x927 is distributed (and why)

This is the reasoning behind the release setup, so future-us remembers why it
looks the way it does instead of "fixing" it back into something broken.

## The goal

One `.pdl` spec, compiled in CI, consumed by Rust / Python / C++ projects with a
**single command** — no manual tarball downloads, and **no Rust toolchain on
anyone's machine** (compilation happens only in GitHub Actions).

## The constraint that drives everything

`pdlc` (the pdl compiler) is pinned to a **git commit** of `google/pdl`, not a
crates.io release — because the C++ (`cxx`) backend hasn't shipped in any
published version yet; it exists only on `main`. See `PDL_REV`.

That single fact knocks out the obvious distribution paths:

| Path | Why it doesn't work |
|------|---------------------|
| Rust → **crates.io** (`cargo add x927`) | The generated crate depends on `pdl-runtime` via a **git** pin (same commit as the compiler). crates.io forbids git dependencies in published crates, so we can't publish until pdl cuts a release with `cxx`. |
| Rust → **release tarball** | cargo simply cannot consume an HTTP tarball as a dependency. Deps come only from crates.io, a git ref, or a local path. |
| Commit generated code to `main` | Works for cargo's git-dep resolver, but pollutes history with regenerated output on every spec change (noisy diffs, merge churn). We chose to keep `main` to hand-written source only. |

## The solution: per-language orphan install tags

On every release (`vX.Y.Z`), the workflow generates the code and then pushes the
**package source** to a dedicated, throwaway git tag per language, whose tree
root *is* the package:

- `rust-vX.Y.Z`   → root is the crate (`Cargo.toml` + `src/`)
- `python-vX.Y.Z` → root is the sdist (`pyproject.toml` + `x927/`)

Each is an **orphan commit** (no parent, unrelated to `main`'s history), pushed
straight to `refs/tags/<lang>-vX.Y.Z`. So `main` stays clean — generated code
never lands in its history — while cargo and pip each get a real git ref to
fetch from:

```sh
cargo add --git https://github.com/TimEwing/x927.git --tag rust-vX.Y.Z x927
pip install "git+https://github.com/TimEwing/x927.git@python-vX.Y.Z"
```

Why this works:
- **cargo** clones the repo, checks out the tag, and searches the tree for the
  requested package. With the crate at the tag root it's found immediately, and
  cargo transitively resolves the git `pdl-runtime` pin from its `Cargo.toml`.
- **pip** clones the repo at the tag and builds the sdist from the `pyproject.toml`
  at the root. The generated Python is pure stdlib, so there's nothing else to
  resolve.

C++ has no package-manager story, so it stays a Releases tarball (`include/`
with the generated header + the vendored `packet_runtime.h`).

## Why the tag-format guard exists

cargo and pip disagree on prerelease syntax: cargo wants `1.0.0-rc1`, PEP 440
wants `1.0.0rc1`. The stamp step derives one version string from the tag
(`vX.Y.Z` → `X.Y.Z`), so a prerelease suffix would be valid for one ecosystem
and rejected by the other (a `0.0.0-test` tag literally fails the Python wheel
build). The `release.yml` guard therefore rejects anything that isn't plain
`vMAJOR.MINOR.PATCH`, failing fast instead of publishing half a release.

## When pdl ships a release with the C++ backend

The git pins become unnecessary. At that point we can:
1. point `PDL_REV` at the release (or reintroduce a version), and
2. switch the generated crate's `pdl-runtime` dep to the crates.io version,

which unblocks publishing Rust to **crates.io** directly (`cargo add x927`) and
makes the `rust-*` install tags optional. Until then, orphan tags are the move.
