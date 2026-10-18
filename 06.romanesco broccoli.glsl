#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

float srand=1.234;
float hash(float x){x=fract(x*.1031);x*=x+33.33;x*=x+x;return fract(x)*2.-1.;}
float rf(){return hash(srand+=1.);}
mat3 rotx(float w){return mat3(1.,0.,0.,0.,cos(w),sin(w),0.,-sin(w),cos(w));}
mat3 roty(float w){return mat3(cos(w),0.,-sin(w),0.,1.,0.,sin(w),0.,cos(w));}
mat3 rotz(float w){return mat3(cos(w),sin(w),0.,-sin(w),cos(w),0.,0.,0.,1.);}

vec3 r0,rd;
float nt;
vec3 np,nr;

bool cirtest(vec3 o,vec3 d,vec3 pos,float r,
	out float t,out vec3 p,out vec3 ref)
{
    vec3 q=o-pos;
    float b=dot(q,d),h=b*b-dot(q,q)+r*r;
    if(h<0.)return false;
    h=sqrt(h);
    t=-b-h;
    if(t<0.)t=-b+h;
    if(t<0.)return false;
    p=o+d*t;
    ref=reflect(d,(p-pos)/r);
    return true;
}
void addcir(vec3 pos,float r)
{
	float t;vec3 p,ref;
	bool hit=cirtest(r0,rd,pos,r,t,p,ref);
	if(hit&&nt>t){nt=t;np=p;nr=ref;}
}

bool maptest(vec3 o,vec3 d,
	out float t,out vec3 p,out vec3 r)
{
	nt=9999999.;
	r0=o;rd=d;
	//scene start
for(int i=0;i<20;i++){
    float a=float(i)*2.3999632,t=(float(i)+.5)/20.,s=.7*(1.-t)+.03;
    vec3 e=vec3(cos(a),0.,sin(a));
    vec3 z=normalize(vec3(e.x*.65,1.,e.z*.65)),x=vec3(-e.z,0.,e.x),y=cross(z,x);
    vec3 p=vec3(e.x*1.5*(1.-t),2.8*t,e.z*1.5*(1.-t));
    for(int j=0;j<9;j++){
        float b=float(j)*2.3999632,u=(float(j)+.5)/9.,q=s*(.5*(1.-u)+.12);
        vec3 f=x*cos(b)+y*sin(b),v=z*.8+f*.6,g=cross(z,f),h=cross(v,g);
        vec3 c=p+z*(s*1.8*u)+f*(s*.9*(1.-u));
        for(int k=0;k<6;k++){
            float d=float(k)*2.3999632,w=(float(k)+.5)/5.;
            vec3 n=g*cos(d)+h*sin(d);
            addcir(c+v*(q*1.5*w)+n*(q*.9*(1.-w)),(q*(.3*(1.-w)+.08))*2.);
        }
    }
}
	//scene end
	if(nt<9999999.)
	{t=nt;p=np;r=nr;return true;}
	return false;
}

void main(void) {
    vec2 uv=gl_FragCoord.xy/resolution;
    vec2 m=mouse;
    vec2 bbuv=uv;
    uv-=vec2(.5);
    m-=vec2(.5);
    uv.x*=resolution.x/resolution.y;
    m.x*=resolution.x/resolution.y;
    const float fov=100.;
    const vec3 rup=vec3(0.,1.,0.);
    const vec3 forward=vec3(0.,0.,1.);
    const vec3 right=vec3(1.,0.,0.);
    const vec3 ray0=vec3(0.,0.,-6.);
    vec3 rayd=normalize(forward+2.*tan(radians(fov)*.5)*(uv.x*right+uv.y*rup));

    float w=time*.05;
    mat3 rm=roty(w+m.x*16.)*rotx(-m.y*8.);
    vec3 o=rm*ray0,d=rm*rayd;

    float t;
vec3 p,r;
bool hit=maptest(o,d,t,p,r);
vec4 col;
if(hit){
    vec3 n=normalize(r-d);
    vec3 l=normalize(vec3(-.5,.85,.45));
    float grain=sin(p.x*83.)*sin(p.y*91.)*sin(p.z*79.);
    float band=sin(p.y*30.+sin(p.x*19.)*2.+sin(p.z*21.)*2.);
    float tip=clamp(.5+.27*n.y+.09*band+.05*grain,0.,1.);
    vec3 base=mix(vec3(.10,.26,.018),vec3(.65,.84,.16),tip);
    float dif=max(dot(n,l),0.);
    float fill=max(dot(n,normalize(vec3(.7,.2,-.6))),0.);
    float rim=pow(1.-max(dot(n,-d),0.),3.);
    float spec=pow(max(dot(r,l),0.),40.);
    float ao=mix(.7,1.,smoothstep(0.,2.8,p.y));
    vec3 c=base*(.25+.85*dif+.22*fill)*ao;
    c+=vec3(.65,.9,.2)*rim*.3;
    c+=vec3(1.,.95,.65)*spec*.22;
    c=pow(c,vec3(.85));
    col=vec4(c,1.);
}else{
    col=vec4(mix(vec3(.025,.04,.035),vec3(.12,.17,.14),clamp(d.y*.5+.5,0.,1.)),1.);
}

    gl_FragColor = col;
}
