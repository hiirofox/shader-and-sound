#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform sampler2D iChannel0;
uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

mat3 rotx(float w){return mat3(1.,0.,0.,0.,cos(w),sin(w),0.,-sin(w),cos(w));}
mat3 roty(float w){return mat3(cos(w),0.,-sin(w),0.,1.,0.,sin(w),0.,cos(w));}
mat3 rotz(float w){return mat3(cos(w),sin(w),0.,-sin(w),cos(w),0.,0.,0.,1.);}

vec3 readn(vec2 uv) { return (texture2D(iChannel0,clamp(uv,0.0,1.0)).xyz-vec3(0.5))/0.3; }
float readt(vec2 uv) { return texture2D(iChannel0,clamp(uv,0.0,1.0)).w*10.; }

vec4 gcol1(vec2 uv)
{
    vec3 n = readn(uv);
    float t = readt(uv);
    bool hit = t < 999. && length(n) > .5;
    float fogNear = 0.25;
    float fogFar = 0.5;
    float fogDensity = 2.0;
    float fogStrength = .6;
    vec3 fogNearColor = vec3(.85, .86, .83);
    vec3 fogFarColor = vec3(.95, .95, .90);
    float fd = smoothstep(fogNear, fogFar, t);
    vec3 fogColor = mix(fogNearColor, fogFarColor, pow(fd, .8));
    if (!hit) return vec4(fogFarColor, 1.);
    n = normalize(n);
    vec3 sun = normalize(vec3(.65, .75, .35));
    float ndl = dot(n, sun);
    float diff = max(ndl, 0.);
    float hemi = n.y * .5 + .5;
    float sky = smoothstep(-.4, 1., n.y);
    float bounce = smoothstep(.2, -1., n.y);
    vec3 albedo = vec3(.72, .64, .52);
    vec3 ambient = mix(vec3(.24, .23, .22), vec3(.38, .48, .63), sky);
    ambient += vec3(.27, .16, .09) * bounce * .35;
    vec3 direct = vec3(1.0, .78, .52) * diff * 1.15;
    float soft = smoothstep(-.15, .35, ndl);
    direct += vec3(.85, .55, .32) * soft * .08;
    vec3 col = albedo * (ambient + direct);
    col += albedo * vec3(.08, .12, .18) * hemi * .08;
    float fog = pow(fd, fogDensity) * fogStrength;
    col = mix(col, fogColor, fog);
    return vec4(col, 1.);
}

vec4 gcol2(vec2 uv)
{
    vec3 n = readn(uv);
    float t = readt(uv);
    bool hit = t < 999. && length(n) > .5;
    float fogNear = .98;
    float fogFar = 10.0;
    float fogDensity = 0.7;
    float fogStrength = .92;
    vec3 fogNearColor = vec3(.55, .62, .65);
    vec3 fogFarColor = vec3(.16, .29, .38);
    float fd = smoothstep(fogNear, fogFar, t);
    vec3 fogColor = mix(fogNearColor, fogFarColor, pow(fd, .75));
    if (!hit) return vec4(fogFarColor, 1.);
    n = normalize(n);
    vec3 light = normalize(vec3(-.5, .85, .3));
    vec3 fill = normalize(vec3(.7, .15, -.6));
    float ndl = max(dot(n, light), 0.);
    float nd2 = max(dot(n, fill), 0.);
    float sky = smoothstep(-.5, .9, n.y);
    float ground = smoothstep(.3, -1., n.y);
    vec3 metal = vec3(.35, .40, .43);
    vec3 ambient = mix(vec3(.12, .16, .19), vec3(.38, .52, .60), sky);
    ambient += vec3(.13, .17, .19) * ground * .4;
    vec3 direct = vec3(.78, .91, 1.) * pow(ndl, 1.6) * 1.15;
    direct += vec3(.22, .55, .76) * pow(nd2, 2.5) * .45;
    float sheen = pow(1. - abs(dot(n, light)), 5.);
    vec3 col = metal * (ambient + direct);
    col += vec3(.55, .78, .92) * sheen * .14;
    col += vec3(.18, .35, .48) * pow(nd2, 12.) * .08;
    float fog = pow(fd, fogDensity) * fogStrength;
    col = mix(col, fogColor, fog);
    return vec4(col, 1.);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    //gl_FragColor=texture2D(iChannel0, uv);return;
    gl_FragColor = gcol1(uv);
}