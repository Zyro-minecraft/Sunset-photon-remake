#version 330 compatibility
in vec4 glcolor;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;
// Sky is shaded analytically in composite (where depth == 1.0); discard vanilla sky.
void main() { discard; }
