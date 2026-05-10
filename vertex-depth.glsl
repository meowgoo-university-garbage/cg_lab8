#version 460
#pragma shader_stage(vertex)

layout(location = 0) uniform mat4 model;
layout(location = 1) uniform mat4 view;
layout(location = 2) uniform mat4 proj;

layout(location = 0) in vec3 inPosition;

void main() {
    gl_Position = proj * view * model * vec4(inPosition, 1.0);
}
