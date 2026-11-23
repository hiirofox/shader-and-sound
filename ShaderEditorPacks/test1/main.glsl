#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 resolution;
uniform sampler2D iChannel0;

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    // 采样 buffer.glsl 输出的纹理
    vec4 bufferColor = texture2D(iChannel0, uv);

    gl_FragColor = vec4(bufferColor.rgb, 1.0);
}