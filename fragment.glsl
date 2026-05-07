#version 460
#pragma shader_stage(fragment)

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 fragTexCoord;
layout(location = 2) in vec3 fragPos;
layout(location = 3) in vec3 fragNormal;
layout(location = 4) in vec3 fragCamera;

layout(location = 5) uniform sampler2D tex;

layout(location = 0) out vec4 outColor;

void main() {
    vec4 c = texture(tex, fragTexCoord.xy);
    outColor = vec4(c.xyz, 1.0);
}
