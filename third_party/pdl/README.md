# Vendored: packet_runtime.h

`packet_runtime.h` is the C++ runtime header that the pdl-generated C++ code
`#include`s. It's vendored here so C++ release artifacts are self-contained and
reproducible without a network fetch at build time.

- **Source:** https://github.com/google/pdl — `pdl-compiler/scripts/packet_runtime.h`
- **Version:** matches the commit pinned in `/PDL_REV`
- **License:** Apache-2.0 (license header retained in the file)

When you bump `PDL_REV`, refresh this file from the matching commit:

```sh
curl -fsSL \
  "https://raw.githubusercontent.com/google/pdl/$(cat PDL_REV)/pdl-compiler/scripts/packet_runtime.h" \
  -o third_party/pdl/packet_runtime.h
```
