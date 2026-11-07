#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;
uniform vec4 entityColor;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
flat in int blockId;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outData;
layout(location = 2) out vec4 outMat;

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
#ifdef G_WATER
    if (c.a < 0.02) discard;
#else
    if (c.a < alphaTestRef) discard;
#endif

    int mat = MAT_NONE;
#if defined G_TERRAIN || defined G_WATER
    if (blockId == 10001) mat = MAT_WATER;
    else if (blockId == 10010 || blockId == 10011) mat = MAT_PLANT;
    else if (blockId == 10012) mat = MAT_LEAVES;
    else if (blockId == 10020) mat = MAT_GLOW;
    else if (blockId == 10021) mat = MAT_LAVA;
#elif defined G_ENTITIES
    mat = MAT_ENTITY;
    c.rgb = mix(c.rgb, entityColor.rgb, entityColor.a); // hurt / creeper flash
#elif defined G_HAND
    mat = MAT_HAND;
#elif defined G_TEXTURED
    mat = MAT_PARTICLE;
#endif
#ifdef G_WATER
    if (mat == MAT_WATER) c.a = 1.0; // surface is fully shaded in composite
#endif

    outAlbedo = vec4(srgbToLinear(c.rgb), c.a);
    outData = vec4(encodeNormal(normalize(normal)), lmcoord.x, lmcoord.y);
    outMat = vec4(encodeMat(mat), 0.0, 0.0, 1.0);
}
