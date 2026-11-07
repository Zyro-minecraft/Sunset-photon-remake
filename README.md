# Sunset Photon Remake

Remake of a Photon-style shader pack for **Minecraft 1.20.1 (Forge) + Oculus**.

Original GLSL, no code copied from other packs.

## Install
Zip the `shaders/` folder (so `shaders/` is at the zip root) and put it in `.minecraft/shaderpacks/`.

## Current pipeline
- `shadow` - distorted shadow map
- `gbuffers_terrain / textured` - albedo + normal + lightmap
- `gbuffers_skybasic` - vanilla sky discarded
- `composite` - analytic sunset sky, sun shadows (3x3 PCF), block light, fog
- `final` - ACES tonemap + exposure

## Roadmap
Water, clouds, volumetric light, SSAO, bloom, TAA, per-block materials.

## Validate GLSL locally
`glslangValidator -S frag|vert <file>` after inlining `#include`; `RGBA16F`/`RGB16` are loader macros.
