#version 330 compatibility
uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 glcolor;

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.1) discard;
    gl_FragData[0] = c;
}
