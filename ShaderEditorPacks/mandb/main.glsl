#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

float srand = 123.45678;
float hash(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(p * (p + p));
}
float rf() { return hash(srand++); }

mat3 rotx(float w){return mat3(1.,0.,0.,0.,cos(w),sin(w),0.,-sin(w),cos(w));}
mat3 roty(float w){return mat3(cos(w),0.,-sin(w),0.,1.,0.,sin(w),0.,cos(w));}
mat3 rotz(float w){return mat3(cos(w),sin(w),0.,-sin(w),cos(w),0.,0.,0.,1.);}

float sdMandelbulb(vec3 p)
{
    vec3 z = p;
    float dr = 1.0;
    float r = 0.0;
    const float power = 8.0;
    for (int i = 0; i < 15; i++)
    {
        r = length(z);
        if (r > 2.0)
            break;
        if (r < 1e-8)
        {
            z = p;
            continue;
        }
        // 球坐标
        float theta = acos(clamp(z.z / r, -1.0, 1.0));
        float phi = atan(z.y, z.x);
        // 距离导数
        dr = pow(r, power - 1.0)
           * power * dr + 1.0;
        // Mandelbulb 幂变换
        float zr = pow(r, power);
        theta *= power;
        phi *= power;
        z = zr * vec3(
            sin(theta) * cos(phi),
            sin(theta) * sin(phi),
            cos(theta)
        );
        z += p;
    }
    return 0.5 * log(r) * r / dr;
}
vec3 mandelbulbNormal(vec3 p) {
    vec3 z = p;
    mat3 J = mat3(1.0);
    float power = 8.0;
    for (int i = 0; i < 15; i++) {
        float r = length(z);
        if (r > 2.0) break;
        if (r < 1e-8) { z = p; J = mat3(1.0); continue; }
        float theta = acos(clamp(z.z / r, -1.0, 1.0));
        float phi = atan(z.y, z.x);
        float t = theta * power;
        float f = phi * power;
        float zr = pow(r, power);
        float st = sin(t), ct = cos(t), sf = sin(f), cf = cos(f);
        vec3 u = vec3(st * cf, st * sf, ct);
        vec3 gr = z / r;
        vec3 gt = (cos(theta) * gr - vec3(0.0, 0.0, 1.0)) / max(r * sin(theta), 1e-8);
        vec3 gp = vec3(-z.y, z.x, 0.0) / max(dot(z.xy, z.xy), 1e-8);
        vec3 Fr = power * zr / r * u;
        vec3 Ft = power * zr * vec3(ct * cf, ct * sf, -st);
        vec3 Fp = power * zr * vec3(-st * sf, st * cf, 0.0);
        mat3 A = mat3(Fr * gr.x + Ft * gt.x + Fp * gp.x, Fr * gr.y + Ft * gt.y + Fp * gp.y, Fr * gr.z + Ft * gt.z + Fp * gp.z);
        J = A * J + mat3(1.0);
        z = zr * u + p;
    }
    return normalize(vec3(dot(J[0], z), dot(J[1], z), dot(J[2], z)));
}
float rayMarchMandb(vec3 ro, vec3 rd, out vec3 n) {
    float t = 0.0;
    n = vec3(0.0);
    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        float d = sdMandelbulb(p);
        if (d < 0.0001) {
            n = mandelbulbNormal(p);
            return t;
        }
        t += max(d , 0.00001);
        if (t > 100.0) break;
    }
    return -1.0;
}
vec4 colMandb(float t,vec3 n,vec3 o,vec3 d)
{
	vec4 col = vec4(0.0);
vec3 bg = mix(vec3(0.008, 0.012, 0.035), vec3(0.035, 0.055, 0.09), smoothstep(-0.5, 0.8, d.y));
col = vec4(bg, 1.0);
if (t > 0.0) {
    vec3 p = o + d * t;
    vec3 v = -d;
    vec3 l1 = normalize(vec3(0.7, 0.9, -0.5));
    vec3 l2 = normalize(vec3(-0.8, 0.2, 0.6));
    vec3 h1 = normalize(l1 + v);
    vec3 h2 = normalize(l2 + v);
    float diff1 = max(dot(n, l1), 0.0);
    float diff2 = max(dot(n, l2), 0.0);
    float spec1 = pow(max(dot(n, h1), 0.0), 64.0);
    float spec2 = pow(max(dot(n, h2), 0.0), 32.0);
    float fresnel = pow(1.0 - max(dot(n, v), 0.0), 4.0);
    float ao = clamp(0.55 + 0.45 * n.y, 0.0, 1.0);
    vec3 base = mix(vec3(0.025, 0.12, 0.22), vec3(0.65, 0.32, 0.12), smoothstep(-0.6, 0.8, n.y));
    vec3 c = base * (0.12 + diff1 * vec3(1.4, 1.05, 0.75) + diff2 * vec3(0.15, 0.45, 1.2));
    c += spec1 * vec3(1.0, 0.8, 0.5) * 1.8;
    c += spec2 * vec3(0.2, 0.55, 1.0) * 0.8;
    c += fresnel * vec3(0.15, 0.5, 1.0) * 1.2;
    c *= ao;
    float fog = 1.0 - exp(-0.006 * t * t);
    c = mix(c, bg, fog);
    c = c / (c + vec3(1.0));
    c = pow(c, vec3(0.85));
    col = vec4(c, 1.0);
}
return col;
}

