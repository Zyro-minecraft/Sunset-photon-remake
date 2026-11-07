#ifndef SKY_GLSL
#define SKY_GLSL
#include "/lib/settings.glsl"

// Sunset-style analytic sky: blue zenith blending to warm orange near the sun at low elevation.
vec3 skyColor(vec3 dir, vec3 sunDir) {
    float up = clamp(dir.y, 0.0, 1.0);
    float sunElev = sunDir.y;
    float sunset = (1.0 - smoothstep(0.0, 0.45, abs(sunElev))) * SUNSET_STRENGTH;
    vec3 zenith = mix(vec3(0.08, 0.20, 0.55), vec3(0.12, 0.10, 0.32), sunset);
    vec3 horizon = mix(vec3(0.55, 0.72, 0.95), vec3(1.10, 0.45, 0.18), sunset);
    vec3 sky = mix(horizon, zenith, pow(up, 0.5));
    float sd = max(dot(dir, sunDir), 0.0);
    sky += vec3(1.0, 0.55, 0.25) * pow(sd, 6.0) * sunset;
    sky += vec3(1.0, 0.9, 0.7) * pow(sd, 800.0) * 20.0;
    return sky * smoothstep(-0.25, 0.1, sunElev + 0.2);
}

vec3 sunColor(vec3 sunDir) {
    float sunset = (1.0 - smoothstep(0.0, 0.45, abs(sunDir.y))) * SUNSET_STRENGTH;
    return mix(vec3(1.0, 0.95, 0.85) * 3.0, vec3(1.0, 0.45, 0.15) * 2.5, sunset);
}
#endif
