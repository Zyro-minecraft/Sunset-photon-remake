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
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 fogColor;
uniform float far;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

vec3 viewPos(vec2 uv, float depth) {
    vec4 n = vec4(uv, depth, 1.0) * 2.0 - 1.0;
    vec4 v = gbufferProjectionInverse * n;
    return v.xyz / v.w;
}

float shadowFactor(vec3 viewP, vec3 nView) {
    vec3 feet = (gbufferModelViewInverse * vec4(viewP, 1.0)).xyz;
    feet += (gbufferModelViewInverse * vec4(nView, 0.0)).xyz * 0.05; // normal offset bias
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

    vec3 vp = viewPos(texcoord, depth);
    vec3 viewDir = normalize(vp);
    vec3 sunDirView = normalize(sunPosition);
    vec3 sunDirWorld = normalize(mat3(gbufferModelViewInverse) * sunDirView);

    if (depth >= 1.0) {
        vec3 dirWorld = normalize(mat3(gbufferModelViewInverse) * viewDir);
        outColor = vec4(skyColor(dirWorld, sunDirWorld), 1.0);
        return;
    }

    vec3 albedo = albedoA.rgb;
    vec3 n = decodeNormal(data.xy);
    float blockL = data.z, skyL = data.w;

    vec3 lightDir = normalize(shadowLightPosition);
    float ndl = max(dot(n, lightDir), 0.0);
    float sh = ndl > 0.0 ? shadowFactor(vp, n) : 0.0;

    vec3 sunC = sunColor(sunDirWorld) * step(0.0, sunDirWorld.y + 0.1);
    vec3 direct = sunC * ndl * sh * skyL;
    vec3 ambientSky = skyColor(vec3(0.0, 1.0, 0.0), sunDirWorld) * 0.6 * pow(skyL, 2.0);
    vec3 blockLight = vec3(1.0, 0.62, 0.30) * pow(blockL, 3.0) * 1.5;
    vec3 color = albedo * (direct + ambientSky + blockLight + 0.02);

    // distance fog toward sky colour
    float dist = length(vp);
    float fog = 1.0 - exp(-pow(dist / far, 2.0) * 3.0);
    vec3 fogC = skyColor(normalize(mat3(gbufferModelViewInverse) * viewDir), sunDirWorld);
    color = mix(color, fogC, clamp(fog, 0.0, 1.0));

    outColor = vec4(color, albedoA.a);
}
