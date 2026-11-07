// Shared vertex stage for gbuffers. Wrapper defines one of:
// G_TERRAIN, G_WATER, G_TEXTURED, G_ENTITIES, G_HAND, G_BLOCK
#include "/lib/settings.glsl"
#include "/lib/waving.glsl"

in vec4 mc_Entity;
in vec2 mc_midTexCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
flat out int blockId;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vec2 lm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = clamp((lm - 1.0 / 32.0) * 16.0 / 15.0, 0.0, 1.0);
    glcolor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
    blockId = 0;
    vec4 viewP = gl_ModelViewMatrix * gl_Vertex;

#if defined G_TERRAIN || defined G_WATER
    blockId = int(mc_Entity.x + 0.5);
#endif
#if defined G_TERRAIN && defined WAVING_PLANTS
    if (blockId >= 10010 && blockId <= 10012) {
        vec3 feet = (gbufferModelViewInverse * viewP).xyz;
        feet += waveOffset(feet + cameraPosition, blockId, texcoord.y < mc_midTexCoord.y, frameTimeCounter, rainStrength);
        viewP = gbufferModelView * vec4(feet, 1.0);
    }
#endif
    gl_Position = gl_ProjectionMatrix * viewP;
}
