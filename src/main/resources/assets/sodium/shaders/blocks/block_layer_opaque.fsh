#version 330 core

#import <sodium:include/fog.glsl>

in vec4 v_Color; // The interpolated vertex color
in vec2 v_TexCoord; // The interpolated block texture coordinates
in float v_FragDistance; // The fragment's distance from the camera
in vec3 v_DebugSectionColor; // DIAGNOSTIC: section position debug color

in float v_MaterialMipBias;
in float v_MaterialAlphaCutoff;

uniform sampler2D u_BlockTex; // The block texture

uniform vec4 u_FogColor; // The color of the shader fog
uniform float u_FogStart; // The starting position of the shader fog
uniform float u_FogEnd; // The ending position of the shader fog

out vec4 fragColor; // The output fragment for the color framebuffer

void main() {
    vec4 diffuseColor = texture(u_BlockTex, v_TexCoord, v_MaterialMipBias);

#ifdef USE_FRAGMENT_DISCARD
    if (diffuseColor.a < v_MaterialAlphaCutoff) {
        discard;
    }
#endif

    // Apply per-vertex color
    diffuseColor.rgb *= v_Color.rgb;

    // Apply ambient occlusion "shade"
    diffuseColor.rgb *= v_Color.a;

    // DIAGNOSTIC: Override with section debug color (50% blend with texture so we can still see block shapes)
    diffuseColor.rgb = mix(diffuseColor.rgb, v_DebugSectionColor, 0.7);

    fragColor = _linearFog(diffuseColor, v_FragDistance, u_FogColor, u_FogStart, u_FogEnd);
}