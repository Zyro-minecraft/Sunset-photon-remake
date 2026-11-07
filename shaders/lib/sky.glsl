#ifndef SKY_GLSL
#define SKY_GLSL
#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

// World-space direction of the dying sun. With FROZEN_SUN the elevation is pinned near the
// horizon regardless of game time (pair with /gamerule doDaylightCycle false so shadows match).
vec3 getSunDirWorld(vec3 realSunWorld) {
#ifdef FROZEN_SUN
    vec2 az = realSunWorld.xz;
    az = length(az) < 1e-3 ? vec2(1.0, 0.0) : normalize(az);
    float e = SUN_ELEVATION;
    return normalize(vec3(az.x * cos(e), sin(e), az.y * cos(e)));
#else
    return realSunWorld;
#endif
}

// Gradient only (used for fog/ambient): bleeding horizon, ash-black everywhere else.
vec3 skyBase(vec3 d, vec3 s) {
    float toward = dot(d, s) * 0.5 + 0.5;
    float up = clamp(d.y, 0.0, 1.0);
    float sunSide = pow(toward, 6.0);
    vec3 zen = vec3(0.035, 0.012, 0.016);
    vec3 mid = vec3(0.09, 0.008, 0.006);
    vec3 hor = vec3(0.60, 0.045, 0.010);
    vec3 col = mix(zen, mid, exp(-up * 2.5) * (0.25 + 0.75 * sunSide));
    col += hor * exp(-up * 6.0) * (0.05 + 0.95 * sunSide * sunSide);
    col = mix(col, vec3(0.02, 0.008, 0.008), smoothstep(0.0, 0.15, -d.y));
    return col;
}

vec3 skyFull(vec3 d, vec3 s, float t) {
    vec3 col = skyBase(d, s);
    float mu = dot(d, s);
    float toward = mu * 0.5 + 0.5;
    float ang = acos(clamp(mu, -1.0, 1.0));
    float r = SUN_SIZE;

    // Tangent frame around the sun for disk/corona detail
    vec3 T = normalize(cross(s, vec3(0.0, 1.0, 0.0001)));
    vec3 B = cross(T, s);
    vec2 q = vec2(dot(d, T), dot(d, B));

    // Bloated, bleeding sun with sunspots and limb darkening
    if (ang < r * 1.02) {
        float x = clamp(ang / r, 0.0, 1.0);
        float limb = sqrt(1.0 - x * x);
        vec3 disk = mix(vec3(0.55, 0.02, 0.004), vec3(1.0, 0.16, 0.03), limb) * (1.2 + 2.0 * limb);
        float spots = smoothstep(0.32, 0.62, fbm(q / r * 3.5 + t * 0.02));
        disk *= mix(0.15, 1.0, spots);
        col = mix(col, disk, 1.0 - smoothstep(0.96, 1.02, x));
    }
    // Writhing corona / solar flares
    vec2 rd = normalize(q + 1e-6);
    float flare = fbm(rd * 2.5 + vec2(t * 0.11, -t * 0.07));
    float corona = exp(-max(ang - r, 0.0) / (r * (0.25 + 1.6 * flare * flare)));
    col += vec3(1.0, 0.06, 0.012) * corona * 1.2;
    col += vec3(0.7, 0.05, 0.01) * pow(max(mu, 0.0), 30.0) * 0.6;

    // Ash clouds drifting across the sky, rims lit blood-red toward the sun
    if (d.y > 0.0) {
        vec2 uv = d.xz / (d.y + 0.08) * 1.2 + vec2(t * 0.008, t * 0.003);
        float n = fbm(uv);
        float n2 = fbm(uv * 2.3 - t * 0.01);
        float cover = smoothstep(0.30, 0.70, n * 0.7 + n2 * 0.4);
        vec3 lit = vec3(0.7, 0.05, 0.01) * pow(toward, 10.0) * pow(1.0 - n2, 2.0);
        vec3 cloud = vec3(0.014, 0.006, 0.006) + lit;
        float nearSun = exp(-max(ang - r, 0.0) * 25.0);
        col = mix(col, cloud, cover * smoothstep(0.0, 0.08, d.y) * (0.95 - 0.5 * nearSun));
    }
    return col;
}

vec3 sunLightColor() { return vec3(1.0, 0.075, 0.018) * 1.2; }
#endif
