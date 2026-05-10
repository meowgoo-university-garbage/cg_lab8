#version 460
#pragma shader_stage(fragment)

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 fragTexCoord;
layout(location = 2) in vec3 fragPos;
layout(location = 3) in vec3 fragNormal;
layout(location = 4) in vec3 fragCamera;
layout(location = 5) in vec4 fragLightPos;

layout(location = 10) uniform sampler2D tex;
layout(location = 11) uniform sampler2D depth;

layout(location = 0) out vec4 outColor;

void main() {
    vec2 depthCoords = (fragLightPos.xyz / fragLightPos.w).xy * 0.5 + 0.5;
    float sampledDepth = texture(depth, depthCoords).r;
    float actualDepth = (fragLightPos.xyz / fragLightPos.w).z * 0.5 + 0.5;

    float shadow = actualDepth - 0.0005 > sampledDepth ? 1 : 0;
    if(actualDepth > 1.0 || actualDepth < 0) {
        shadow = 1;
    }

    float illumination = (1 - shadow) * 0.8 + 0.2;

    vec4 c = texture(tex, fragTexCoord.xy);
    outColor = vec4(c.xyz * illumination, 1.0);

    // outColor = vec4(sampledDepth, 0, 0, 1);
    // outColor = vec4(texture(depth, fragTexCoord).r, 0, 0, 1);
    // outColor = vec4(pow(c.r, 5), 0, 0, 1);
}
