#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

float de(vec3 p,out vec3 pmap){
    float k=time*0.01;
    p.xz=abs(.5-mod(p.xz,1.))+.01;
    float DEfactor=1.;
    vec3 sp=vec3(0.);
    for (int i=0; i<15; i++) {
      p = abs(p)-vec3(.0,1.5,0);
      float r2 = dot(p, p);
      float sc=2./clamp(r2,0.4,1.);
      p*=sc;
      DEfactor*=sc;
      p = p - vec3(0.5,1.,0.5);
      sp += p;
    }
    pmap=sp;
    return length(p)/DEfactor-.001;
}
float de1(vec3 p,out vec3 pmap){
    vec3 z=p;
    float dr=1.,r=0.;
    vec3 sp=vec3(0.);
    for(int i=0;i<15;i++){
        r=length(z);
        if(r>2.)break;
        float a=acos(z.z/r)*8.;
        float b=atan(z.y,z.x)*8.;
        dr=8.*pow(r,7.)*dr+1.;
        z=pow(r,8.)*vec3(sin(a)*cos(b),sin(a)*sin(b),cos(a))+p;
       sp +=z;
    }
    pmap=sp;
    return .5*log(r)*r/dr-.005;
}
vec3 denorm(vec3 p)
{
    float e = 0.00008;
    vec3 pmap;
    float d = de(p,pmap);
    return normalize(vec3(
        de(p + vec3(e,0,0),pmap),
        de(p + vec3(0,e,0),pmap),
        de(p + vec3(0,0,e),pmap)
    ) - d);
}
vec4 orbitcol1(vec3 p)
{
    vec3 t = log(1.0 + abs(p) * 2.0);
    float v = dot(sin(t * 2.5), vec3(0.33));
    vec3 col = 0.5 + 0.5 * cos(
        6.28318 * (v * 0.35 + vec3(0.05, 0.38, 0.68))
    );
    col = mix(col, vec3(0.35, 0.65, 1.0), 0.15);
    return vec4(col, 1.0);
}
vec4 orbitcol2(vec3 p)
{
    vec3 t = log(1.0 + abs(p) * 3.0);
    float v = dot(sin(t * vec3(2.3, 3.7, 5.1)), vec3(0.4, 0.35, 0.25));
    v += 0.25 * sin(dot(t, vec3(4.2, 2.8, 3.6)));
    vec3 col = 0.5 + 0.5 * cos(6.283185 * (v * 0.65 + vec3(0.0, 0.33, 0.67)) + 0.4 * sin(t.yzx * 2.0)  );
    col = pow(col, vec3(0.8));
    col *= 0.85 + 0.15 * sin(v * 8.0);
    return vec4(col, 1.0);
}
vec4 orbitcol(vec3 p)
{
    vec3 q = log(1.0 + abs(p) * vec3(2.0, 3.5, 1.4));
    vec3 phase = fract(q * vec3(0.37, 0.23, 0.51));
    phase += 0.06 * sin(p.yzx * vec3(2.1, 3.7, 1.6));
    float cyan   = exp(-90.0 * pow(phase.x - 0.72, 2.0));
    float green  = exp(-130.0 * pow(phase.y - 0.43, 2.0));
    float gold   = exp(-110.0 * pow(phase.z - 0.81, 2.0));
    float red    = exp(-180.0 * pow(phase.x - 0.91, 2.0));
    float pink   = exp(-150.0 * pow(phase.y - 0.87, 2.0));
    vec3 col = mix(
        vec3(0.015, 0.025, 0.12),
        vec3(0.18, 0.08, 0.42),
        0.5 + 0.5 * sin(dot(q, vec3(1.3, 0.7, 1.9)))
    );
    col = mix(col, vec3(0.0, 0.85, 0.95), cyan);
    col = mix(col, vec3(0.25, 0.9, 0.18), green);
    col = mix(col, vec3(1.0, 0.65, 0.05), gold);
    col = mix(col, vec3(1.0, 0.08, 0.06), red);
    col = mix(col, vec3(0.95, 0.18, 0.65), pink);
    return vec4(col, 1.0);
}
uniform vec3 iCameraPos;
uniform vec3 iCameraDir;
uniform vec3 iCameraUp;
uniform float iFov;
void main(void) {
	vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
	vec3 right = normalize(cross(iCameraDir, iCameraUp));
	float scale = tan(radians(clamp(iFov, .001, 179.999)) * .5);
	vec3 ray0 = iCameraPos;
	vec3 rayd = normalize(iCameraDir + scale * (uv.x * right + uv.y * iCameraUp));

	vec3 light=vec3(0.,1.,0.);
	ray0*=1.;

	float far=0.;
	vec3 pmap;
	ray0+=rayd*0.01;
	bool hitlight=false;
	for(int iter=0;iter<100;++iter)
	{
		float t1=de(ray0,pmap);
		float t2=length(ray0-light)-.01;
		float t=min(t1,t2);
		if(t1<0.000001)break;
		if(t2<0.0001){hitlight=true;break;}
		ray0+=rayd*t;
		far += t;
	}
	vec3 norm=denorm(ray0);
	vec4 decol=orbitcol(pmap*.005+vec3(.1,.5,.2));
	if (hitlight) decol=vec4(1.,1.,1.,1.);

	rayd = light-ray0;
	vec3 lray0=ray0;
	bool shadow=true;
	for(int iter=0;iter<70;++iter)
	{
		float t=de(ray0,pmap);
		ray0+=rayd*t;
		shadow = dot(lray0-light, ray0-light) > 0.;
		if(!shadow)break;
	}
	float lightfar=length(lray0-light);
	if (shadow) decol*=0.3;

	float scenedamp=1./(1.+far*far*.08);
	float lightdamp=1./(1.+lightfar*lightfar*.08);

	if(!hitlight)
	{
		if(!shadow) decol*=lightdamp;
		decol*=scenedamp;
	}

	gl_FragColor = decol;
}
