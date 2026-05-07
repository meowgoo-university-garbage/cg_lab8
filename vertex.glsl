#version 460
#pragma shader_stage(vertex)

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 model;
layout(location = 2) uniform mat4 view;
layout(location = 3) uniform mat4 proj;
layout(location = 4) uniform vec3 camera;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inNormal;
layout(location = 3) in vec2 inTexCoord;

layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragTexCoord;
layout(location = 2) out vec3 fragPos;
layout(location = 3) out vec3 fragNormal;
layout(location = 4) out vec3 fragCamera;

void main() {
    gl_Position = proj * view * model * vec4(inPosition, 1.0);

    fragColor = inColor;
    fragTexCoord = inTexCoord;
    fragPos = inPosition;
    fragNormal = normalize(inNormal);
    fragCamera = camera;
}
