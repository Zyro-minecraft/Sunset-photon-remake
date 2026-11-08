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
    // faint dying stars: tiny round points, slowly flickering
    vec2 sp = vec2(atan(d.z, d.x), asin(clamp(d.y, -1.0, 1.0))) * 260.0;
    vec2 cell = floor(sp);
    float star = step(0.996, hash12(cell)) * smoothstep(0.3, 0.0, length(fract(sp) - 0.5));
    col += vec3(0.75, 0.65, 1.0) * star * (0.5 + 0.5 * sin(t * 1.5 + hash12(cell + 3.0) * 30.0)) * 0.35;
    // eclipse: black disk with a violet-white corona that writhes
    float mu = dot(d, e);
    float ang = acos(clamp(mu, -1.0, 1.0));
    float r = 0.09;
    vec3 T = normalize(cross(e, vec3(0.0, 1.0, 0.0001)));
    vec2 q = vec2(dot(d, T), dot(d, cross(T, e)));
    float flare = fbm(normalize(q + 1e-6) * 2.5 + vec2(t * 0.05, -t * 0.03));
    float corona = exp(-max(ang - r, 0.0) / (r * (0.15 + 1.2 * flare * flare)));
    col += vec3(0.55, 0.35, 1.0) * corona * 1.6 + vec3(0.25, 0.1, 0.5) * pow(max(mu, 0.0), 12.0) * 0.4;
    // slow violet nebulae drifting around the dead sun
    vec2 nuv = d.xz / (abs(d.y) + 0.35) * 0.7 + vec2(t * 0.004, -t * 0.003);
    float neb = fbm(nuv) * 0.65 + fbm(nuv * 2.7 + 11.0) * 0.35;
    float nebMask = smoothstep(0.42, 0.85, neb) * (0.35 + 0.65 * pow(max(mu, 0.0) * 0.5 + 0.5, 3.0));
    col += mix(vec3(0.05, 0.015, 0.09), vec3(0.16, 0.05, 0.22), neb) * nebMask * 1.3;
    // the void below glows faintly, like something breathing down there
    col += vec3(0.05, 0.015, 0.08) * smoothstep(0.0, -0.6, d.y) * (0.7 + 0.3 * sin(t * 0.4));
    col *= smoothstep(r * 0.985, r * 1.01, ang); // the black disk itself
    return col;
}

// Sky as seen in direction d (world space).
vec3 dimSky(vec3 d, vec3 sunW, float t) {
#if defined DIM_NETHER
    return srgbToLinear(fogColor) * 2.4;
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
    // the biome's own haze (crimson, warped teal, soul blue, basalt grey), brighter looking down
    // toward the lava seas
    float down = smoothstep(0.2, -0.5, d.y);
    return srgbToLinear(fogColor) * (2.2 + 1.5 * down) + vec3(0.05, 0.010, 0.0) * down + vec3(0.012, 0.003, 0.002);
#elif defined DIM_END
    // violet void mist, glowing more toward the abyss below the islands
    return mix(vec3(0.014, 0.007, 0.024), vec3(0.05, 0.016, 0.08), smoothstep(0.1, -0.6, d.y));
#else
    vec3 fd = normalize(vec3(d.x, clamp(d.y, 0.0, 0.1), d.z));
    vec3 f = skyBase(fd, sunW) * 0.6;
    return mix(f, vec3(luma(f)) * 0.8 + vec3(0.01, 0.008, 0.008), rainStrength * 0.6);
#endif
}

// Fog amount for a surface dist blocks away (far = render distance).
// worldY = height of the surface, eyeY = height of the camera.
float dimFogAmount(float dist, float farPlane, float worldY, float eyeY) {
    float avgY = 0.5 * (worldY + eyeY);
#if defined DIM_NETHER
    // thick glowing haze hangs over the lava seas (y ~ 31) and thins out higher up
    float lavaHaze = exp(-max(avgY - 31.0, 0.0) / 12.0);
    float f = 1.0 - exp(-dist * (0.012 + 0.03 * lavaHaze) * FOG_DENSITY);
#elif defined DIM_END
    // void mist pools below the islands
    float voidMist = exp(-max(avgY - 40.0, 0.0) / 15.0);
    float f = 1.0 - exp(-dist * (0.006 + 0.02 * voidMist) * FOG_DENSITY);
#else
    float f = 1.0 - exp(-dist * (0.006 + 0.012 * rainStrength) * FOG_DENSITY);
#endif
    return clamp(max(f, smoothstep(0.65, 1.0, dist / farPlane)), 0.0, 1.0);
}
#endif
