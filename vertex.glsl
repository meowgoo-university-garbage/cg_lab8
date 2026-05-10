#version 460
#pragma shader_stage(vertex)

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 model;

layout(location = 2) uniform mat4 view;
layout(location = 3) uniform mat4 proj;

layout(location = 4) uniform mat4 light_view;
layout(location = 5) uniform mat4 light_proj;

layout(location = 6) uniform vec3 camera;



layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inNormal;
layout(location = 3) in vec2 inTexCoord;



layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragTexCoord;
layout(location = 2) out vec3 fragPos;
layout(location = 3) out vec3 fragNormal;
layout(location = 4) out vec3 fragCamera;
layout(location = 5) out vec4 fragLightPos;

void main() {
    vec4 pos = proj * view * model * vec4(inPosition, 1.0);
    vec4 lightPos = light_proj * light_view * model * vec4(inPosition, 1.0);

    fragColor = inColor;
    fragTexCoord = inTexCoord;
    fragPos = pos.xyz;
    fragNormal = normalize(inNormal);
    fragCamera = camera;
    fragLightPos = lightPos;

    gl_Position = pos;
}
