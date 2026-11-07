#ifndef SUN_GLSL
#define SUN_GLSL
#include "/lib/sky.glsl"
// Screen-space position of the (frozen) sun. w = 1 if in front of the camera.
vec3 sunScreen(vec3 sunPositionView, mat4 mvInv, mat4 mv, mat4 proj) {
    vec3 sw = getSunDirWorld(normalize(mat3(mvInv) * normalize(sunPositionView)));
    vec3 sv = mat3(mv) * sw;
    vec4 clip = proj * vec4(sv * 100.0, 1.0);
    if (clip.w <= 0.0) return vec3(0.5, 0.5, 0.0);
    return vec3(clip.xy / clip.w * 0.5 + 0.5, 1.0);
}
#endif
