// Enchantment glint: additive on albedo only, never touches normals/materials.
#include "/lib/common.glsl"
uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 glcolor;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outAlbedo;
void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    outAlbedo = vec4(srgbToLinear(c.rgb) * vec3(1.0, 0.4, 0.35), c.a); // glint turns blood-tinted
}
