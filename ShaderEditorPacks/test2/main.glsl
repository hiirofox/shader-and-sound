#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

const vec4 sky=vec4(0.5,0.7,0.95,1.0)*.25;
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

vec3 r0,rd;
float nt;
vec3 np,nn;
int guvid,nuvid;
vec2 nuv;
int countTest;

bool quadtest(vec3 o,vec3 r,vec3 a,vec3 b,vec3 c,vec3 d,out float t,out vec3 p,out vec3 n,out vec2 uv){
    countTest++;

    vec3 s=o-a;
    t=1e30;
    bool hit=false;
    for(int i=0;i<2;i++){
        vec3 e1=(i==0?b:c)-a,e2=(i==0?c:d)-a;
        vec3 h=cross(r,e2);
        float det=dot(e1,h);
        if(abs(det)<1e-8)continue;
        float inv=1.0/det,u=dot(s,h)*inv;
        if(u<0.0||u>1.0)continue;
        vec3 q=cross(s,e1);
        float v=dot(r,q)*inv;
        if(v<0.0||u+v>1.0)continue;
        float ti=dot(e2,q)*inv;
        if(ti<=0.0||ti>=t)continue;
        t=ti;
        n=normalize(cross(e1,e2));
        uv=i==0?vec2(u+v,v):vec2(u,u+v);
        hit=true;
    }
    if(hit)p=o+r*t;
    return hit;
}

