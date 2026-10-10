#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D noise;
uniform sampler2D zbuf;
uniform float time;


float hash(vec3 p)
{
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}
float noise3D(vec3 p)
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash(i + vec3(0.0,0.0,0.0));
    float n100 = hash(i + vec3(1.0,0.0,0.0));
    float n010 = hash(i + vec3(0.0,1.0,0.0));
    float n110 = hash(i + vec3(1.0,1.0,0.0));
    float n001 = hash(i + vec3(0.0,0.0,1.0));
    float n101 = hash(i + vec3(1.0,0.0,1.0));
    float n011 = hash(i + vec3(0.0,1.0,1.0));
    float n111 = hash(i + vec3(1.0,1.0,1.0));
    float x00 = mix(n000,n100,f.x);
    float x10 = mix(n010,n110,f.x);
    float x01 = mix(n001,n101,f.x);
    float x11 = mix(n011,n111,f.x);
    return mix(mix(x00,x10,f.y),mix(x01,x11,f.y),f.z);
}
float cloud(vec3 p, vec3 rayd, float far)
{
    const int STEPS = 15;
    float fog = 0.0;
    for (int i = 0; i < STEPS; i++)
    {
        float d = far * (float(i) + 0.5) / float(STEPS);
        vec3 q = p + rayd * d + vec3(2.25 * time, 0.0, 0.0);
        float n1 = noise3D((q + vec3(0.0, 1.0, 2.0)) * 0.1);
        float n2 = noise3D((q + vec3(3.0, 1.0, 2.0)) * 0.25);
        float n3 = noise3D((q + vec3(4.0, 1.0, 2.0)) * 0.70);
        float n = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
        float density = smoothstep(0.25, 0.65, n);
        float h = smoothstep(-1.0, 1.0, -q.y) * smoothstep(3.0, 1.0, -q.y);
        fog += density * h;
    }
    return fog * far / float(STEPS);
}

vec2 circlerz(vec3 ray0, vec3 rayd, vec3 cpos, float r)
{
    vec3 q = cpos - ray0;
    float z = dot(q, rayd);
    float rz = length(q - rayd * z);
    float h2 = r * r - rz * rz;
    if (h2 < 0.0)
        return vec2(rz, 999999.);
    return vec2(rz, z - sqrt(h2));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
uv = uv * 2.0 - 1.0;
uv.x *= resolution.x / resolution.y;

// 相机位置
vec3 ray0 = vec3(-10.0,-16.0, -10.0);

// mouse: 0~1
vec2 m = mouse * 2.0 - 1.0;

float yaw   = -(mouse.x - 0.5) * (resolution.x / resolution.y) * 12.0;
float pitch =  (mouse.y - 0.5) * 6.0;

// 相机 forward
vec3 forward = normalize(vec3(
    sin(yaw) * cos(pitch),
    sin(pitch),
    cos(yaw) * cos(pitch)
));

// 标准 camera basis
vec3 worldUp = vec3(0.0, 1.0, 0.0);
vec3 right = normalize(cross(forward, worldUp));
vec3 up = cross(right, forward);

// FOV
float fov = radians(100.0);
float tanHalfFov = tan(fov * 0.5);

// 最终 ray
vec3 ray = normalize(
    forward
    + right * uv.x * tanHalfFov
    + up    * uv.y * tanHalfFov
);




    vec3 c[3];
    c[0] = vec3(-0.8,  0.0, 3.0);
    c[1] = vec3( 0.8,  0.2, 4.5);
    c[2] = vec3( 0.0, -0.7, 6.0);
    vec4 col[3];
    col[0]=vec4(1.,0.,0.,1.);
    col[1]=vec4(0.,1.,0.,1.);
    col[2]=vec4(0.,0.,1.,1.);
    float r[3];
    r[0] = 0.8;
    r[1] = 1.0;
    r[2] = 1.2;

    float zbuf = 999.0;
    vec4 zcol;
    float hit = 0.0;

    for (int i = 0; i < 3; i++)
    {
        vec2 rz = circlerz(ray0, ray, c[i], r[i]);

        if (rz.y > 0.0 && rz.y < zbuf)
        {
            zbuf = rz.y;
            zcol = vec4(col[i].rgb, float(i));
        }
        if (rz.x < r[i] && rz.y > 0.0)
            hit = 1.0;
    }

    // 雾积分到 zbuf
    float far = min(zbuf, 40.0);
    float fog = cloud(ray0,ray,far)*2.;

    float trans = exp(-fog * .27);
    vec3 cols = vec3(1.) * (1.0 - trans);
    vec3 colc = vec3(.4,.7,.9);
    if (hit > 0.5)
    {
        vec3 center = mix(mix(c[0], c[1], step(0.5, zcol.a)), c[2], step(1.5, zcol.a));
        vec3 normal = normalize(ray0 + ray * zbuf - center);
        vec3 light = normalize(vec3(-0.5, 0.8, -0.7));
        vec3 view = normalize(-ray);
        float diff = max(dot(normal, light), 0.0);
        float rim = pow(1.0 - max(dot(normal, view), 0.0), 2.0);
        float spec = pow(max(dot(reflect(-light, normal), view), 0.0), 24.0);
        vec3 base = zcol.rgb;
        vec3 shade = base * (0.18 + diff * 0.72) + vec3(1.0) * (spec * 0.55 + rim * 0.08);
        colc = shade;
    }
    vec3 frag = cols.xyz+colc.xyz*trans;
    gl_FragColor = vec4(frag, 1.0);
}
