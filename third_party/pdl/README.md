# Vendored: packet_runtime.h

`packet_runtime.h` is the C++ runtime header that the pdl-generated C++ code
`#include`s. It's vendored here so C++ release artifacts are self-contained and
reproducible without a network fetch at build time.

- **Source:** https://github.com/google/pdl — `pdl-compiler/scripts/packet_runtime.h`
- **Version:** matches the compiler pinned in `/PDL_VERSION` (currently 0.5.2)
- **License:** Apache-2.0 (license header retained in the file)

When you bump `PDL_VERSION`, refresh this file from the matching upstream tag:

```sh
curl -fsSL \
  https://raw.githubusercontent.com/google/pdl/main/pdl-compiler/scripts/packet_runtime.h \
  -o third_party/pdl/packet_runtime.h
```