void addquad(vec3 a,vec3 b,vec3 c,vec3 d)
{
	float t;vec3 p,n;vec2 uv;
	bool hit = quadtest(r0,rd,a,b,c,d,t,p,n,uv);
	if(hit&&nt>t){nt=t;np=p;nn=n;nuvid=guvid;nuv=uv;}
}
void addcrown(vec3 p,float r,int n)
{
    vec3 q=p-r0;
    float t=dot(q,rd);
    if(dot(q,q)-t*t>r*r||t<-r)return;

    srand=1234.456;
    for(int i=0;i<n;i++)
    {
        float z=rf()*2.-1.,a=rf()*6.2831853,b=rf()*6.2831853;
        vec3 N=vec3(sqrt(1.-z*z)*cos(a),sqrt(1.-z*z)*sin(a),z);
        vec3 U=normalize(cross(N,abs(N.z)<.9?vec3(0.,0.,1.):vec3(0.,1.,0.)));
        vec3 V=cross(N,U);
        float h=r*(rf()*.1),s=sqrt((r*r-h*h)*.5);
        vec3 X=(U*cos(b)+V*sin(b))*s,Y=(-U*sin(b)+V*cos(b))*s,C=p+N*h;
        addquad(C+X+Y,C-X+Y,C-X-Y,C+X-Y);
    }
}
void addfloor1(float y,float n){
    float r=20.;
    float t = (y-r0.y)/rd.y;
    vec3 p = r0+rd*t;//位置
    float fx=floor(p.x*float(n))/float(n);
    float cx=ceil(p.x*float(n))/float(n);
    float fz=floor(p.z*float(n))/float(n);
    float cz=ceil(p.z*float(n))/float(n);

    addquad(vec3(fx,y,fz),vec3(fx,y,cz),vec3(cx,y,cz),vec3(cx,y,fz));
}
float terrain(vec2 p){
    float h=0.0;
    h+=2.8*sin(p.x*0.13)*cos(p.y*0.11);
    h+=1.7*sin(p.x*0.31+p.y*0.17);
    h+=0.7*cos(p.y*0.57-p.x*0.24);
    return h*1.;
}
float floorTri(vec3 a,vec3 b,vec3 c){
    vec3 e1=b-a,e2=c-a;
    vec3 p=cross(rd,e2);
    float det=dot(e1,p);
    if(abs(det)<1e-7)return 1e30;
    float inv=1.0/det;
    vec3 s=r0-a;
    float u=dot(s,p)*inv;
    if(u<0.0||u>1.0)return 1e30;
    vec3 q=cross(s,e1);
    float v=dot(rd,q)*inv;
    if(v<0.0||u+v>1.0)return 1e30;
    float t=dot(e2,q)*inv;
    return t>=0.0?t:1e30;
}
void addfloor(float y,float n){
    if(n<=0.0)return;
    float s=1.0/n,INF=1e30,H=5.3;
    float t0=0.0,t1=INF;
    if(abs(rd.y)>1e-6){
        float a=(y-H-r0.y)/rd.y;
        float b=(y+H-r0.y)/rd.y;
        t0=max(0.0,min(a,b));
        t1=max(a,b);
        if(t1<t0)return;
    }else{
        if(abs(r0.y-y)>H)return;
    }
    vec3 p=r0+rd*t0;
    vec2 cell=floor(p.xz*n);
    vec2 dir=sign(rd.xz);
    vec2 next=(cell+max(dir,vec2(0.0)))*s;
    vec2 tMax=vec2(INF),tDelta=vec2(INF);
    if(abs(rd.x)>1e-8){
        tMax.x=(next.x-r0.x)/rd.x;
        tDelta.x=s/abs(rd.x);
    }
    if(abs(rd.z)>1e-8){
        tMax.y=(next.y-r0.z)/rd.z;
        tDelta.y=s/abs(rd.z);
    }
    float t=t0;
    for(int i=0;i<128;i++){
        if(t>t1)break;
        vec2 a=cell*s,b=a+vec2(s);
        vec3 v0=vec3(a.x,y+terrain(vec2(a.x,a.y)),a.y);
        vec3 v1=vec3(a.x,y+terrain(vec2(a.x,b.y)),b.y);
        vec3 v2=vec3(b.x,y+terrain(vec2(b.x,b.y)),b.y);
        vec3 v3=vec3(b.x,y+terrain(vec2(b.x,a.y)),a.y);
        float exitT=min(tMax.x,tMax.y);
        float h0=floorTri(v0,v1,v2);
        float h1=floorTri(v0,v2,v3);
        float hit=min(h0,h1);
        if(hit>=t-1e-5&&hit<=min(exitT,t1)+1e-5){
            addquad(v0,v1,v2,v3);
            return;
        }
        if(tMax.x<tMax.y){
            t=tMax.x;
            tMax.x+=tDelta.x;
            cell.x+=dir.x;
        }else{
            t=tMax.y;
            tMax.y+=tDelta.y;
            cell.y+=dir.y;
        }
    }
}
bool maptest(vec3 o,vec3 d,out float t,out vec3 p,out vec3 n,out int uvid,out vec2 uv)
{
	nt=9999999.;
	nuvid=-1;
	r0=o,rd=d;
	nuv=vec2(0.);
	//scene start
	//树叶
	guvid=0;
	addcrown(vec3(0.,0.,0.),2.,15);
	for(int i=0;i<3;++i)
		addcrown(vec3(hash(float(i)+.2),0.,hash(float(i*i)+.3))*40.,2.,15);
	//地板
	guvid=1;
	//addquad(vec3(-100,-5,-100),vec3(-100,-5,100),vec3(100,-5,100),vec3(100,-5,-100));
	addfloor(-2.,.15);
	//scene end
	if(nt<9999999.)
	{
		t=nt;p=np;n=nn;uvid=nuvid;uv=nuv;
		return true;
	}
	return false;
}
vec4 leafcolfix(vec2 uv,out bool hitleaf)
{
	vec4 c=texture2D(iChannel0,uv)*2.;
	if(c.w<.5)
	{
		return sky;
		hitleaf=false;
	}
	float l=length(uv-vec2(.5,.5));
	c.xyz/=(1.+l*1.)+1.;
	hitleaf=true;
	return c;
}
vec4 floorcol(vec2 uv)
{
	return texture2D(iChannel1,fract(uv*1.));
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
vec3 rayd = normalize(iCameraDir + scale *
    (uv.x * right + uv.y * iCameraUp));


    vec3 o=ray0,d=rayd;

float t=0.,tp;
vec3 p,n;
int uvid;
vec2 tuv;
bool hitleaf=false;
bool hit=maptest(o,d,tp,p,n,uvid,tuv);
if(hit)t+=tp;
vec4 col=sky,c=sky;
countTest=0;
for(int i=0;i<20&&hit&&uvid==0;++i)
{
    vec4 lc=leafcolfix(tuv,hitleaf);
    if(hitleaf){c=lc;break;}
    o=p+d*0.01;
    hit=maptest(o,d,tp,p,n,uvid,tuv);
    if(hit)t+=tp+0.01;
}
if(hit&&uvid==0&&!hitleaf)hit=false;
if(hit&&uvid==1)c=floorcol(tuv);
if(hit)
{
    vec3 lightpos=roty(time*.25)*vec3(2.,4.,2.);
    vec3 lv=lightpos-p;
    float dist=length(lv);
    vec3 ld=lv/max(dist,0.0001);
    float diffuse=max(dot(n,ld),0.);
    if(diffuse>0.)
    {
        bool shadow=false;
        vec3 so=p+ld*0.02,sp,sn;
        float st;
        int sid;
        vec2 suv;
        for(int i=0;i<20;++i)
        {
            if(!maptest(so,ld,st,sp,sn,sid,suv)||st>=length(lightpos-so))break;
            if(sid==0)
            {
                bool solid=false;
                leafcolfix(suv,solid);
                if(!solid){so=sp+ld*0.01;continue;}
            }
            shadow=true;
            break;
        }
        if(shadow)c.rgb*=0.4;
        else c.rgb+=c.rgb*vec3(1.,0.95,0.8)*diffuse*3./(1.+0.015*dist*dist);
    }
}
float fogmix=1.-min(t/200.,1.);
col=mix(c,sky,1.-fogmix);
gl_FragColor=col;

/*
    float t,tp;
    vec3 p,n;
    int uvid;
    vec2 tuv;
    bool hitleaf=false;
    bool hit=maptest(o,d,tp,p,n,uvid,tuv);t+=tp;
    vec4 col=sky,c=sky;
    countTest=0;
    if(hit&&uvid==0)//照到树叶
    {
    	bool hitleaf=false;
    	c=leafcolfix(tuv,hitleaf);
    	for(int i=0;i<20&&!hitleaf&&uvid==0;++i)//透明部分
    	{
    		o=p+d*0.01;//继续透射
    		hit=maptest(o,d,tp,p,n,uvid,tuv);t+=tp;
    		if(hit&&uvid==0)c=leafcolfix(tuv,hitleaf);
    		else break;//啥也碰不到就算了,或者碰到其他东西了
    	}
    }
    if(uvid==1)
    {
    	c=floorcol(tuv);
    }
    float fogmix=1.-min(t/200.,1.);
    col=c;
    col=mix(c,sky,1.-fogmix);

    gl_FragColor = col;
    //gl_FragColor = vec4(1.)*exp(-float(countTest)*0.005);

*/
}
