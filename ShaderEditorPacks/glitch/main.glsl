#extension GL_OES_EGL_image_external : require
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
uniform vec2 resolution;
uniform vec2 cameraAddent;
uniform mat2 cameraOrientation;
uniform samplerExternalOES cameraBack;
uniform sampler2D backbuffer;
uniform float time;
uniform vec2 mouse;
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float tick = floor(time * 10.0);
    float burst = step(0.55, hash(vec2(tick, 10.0)));
    float row = floor(uv.y * 55.0);
    float stripe = step(0.60, hash(vec2(row, tick)));
    float offset = (hash(vec2(row + 31.0, tick)) - 0.5) * 0.22 * stripe * burst;
    float line = step(0.94, hash(vec2(floor(uv.y * resolution.y / 3.0), floor(time * 23.0)))) * 0.025 * burst;
    float block = step(0.82, hash(vec2(floor(uv.x * 12.0) + tick, floor(uv.y * 16.0)))) * burst;
    vec2 distorted = uv + vec2(offset + line, 0.0);
    distorted = mix(distorted, (floor(distorted * vec2(160.0, 90.0)) + 0.5) / vec2(160.0, 90.0), block);
    float split = 0.0015 + 0.014 * stripe * burst;
    vec2 redUV = clamp(distorted + vec2(split, 0.0), 0.001, 0.999);
    vec2 greenUV = clamp(distorted, 0.001, 0.999);
    vec2 blueUV = clamp(distorted - vec2(split, 0.0), 0.001, 0.999);
    vec2 redST = cameraAddent + redUV * cameraOrientation;
    vec2 greenST = cameraAddent + greenUV * cameraOrientation;
    vec2 blueST = cameraAddent + blueUV * cameraOrientation;
    float r = texture2D(cameraBack, redST).r;
    float g = texture2D(cameraBack, greenST).g;
    float b = texture2D(cameraBack, blueST).b;
    vec3 color = vec3(r, g, b);
    float noise = (hash(floor(gl_FragCoord.xy) + tick * 13.0) - 0.5) * (0.04 + 0.14 * burst * stripe);
    float scanline = 0.92 + 0.08 * sin(gl_FragCoord.y * 1.7 + time * 6.0);
    float dropout = 1.0 - 0.35 * block * step(0.6, hash(vec2(floor(uv.y * 16.0), tick)));
    float flicker = 0.96 + 0.04 * hash(vec2(floor(time * 30.0), 1.0));
    color = color * scanline * dropout * flicker + noise;
    color += vec3(0.03, 0.0, 0.06) * stripe * burst;
    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}