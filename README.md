# vyges-yosys

A Vyges-controlled, versioned, **reproducible distribution of Yosys** — the RTL
synthesis frontend for our digital flow — pinned at a commit and rebuilt from source,
as a relocatable `tar.gz` and a slim container. **Multi-arch (linux/amd64 + linux/arm64).**

- **Rebuild, never fork or vendor.** We build Yosys at a pinned commit — this repo
  holds only the *build recipe* (CI clones upstream recursively at build time). No patches.
- **Binary-first.** The relocatable bundle is the product; the container wraps the same bytes.
- **De-facto multi-arch build.** Native per-arch builds + digest-based manifest merge
  → clean tags only (`:sha-<short>` / `:<version>` / `:latest`, each multi-arch).
- **Images:** `ghcr.io/vyges-tools/vyges-yosys` · **Tarballs:** GitHub Releases.

## Use it

```sh
# tarball:
tar xzf vyges-yosys-0.66-g<short>-linux-x86_64.tar.gz
source vyges-yosys-0.66-g<short>/env.sh
yosys --version

# container:
docker run --rm ghcr.io/vyges-tools/vyges-yosys:latest yosys --version
```

## How it's built

`scripts/build-bundle.sh` builds Yosys (`make config-gcc && make`) at the pinned
commit and assembles the relocatable bundle. `Dockerfile.runtime` wraps the same
bundle. Workflows: `release.yml` (multi-arch, digest-based), `multiarch-check.yml`.

## Cut a release / bump the pin

Edit **`upstream.yaml`** (`commit`) — the source of truth — then run the `release`
workflow with a `version`.

## Licensing

Repository tooling (Dockerfile, scripts, workflows) is **Apache-2.0** (`LICENSE`).
The built artifact is **Yosys (ISC license)** — shipped as `LICENSE.yosys` in the bundle.
