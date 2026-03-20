#version 460
#pragma shader_stage(vertex)

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 model;
layout(location = 2) uniform mat4 view;
layout(location = 3) uniform mat4 proj;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
// layout(location = 2) in vec2 inTexCoord;

layout(location = 0) out vec3 fragColor;
// layout(location = 1) out vec2 fragTexCoord;

void main() {
    gl_Position = proj * view * model * vec4(inPosition, 1.0);
    // gl_Position = vec4(inPosition, 1.0) + vec4(0.1 * time, 0.0, 0.0, 0.0);
    fragColor = inColor;
}
