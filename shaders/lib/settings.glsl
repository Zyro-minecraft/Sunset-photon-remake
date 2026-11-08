#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

// ---- Shadows ----
#define SHADOW_RES 2048 // [1024 2048 4096]
const int shadowMapResolution = SHADOW_RES;
const float shadowDistance = 128.0;
const float sunPathRotation = -20.0;
#define SHADOW_SOFTNESS 1.5 // [0.5 1.0 1.5 2.0 3.0]

// ---- The frozen sun ----
#define FROZEN_SUN // Sky/light always use a dying sun stuck on the horizon
#define SUN_ELEVATION 0.06 // [0.0 0.03 0.06 0.1 0.15 0.2]
#define SUN_SIZE 0.08 // [0.03 0.05 0.08 0.12 0.16]
#define GODRAYS_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]
#define GODRAY_SAMPLES 32 // [16 24 32 48 64]

// ---- Atmosphere ----
#define FOG_DENSITY 1.0 // [0.25 0.5 1.0 1.5 2.0 3.0]
#define MIN_LIGHT 0.08 // [0.0 0.02 0.04 0.08 0.12 0.2]
#define CANOPY_DARKNESS 1.0 // [0.0 0.5 1.0 1.5 2.0] How little light gets under tree crowns

// ---- World ----
#define SSAO // Contact shadows in corners and crevices
#define AO_STRENGTH 1.0 // [0.5 1.0 1.5]
#define WAVING_PLANTS // Grass and leaves tremble in the hot wind
#define WAVE_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]
#define WATER_STYLE 0 // [0 1 2] 0 = blood, 1 = black oil, 2 = rusty ash water
#define EMISSIVE_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0 3.0]
#define HELD_LIGHT // Torches in hand light the world around you

// ---- Dread / sanity ----
#define DREAD_STRENGTH 1.0 // [0.0 0.5 1.0 1.5]
#define VIGNETTE_STRENGTH 1.0 // [0.0 0.5 1.0 1.5]
#define HEAT_HAZE 1.0 // [0.0 0.5 1.0 2.0]

// ---- Post ----
#define EXPOSURE 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define BLOOM_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]
#define GRAIN 1.0 // [0.0 0.5 1.0 2.0]
#define CHROMATIC 1.0 // [0.0 0.5 1.0 2.0]

// Buffer formats are read by the loader from this comment (not compiled):
/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA8;
const int colortex3Format = R8;
const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
*/

// Material ids written to colortex2.r
#define MAT_NONE     0
#define MAT_WATER    1
#define MAT_GLOW     2   // bright texels glow (torches, lanterns, glowstone...)
#define MAT_LAVA     3   // whole surface glows
#define MAT_ENTITY   4
#define MAT_HAND     5
#define MAT_WEATHER  6
#define MAT_PLANT    7
#define MAT_LEAVES   8
#define MAT_PARTICLE 9

#endif
