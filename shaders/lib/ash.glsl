#ifndef ASH_GLSL
#define ASH_GLSL
#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

// World-anchored ash flakes and embers. Each shell along the view ray picks the grid cell it
// passes through; the flake inside that cell is drawn as a soft point by its true distance to
// the ray, so flakes stay put in 3D instead of sliding with the camera.
// Returns rgb = emitted light (embers), a = ash coverage.
vec4 ashParticles(vec3 camPos, vec3 dir, float sceneDist, float t, float density) {
    const float S = 1.7;
    const int N = 12;
    vec3 drift = vec3(t * 0.55, t * 0.8, t * 0.2); // wind pushes them along, ash slowly falls
    vec3 o = camPos + drift;
    vec3 emit = vec3(0.0);
    float cover = 0.0;
    for (int k = 0; k < N; k++) {
        float d = S * (float(k) + 0.5);
        if (d > sceneDist) break;
        vec3 p = o + dir * d;
        vec3 cell = floor(p / S);
        vec3 h = hash33(cell);
        if (h.x > 0.30 * density) continue;
        vec3 wob = vec3(sin(t * 1.3 + h.y * 40.0), sin(t * 0.9 + h.z * 30.0), cos(t * 1.1 + h.x * 50.0)) * 0.18;
        vec3 fp = (cell + 0.25 + 0.5 * hash33(cell + 7.0)) * S + wob;
        vec3 v = fp - o;
        float along = dot(v, dir);
        if (along < 0.3 || along > sceneDist) continue;
        float pd = length(v - dir * along);
        bool ember = h.y < 0.12;
        float rad = ember ? 0.025 : 0.04;
        float a = 1.0 - smoothstep(rad * 0.35, rad, pd);
        a *= smoothstep(0.3, 1.5, along) * (1.0 - smoothstep(14.0, 20.0, along));
        if (ember) emit += vec3(1.0, 0.22, 0.04) * a * (3.0 + 3.0 * sin(t * 7.0 + h.z * 60.0));
        else cover += a * 0.85;
    }
    return vec4(emit, clamp(cover, 0.0, 1.0));
}
#endif
