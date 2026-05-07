#version 460
#pragma shader_stage(fragment)

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 fragTexCoord;
layout(location = 2) in vec3 fragPos;
layout(location = 3) in vec3 fragNormal;
layout(location = 4) in vec3 fragCamera;

layout(location = 0) out vec4 outColor;

void main() {
    float kd = 0.5;
    float ks = 0.5;
    float alpha = 2;

    vec3 color = vec3(0, 0, 0);

    {
        vec3 lightPos = vec3(0, 0, 10);

        vec3 lightColor = vec3(0.5, 0.5, 1);
        float lightIntensity = 0.8;
        float lightIntensitySpecular = 0.5;

        vec3 L = normalize(lightPos - fragPos);

        float id = (kd * dot(L, fragNormal) * lightIntensity);
        if(id > 0) {
            color += id * lightColor;
        }

        vec3 R = 2 * dot(L, fragNormal) * fragNormal - L;
        float is = ks * pow(dot(normalize(R), normalize(fragCamera - fragPos)), alpha) * lightIntensitySpecular;
        if(is > 0) {
            color += is * lightColor;
        }
    }


    {
        vec3 lightPos = vec3(0, 5, -10);

        vec3 lightColor = vec3(1, 0, 0);
        float lightIntensity = 0.5;
        float lightIntensitySpecular = 0.5;

        vec3 L = normalize(lightPos - fragPos);

        float id = (kd * dot(L, fragNormal) * lightIntensity);
        if(id > 0) {
            color += id * lightColor;
        }

        vec3 R = 2 * dot(L, fragNormal) * fragNormal - L;
        float is = ks * pow(dot(normalize(R), normalize(fragCamera - fragPos)), alpha) * lightIntensitySpecular;
        if(is > 0) {
            color += is * lightColor;
        }
    }

    outColor = vec4(color, 1.0);
}
