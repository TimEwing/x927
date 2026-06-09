#!/usr/bin/env bash
# Generate the Rust / Python / C++ codecs from the .pdl spec.
#
# Single source of truth for code generation: used by CI, by the release
# workflow, and locally if you happen to have rust installed. You do NOT need
# rust to use x927 — grab a prebuilt artifact from the GitHub Releases page.
#
# We pin pdlc to a specific google/pdl commit (PDL_REV) rather than a crates.io
# release because the C++ ('cxx') backend isn't in any published release yet —
# it only exists on the main branch. The pinned sha keeps builds reproducible.
#
# Output lands in build/ (gitignored), one ready-to-consume tree per language.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PDL_REV="$(cat PDL_REV)"
PDL_REPO="https://github.com/google/pdl"
SPEC="spec/x927.pdl"
NAME="x927"
OUT="build"

# pdlc is the pdl compiler. Install it from the pinned commit if missing.
if ! command -v pdlc >/dev/null 2>&1; then
    if command -v cargo >/dev/null 2>&1; then
        echo ">> pdlc not found; installing pdl-compiler @ ${PDL_REV} via cargo"
        cargo install --git "${PDL_REPO}" --rev "${PDL_REV}" pdl-compiler
    else
        echo "error: pdlc not on PATH and cargo unavailable." >&2
        echo "       this is normally run in CI. to run locally, install rust first." >&2
        exit 1
    fi
fi

echo ">> generating ${NAME} codecs with $(pdlc --version 2>/dev/null || echo pdlc)"

rm -rf "${OUT}"
mkdir -p "${OUT}/rust/src" "${OUT}/python/${NAME}" "${OUT}/cxx/include"

# --- Rust: a self-contained crate -------------------------------------------
# pdl-runtime is pinned to the SAME commit as the compiler so the generated
# code matches the runtime API (main may have drifted from the 0.5.2 crate).
pdlc "${SPEC}" --output-format rust > "${OUT}/rust/src/lib.rs"
cat > "${OUT}/rust/Cargo.toml" <<EOF
[package]
name = "${NAME}"
version = "0.0.0"   # stamped from the git tag at release time
edition = "2021"
description = "Generated x927 packet codec"
license = "MIT"

[dependencies]
pdl-runtime = { git = "${PDL_REPO}", rev = "${PDL_REV}" }
bytes = "1"
EOF

# --- Python: stdlib-only module ---------------------------------------------
pdlc "${SPEC}" --output-format python > "${OUT}/python/${NAME}/__init__.py"
cat > "${OUT}/python/pyproject.toml" <<EOF
[build-system]
requires = ["setuptools>=61"]
build-backend = "setuptools.build_meta"

[project]
name = "${NAME}"
version = "0.0.0"
description = "Generated x927 packet codec"
requires-python = ">=3.8"
EOF

# --- C++: generated header + vendored runtime header ------------------------
pdlc "${SPEC}" --output-format cxx > "${OUT}/cxx/include/${NAME}.h"
cp third_party/pdl/packet_runtime.h "${OUT}/cxx/include/packet_runtime.h"

echo ">> done -> ${OUT}/"
