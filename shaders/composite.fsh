#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 sunPosition;
uniform float far;
uniform float frameTimeCounter;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

vec3 viewPos(vec2 uv, float depth) {
    vec4 v = gbufferProjectionInverse * (vec4(uv, depth, 1.0) * 2.0 - 1.0);
    return v.xyz / v.w;
}

float shadowFactor(vec3 viewP, vec3 nView) {
    vec3 feet = (gbufferModelViewInverse * vec4(viewP, 1.0)).xyz;
    feet += mat3(gbufferModelViewInverse) * nView * 0.05;
    vec4 sp = shadowProjection * (shadowModelView * vec4(feet, 1.0));
    sp.xy /= (0.9 * length(sp.xy) + 0.1);
    vec3 coord = sp.xyz * 0.5 + 0.5;
    if (any(lessThan(coord.xy, vec2(0.0))) || any(greaterThan(coord.xy, vec2(1.0)))) return 1.0;
    float texel = SHADOW_SOFTNESS / float(shadowMapResolution);
    float s = 0.0;
    for (int x = -1; x <= 1; x++)
        for (int y = -1; y <= 1; y++)
            s += step(coord.z - 0.0006, texture(shadowtex1, coord.xy + vec2(x, y) * texel).r);
    return s / 9.0;
}

void main() {
    vec4 albedoA = texture(colortex0, texcoord);
    vec4 data = texture(colortex1, texcoord);
    float depth = texture(depthtex0, texcoord).r;
    float t = frameTimeCounter;

    vec3 vp = viewPos(texcoord, depth);
    vec3 dirWorld = normalize(mat3(gbufferModelViewInverse) * normalize(vp));
    vec3 sunW = getSunDirWorld(normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition)));

    if (depth >= 1.0) { outColor = vec4(skyFull(dirWorld, sunW, t), 1.0); return; }

    vec3 albedo = albedoA.rgb;
    vec3 n = decodeNormal(data.xy);
    float blockL = data.z, skyL = data.w;

    // Low, blood-red sun: only faces turned toward it catch light, everything else falls into black.
    vec3 sunV = mat3(gbufferModelView) * sunW;
    float ndl = max(dot(n, sunV), 0.0);
    float sh = ndl > 0.0 ? shadowFactor(vp, n) : 0.0;
    vec3 direct = sunLightColor() * ndl * sh * skyL;

    vec3 ambient = skyBase(normalize(vec3(sunW.x, 0.25, sunW.z)), sunW) * 0.25 * pow(skyL, 2.0)
                 + vec3(0.09, 0.05, 0.05) * pow(skyL, 2.0);
    // Torches are the only refuge: warm, small radius, nervous flicker.
    float flicker = 0.92 + 0.08 * vnoise(vec2(t * 9.0, 0.0));
    vec3 blockLight = vec3(1.0, 0.48, 0.18) * pow(blockL, 4.5) * 2.2 * flicker;

    // Minimum light mostly for dark places, so silhouettes stay readable in caves.
    vec3 minLight = MIN_LIGHT * vec3(1.0, 0.82, 0.82) * (1.0 - 0.75 * skyL);
    vec3 color = albedo * (direct + ambient + blockLight + minLight);

    // Choking ash fog: black away from the sun, smoldering red toward it.
    float dist = length(vp);
    float fog = 1.0 - exp(-dist * 0.006 * FOG_DENSITY);
    fog = max(fog, smoothstep(0.6, 1.0, dist / far));
    vec3 fogDir = normalize(vec3(dirWorld.x, clamp(dirWorld.y, 0.0, 0.1), dirWorld.z));
    vec3 fogC = skyBase(fogDir, sunW) * 0.6;
    color = mix(color, fogC, clamp(fog, 0.0, 1.0));

    outColor = vec4(color, albedoA.a);
}
