#ifndef DIMS_GLSL
#define DIMS_GLSL
// Per-dimension sky, fog and ambient. Exactly one of DIM_OVERWORLD / DIM_NETHER / DIM_END is
// defined by the wrapper program in /, /world-1 or /world1.
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/noise.glsl"
#include "/lib/sky.glsl"

uniform float rainStrength;
uniform vec3 fogColor;

// ---------------- The End: a dead, eclipsed sun hanging over the void ----------------
const vec3 END_ECLIPSE_DIR = vec3(-0.35, 0.42, 0.84);

vec3 endSky(vec3 d, float t) {
    vec3 e = normalize(END_ECLIPSE_DIR);
    float up = d.y * 0.5 + 0.5;
    vec3 col = mix(vec3(0.004, 0.002, 0.007), vec3(0.025, 0.010, 0.040), pow(up, 1.5));
    // faint dying stars
    vec2 sp = vec2(atan(d.z, d.x) * 60.0, d.y * 120.0);
    float star = step(0.995, hash12(floor(sp)));
    col += vec3(0.6, 0.5, 0.8) * star * (0.4 + 0.6 * sin(t * 2.0 + hash12(floor(sp) + 3.0) * 30.0)) * 0.08;
    // eclipse: black disk with a violet-white corona that writhes
    float mu = dot(d, e);
    float ang = acos(clamp(mu, -1.0, 1.0));
    float r = 0.09;
    vec3 T = normalize(cross(e, vec3(0.0, 1.0, 0.0001)));
    vec2 q = vec2(dot(d, T), dot(d, cross(T, e)));
    float flare = fbm(normalize(q + 1e-6) * 2.5 + vec2(t * 0.05, -t * 0.03));
    float corona = exp(-max(ang - r, 0.0) / (r * (0.15 + 1.2 * flare * flare)));
    col += vec3(0.55, 0.35, 1.0) * corona * 1.6 + vec3(0.25, 0.1, 0.5) * pow(max(mu, 0.0), 12.0) * 0.4;
    col *= smoothstep(r * 0.985, r * 1.01, ang); // the black disk itself
    return col;
}

// Sky as seen in direction d (world space).
vec3 dimSky(vec3 d, vec3 sunW, float t) {
#if defined DIM_NETHER
    return srgbToLinear(fogColor) * 1.1;
#elif defined DIM_END
    return endSky(d, t);
#else
    vec3 col = skyFull(d, sunW, t);
    // Rain: ash-grey overcast swallows the sun
    vec3 overcast = skyBase(vec3(d.x, max(d.y, 0.0) * 0.3, d.z), sunW) * 0.5 + vec3(0.012, 0.010, 0.010);
    return mix(col, overcast, rainStrength * 0.85);
#endif
}

// Colour the air fades into, looking along d.
vec3 dimFog(vec3 d, vec3 sunW) {
#if defined DIM_NETHER
    // smouldering haze, a little brighter low down where the lava seas are
    return srgbToLinear(fogColor) * (1.1 + 0.6 * smoothstep(0.2, -0.4, d.y)) + vec3(0.012, 0.003, 0.002);
#elif defined DIM_END
    return vec3(0.012, 0.006, 0.02);
#else
    vec3 fd = normalize(vec3(d.x, clamp(d.y, 0.0, 0.1), d.z));
    vec3 f = skyBase(fd, sunW) * 0.6;
    return mix(f, vec3(luma(f)) * 0.8 + vec3(0.01, 0.008, 0.008), rainStrength * 0.6);
#endif
}

// Fog amount for a surface dist blocks away (far = render distance).
float dimFogAmount(float dist, float farPlane) {
#if defined DIM_NETHER
    float f = 1.0 - exp(-dist * 0.018 * FOG_DENSITY);
#elif defined DIM_END
    float f = 1.0 - exp(-dist * 0.008 * FOG_DENSITY);
#else
    float f = 1.0 - exp(-dist * (0.006 + 0.012 * rainStrength) * FOG_DENSITY);
#endif
    return clamp(max(f, smoothstep(0.65, 1.0, dist / farPlane)), 0.0, 1.0);
}
#endif
