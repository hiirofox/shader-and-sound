#extension GL_OES_EGL_image_external : require
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define QP_Y 42.0
#define GOP_FRAMES 100.
#define CODEC_FPS 60.
#define SEARCH_RANGE 58.0
uniform vec2 resolution;
uniform vec2 cameraAddent;
uniform mat2 cameraOrientation;
uniform samplerExternalOES cameraBack;
uniform sampler2D backbuffer;
uniform float time;
vec3 camera(vec2 uv) {
    return texture2D(cameraBack, cameraAddent + clamp(uv, 0.0, 1.0) * cameraOrientation).rgb;
}
vec3 previous(vec2 uv) {
    return texture2D(backbuffer, clamp(uv, 0.5 / resolution, 1.0 - 0.5 / resolution)).rgb;
}
vec3 rgb2ycc(vec3 c) {
    return vec3(dot(c, vec3(0.299, 0.587, 0.114)), dot(c, vec3(-0.168736, -0.331264, 0.5)), dot(c, vec3(0.5, -0.418688, -0.081312)));
}
vec3 ycc2rgb(vec3 c) {
    return vec3(c.x + 1.402 * c.z, c.x - 0.344136 * c.y - 0.714136 * c.z, c.x + 1.772 * c.y);
}
vec3 sourceAt(vec2 pixel) {
    return rgb2ycc(camera(pixel / resolution));
}
vec3 predictAt(vec2 pixel, vec2 motion, bool intra) {
    if (intra) return vec3(0.5, 0.0, 0.0);
    return rgb2ycc(previous((pixel + motion) / resolution));
}
vec3 residualAt(vec2 pixel, vec2 motion, bool intra) {
    return sourceAt(pixel) - predictAt(pixel, motion, intra);
}
vec3 displayedPrediction(vec2 pixel, vec2 motion, bool intra) {
    if (intra) return vec3(0.5, 0.0, 0.0);
    vec3 ycc = predictAt(pixel, motion, false);
    vec2 p = floor(pixel * 0.5) * 2.0;
    vec3 a = predictAt(p + vec2(0.5, 0.5), motion, false);
    vec3 b = predictAt(p + vec2(1.5, 0.5), motion, false);
    vec3 c = predictAt(p + vec2(0.5, 1.5), motion, false);
    vec3 d = predictAt(p + vec2(1.5, 1.5), motion, false);
    vec3 chroma = (a + b + c + d) * 0.25;
    return vec3(ycc.x, chroma.y, chroma.z);
}
vec4 forward4(vec4 x) {
    return vec4(x.x + x.y + x.z + x.w, 2.0 * x.x + x.y - x.z - 2.0 * x.w, x.x - x.y - x.z + x.w, x.x - 2.0 * x.y + 2.0 * x.z - x.w);
}
vec4 inverse4(vec4 x) {
    float a = x.x + x.z;
    float b = x.x - x.z;
    float c = 0.5 * x.y - x.w;
    float d = x.y + 0.5 * x.w;
    return vec4(a + d, b + c, b - c, a - d);
}
float chromaQP(float q) {
    if (q < 30.0) return q;
    if (q < 34.0) return q - 1.0;
    if (q < 35.0) return 32.0;
    if (q < 37.0) return q - 2.0;
    if (q < 38.0) return 34.0;
    if (q < 40.0) return 35.0;
    if (q < 42.0) return 36.0;
    if (q < 45.0) return 37.0;
    if (q < 48.0) return 38.0;
    return 39.0;
}
vec3 quantTableM(float r) {
    if (r < 0.5) return vec3(13107.0, 5243.0, 8066.0);
    if (r < 1.5) return vec3(11916.0, 4660.0, 7490.0);
    if (r < 2.5) return vec3(10082.0, 4194.0, 6554.0);
    if (r < 3.5) return vec3(9362.0, 3647.0, 5825.0);
    if (r < 4.5) return vec3(8192.0, 3355.0, 5243.0);
    return vec3(7282.0, 2893.0, 4559.0);
}
vec3 quantTableV(float r) {
    if (r < 0.5) return vec3(10.0, 16.0, 13.0);
    if (r < 1.5) return vec3(11.0, 18.0, 14.0);
    if (r < 2.5) return vec3(13.0, 20.0, 16.0);
    if (r < 3.5) return vec3(14.0, 23.0, 18.0);
    if (r < 4.5) return vec3(16.0, 25.0, 20.0);
    return vec3(18.0, 29.0, 23.0);
}
float decodedCoefficient(float w, float qp, float x, float y, bool intra) {
    float group = mod(x, 2.0) < 0.5 && mod(y, 2.0) < 0.5 ? 0.0 : (mod(x, 2.0) > 0.5 && mod(y, 2.0) > 0.5 ? 1.0 : 2.0);
    float r = mod(qp, 6.0);
    float shift = floor(qp / 6.0);
    vec3 m = quantTableM(r);
    vec3 v = quantTableV(r);
    float mf = group < 0.5 ? m.x : (group < 1.5 ? m.y : m.z);
    float vf = group < 0.5 ? v.x : (group < 1.5 ? v.y : v.z);
    float coeff = floor(abs(w) * 255.0 * (mf / 32768.0) * exp2(-shift) + (intra ? 0.3333333333 : 0.1666666667));
    return sign(w) * coeff * (vf * exp2(shift) / (64.0 * 255.0));
}
vec3 decodedCoefficients(vec3 w, float x, float y, bool intra) {
    float qc = chromaQP(QP_Y);
    return vec3(decodedCoefficient(w.x, QP_Y, x, y, intra), decodedCoefficient(w.y, qc, x, y, intra), decodedCoefficient(w.z, qc, x, y, intra));
}
float sad16(vec2 block, vec2 offset) {
    float result = 0.0;
    for (int i = 0; i < 4; i++) {
        vec2 p = block + vec2(mod(float(i), 2.0), floor(float(i) / 2.0)) * 8.0 + 4.0;
        float a = dot(camera(p / resolution), vec3(0.299, 0.587, 0.114));
        float b = dot(previous((p + offset) / resolution), vec3(0.299, 0.587, 0.114));
        result += abs(a - b);
    }
    return result * (255.0 * 64.0);
}
float mvBits(vec2 motion) {
    return 2.0 * floor(log2(2.0 * abs(motion.x) + 1.0)) + 2.0 * floor(log2(2.0 * abs(motion.y) + 1.0));
}
vec2 findMotion(vec2 block) {
    vec2 bestMotion = vec2(0.0);
    float bestCost = sad16(block, bestMotion);
    float lambdaMV = 0.85 * exp2((QP_Y - 12.0) / 6.0);
    for (int pass = 0; pass < 2; pass++) {
        float distance = pass == 0 ? SEARCH_RANGE : SEARCH_RANGE * 0.25;
        vec2 center = bestMotion;
        for (int i = 0; i < 9; i++) {
            vec2 delta = vec2(mod(float(i), 3.0), floor(float(i) / 3.0)) - 1.0;
            vec2 candidate = center + delta * distance;
            float cost = sad16(block, candidate) + lambdaMV * mvBits(candidate);
            if (cost < bestCost) {
                bestCost = cost;
                bestMotion = candidate;
            }
        }
    }
    return bestMotion;
}
void main(void) {
    vec2 pixel = gl_FragCoord.xy;
    vec2 mb = floor(pixel / 16.0) * 16.0;
    float frame = floor(time * CODEC_FPS);
    bool intra = mod(frame, GOP_FRAMES) < 0.5;
    vec2 motion = intra ? vec2(0.0) : findMotion(mb);
    vec2 tile = floor(pixel / 4.0) * 4.0;
    mat4 ys = mat4(0.0);
    mat4 us = mat4(0.0);
    mat4 vs = mat4(0.0);
    for (int j = 0; j < 4; j++) {
        float y = float(j) + 0.5;
        vec3 a = residualAt(tile + vec2(0.5, y), motion, intra);
        vec3 b = residualAt(tile + vec2(1.5, y), motion, intra);
        vec3 c = residualAt(tile + vec2(2.5, y), motion, intra);
        vec3 d = residualAt(tile + vec2(3.5, y), motion, intra);
        ys[j] = vec4(a.x, b.x, c.x, d.x);
        us[j] = vec4(a.y, b.y, c.y, d.y);
        vs[j] = vec4(a.z, b.z, c.z, d.z);
    }
    for (int j = 0; j < 4; j += 2) {
        float u0 = (us[j].x + us[j].y + us[j + 1].x + us[j + 1].y) * 0.25;
        float u1 = (us[j].z + us[j].w + us[j + 1].z + us[j + 1].w) * 0.25;
        float v0 = (vs[j].x + vs[j].y + vs[j + 1].x + vs[j + 1].y) * 0.25;
        float v1 = (vs[j].z + vs[j].w + vs[j + 1].z + vs[j + 1].w) * 0.25;
        us[j] = vec4(u0, u0, u1, u1);
        us[j + 1] = us[j];
        vs[j] = vec4(v0, v0, v1, v1);
        vs[j + 1] = vs[j];
    }
    for (int j = 0; j < 4; j++) {
        ys[j] = forward4(ys[j]);
        us[j] = forward4(us[j]);
        vs[j] = forward4(vs[j]);
    }
    mat4 ry = mat4(0.0);
    mat4 ru = mat4(0.0);
    mat4 rv = mat4(0.0);
    for (int i = 0; i < 4; i++) {
        vec4 cy = forward4(vec4(ys[0][i], ys[1][i], ys[2][i], ys[3][i]));
        vec4 cu = forward4(vec4(us[0][i], us[1][i], us[2][i], us[3][i]));
        vec4 cv = forward4(vec4(vs[0][i], vs[1][i], vs[2][i], vs[3][i]));
        for (int j = 0; j < 4; j++) {
            vec3 q = decodedCoefficients(vec3(cy[j], cu[j], cv[j]), float(i), float(j), intra);
            cy[j] = q.x;
            cu[j] = q.y;
            cv[j] = q.z;
        }
        ry[i] = inverse4(cy);
        ru[i] = inverse4(cu);
        rv[i] = inverse4(cv);
    }
    int py = int(mod(floor(pixel.y), 4.0));
    int px = int(mod(floor(pixel.x), 4.0));
    vec4 ly = inverse4(vec4(ry[0][py], ry[1][py], ry[2][py], ry[3][py]));
    vec4 lu = inverse4(vec4(ru[0][py], ru[1][py], ru[2][py], ru[3][py]));
    vec4 lv = inverse4(vec4(rv[0][py], rv[1][py], rv[2][py], rv[3][py]));
    vec3 prediction = displayedPrediction(pixel, motion, intra);
    vec3 reconstructed = prediction + vec3(ly[px], lu[px], lv[px]);
    gl_FragColor = vec4(clamp(ycc2rgb(reconstructed), 0.0, 1.0), 1.0);
}