float deKIFS(vec3 p) {
    vec3 z = p;
    float scale = 1.0;
    float s = 2.0;
    float a = 0.45;
    mat2 rot = mat2(cos(a), -sin(a), sin(a), cos(a));
    for (int i = 0; i < 7; i++) {
        z = abs(z);
        if (z.x < z.y) z.xy = z.yx;
        if (z.x < z.z) z.xz = z.zx;
        if (z.y < z.z) z.yz = z.zy;
        z.xy = rot * z.xy;
        z = s * z - vec3(2.0, 1.1, 0.7);
        scale *= s;
    }
    vec3 q = abs(z) - vec3(0.65, 1.8, 0.65);
    float d = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    return d / scale;
}
vec3 normalKIFS(vec3 p) {
    float e = 0.0005;
    vec3 k1 = vec3(1.0, -1.0, -1.0);
    vec3 k2 = vec3(-1.0, -1.0, 1.0);
    vec3 k3 = vec3(-1.0, 1.0, -1.0);
    vec3 k4 = vec3(1.0, 1.0, 1.0);
    return normalize(k1 * deKIFS(p + e * k1) + k2 * deKIFS(p + e * k2) + k3 * deKIFS(p + e * k3) + k4 * deKIFS(p + e * k4));
}
float rayMarchKIFS(vec3 o, vec3 d, out vec3 n) {
    float t = 0.0;
    n = vec3(0.0);
    for (int i = 0; i < 96; i++) {
        vec3 p = o + d * t;
        float h = deKIFS(p);
        if (h < 0.0005) {
            n = normalKIFS(p);
            return t;
        }
        t += max(h * 0.65, 0.0001);
        if (t > 30.0) break;
    }
    return -1.0;
}
vec4 colKIFS(float t, vec3 n, vec3 o, vec3 d) {
    vec3 bg = vec3(0.005, 0.009, 0.025);
    if (t < 0.0) return vec4(bg, 1.0);
    vec3 p = o + d * t;
    vec3 v = -d;
    vec3 l1 = normalize(vec3(0.6, 0.85, -0.4));
    vec3 l2 = normalize(vec3(-0.7, 0.25, 0.8));
    float diff1 = max(dot(n, l1), 0.0);
    float diff2 = max(dot(n, l2), 0.0);
    float spec1 = pow(max(dot(reflect(-l1, n), v), 0.0), 64.0);
    float spec2 = pow(max(dot(reflect(-l2, n), v), 0.0), 32.0);
    float fresnel = pow(1.0 - max(dot(n, v), 0.0), 4.0);
    float pattern = 0.5 + 0.5 * sin(p.y * 8.0 + p.x * 3.0);
    vec3 gold = vec3(0.65, 0.38, 0.13);
    vec3 blue = vec3(0.025, 0.12, 0.25);
    vec3 base = mix(blue, gold, smoothstep(0.2, 0.8, pattern));
    vec3 c = base * (0.12 + diff1 * vec3(1.5, 1.15, 0.7) + diff2 * vec3(0.15, 0.45, 1.2));
    c += spec1 * vec3(1.0, 0.78, 0.45) * 1.5;
    c += spec2 * vec3(0.25, 0.6, 1.0) * 0.8;
    c += fresnel * vec3(0.2, 0.55, 1.0) * 0.7;
    c = mix(c, bg, 1.0 - exp(-0.003 * t * t));
    c = c / (1.0 + c);
    c = pow(c, vec3(0.85));
    return vec4(c, 1.0);
}
float deKleinian(vec3 p){
    const vec3 CSize=vec3(0.63248,0.78632,0.875);
    float DEfactor=1.0;
    for(int i=0;i<5;i++){
        p=2.0*clamp(p,-CSize,CSize)-p;
        float k=max(0.70968/max(dot(p,p),1e-8),1.0);
        p*=k;
        DEfactor*=k;
    }
    float rxy=length(p.xy);
    return max(rxy-0.92784,abs(rxy*p.z)/max(length(p),1e-8))/DEfactor;
}
vec3 normalKleinian(vec3 p){
    float e=0.0005;
    vec3 k1=vec3(1.0,-1.0,-1.0);
    vec3 k2=vec3(-1.0,-1.0,1.0);
    vec3 k3=vec3(-1.0,1.0,-1.0);
    vec3 k4=vec3(1.0,1.0,1.0);
    return normalize(k1*deKleinian(p+k1*e)+k2*deKleinian(p+k2*e)+k3*deKleinian(p+k3*e)+k4*deKleinian(p+k4*e));
}
float rayMarchKleinian(vec3 o,vec3 d,out vec3 n){
    float t=0.0;
    n=vec3(0.0);
    for(int i=0;i<120;i++){
        vec3 p=o+d*t;
        float h=deKleinian(p);
        if(h<0.0005){
            n=normalKleinian(p);
            return t;
        }
        t+=max(h*0.65,0.0001);
        if(t>40.0)break;
    }
    return -1.0;
}
vec4 colKleinian(float t,vec3 n,vec3 o,vec3 d){
    vec3 bg=mix(vec3(0.006,0.009,0.02),vec3(0.02,0.03,0.06),smoothstep(-0.3,0.8,d.y));
    if(t<0.0)return vec4(bg,1.0);
    vec3 p=o+d*t;
    vec3 v=-d;
    vec3 l1=normalize(vec3(0.65,0.85,-0.35));
    vec3 l2=normalize(vec3(-0.55,0.25,0.8));
    vec3 h1=normalize(l1+v);
    vec3 h2=normalize(l2+v);
    float diff1=max(dot(n,l1),0.0);
    float diff2=max(dot(n,l2),0.0);
    float spec1=pow(max(dot(n,h1),0.0),96.0);
    float spec2=pow(max(dot(n,h2),0.0),40.0);
    float fres=pow(1.0-max(dot(n,v),0.0),5.0);
    float stripe1=0.5+0.5*sin(p.y*140.0+p.z*18.0);
    float stripe2=0.5+0.5*sin(p.x*110.0-p.y*13.0);
    float brush=mix(stripe1,stripe2,0.5+0.5*n.y);
    float macro=0.5+0.5*sin(p.y*2.6+p.x*1.3+p.z*0.7);
    vec3 steel=mix(vec3(0.12,0.14,0.16),vec3(0.42,0.44,0.48),brush*0.35+0.15);
    vec3 bronze=vec3(0.55,0.36,0.18);
    vec3 base=mix(steel,bronze,macro*0.35);
    vec3 c=base*(0.14+diff1*vec3(1.45,1.15,0.8)+diff2*vec3(0.18,0.42,1.05));
    c+=spec1*mix(vec3(0.9,0.95,1.0),vec3(1.0,0.82,0.55),0.6)*1.4;
    c+=spec2*vec3(0.25,0.55,1.0)*0.9;
    c+=fres*vec3(0.2,0.55,1.0)*0.9;
    float fog=1.0-exp(-0.0018*t*t);
    c=mix(c,bg,fog);
    c=c/(1.0+c);
    c=pow(c,vec3(0.85));
    return vec4(c,1.0);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 m=mouse;
    uv-=vec2(.5);
    m-=vec2(.5);
    uv.x*=resolution.x/resolution.y;
    m.x*=resolution.x/resolution.y;
    const float fov=100.;
    const vec3 rup=vec3(0.,1.,0.);
    const vec3 forward=vec3(0.,0.,1.);
    const vec3 right=vec3(1.,0.,0.);
    const vec3 ray0=vec3(0.,0.,-5.);
    vec3 rayd=normalize(forward+2.*tan(radians(fov)*.5)*(uv.x*right+uv.y*rup));

    float w=time*.0;
    mat3 rm=roty(w+m.x*16.)*rotx(-m.y*8.);
    vec3 o=rm*ray0,d=rm*rayd;

    //vec3 n;
    //float t = rayMarchMandb(o, d, n);
    //vec4 col=colMandb(t,n,o,d);

   // vec3 n;
 //   float t = rayMarchKIFS(o, d, n);
 //   vec4 col = colKIFS(t, n, o, d);

    vec3 n;
    float t=rayMarchKleinian(o,d,n);
    vec4 col=colKleinian(t,n,o,d);
    gl_FragColor = col;
}
