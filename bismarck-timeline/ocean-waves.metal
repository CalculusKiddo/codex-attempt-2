#include <metal_stdlib>
using namespace metal;

float seaHash(float2 p) { return fract(sin(dot(p,float2(127.1,311.7)))*43758.5453); }
float seaNoise(float2 p) {
 float2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(seaHash(i),seaHash(i+float2(1,0)),f.x),mix(seaHash(i+float2(0,1)),seaHash(i+float2(1,1)),f.x),f.y);
}
// Dispersive deep-water components evolve independently. The nonlinear harmonic
// sharpens crests; normals, sky reflection and whitecaps are rebuilt every frame.
kernel void oceanSurface(device uchar4 *pixels [[buffer(0)]],
 constant float4 *u [[buffer(1)]],constant float4 *waves [[buffer(2)]],
 uint2 gid [[thread_position_in_grid]]) {
 uint width=uint(u[2].x),height=uint(u[2].y);if(gid.x>=width||gid.y>=height)return;
 float2 screen=float2((float(gid.x)+0.5)*1280.0/float(width)-640.0,
                       (float(gid.y)+0.5)*720.0/float(height)-355.0);
 float z=u[0].z,angle=u[0].w,t=u[1].x,storm=u[1].y,metres=u[1].z;
 float co=cos(angle),si=sin(angle);
 float2 p=(u[0].xy+float2(screen.x*co+screen.y*si,-screen.x*si+screen.y*co)/z)*metres;
 float metresPerPixel=metres/z*1280.0/float(width);
 float2 slope=0;float heightField=0,crest=0,oldCrest=0;
 for(uint j=0;j<48;j++) {
  float4 w=waves[j];float k=length(w.xy),lambda=6.2831853/k;
  float lod=smoothstep(2.0,7.0,lambda/metresPerPixel);
  float phase=dot(p,w.xy)-w.w*t+float(j)*2.39996323;
  float sn=sin(phase),cs=cos(phase);
  float group=0.84+0.16*sin(dot(p,w.xy)*0.085-t*0.11+float(j)*1.71);
  float a=w.z*mix(0.85,1.35,storm)*lod*group;
  heightField+=a*(sn+0.16*sin(2.0*phase));
  slope+=a*w.xy*(cs+0.32*cos(2.0*phase));
  if(lambda>10.0) {
   float weight=a*k;
   crest+=weight*pow(max(0.0,sn),10.0);
   oldCrest+=weight*pow(max(0.0,sin(phase+w.w*0.45)),10.0);
  }
 }
 float3 n=normalize(float3(-slope,1.0));
 float3 light=normalize(float3(-0.45,-0.65,0.85));
 float3 halfVector=normalize(light+float3(0,0,1));
 float facing=dot(n,light);
 float3 deep=float3(0.027,0.076,0.093),lit=float3(0.085,0.155,0.173);
 float elevation=clamp(0.47+heightField*0.035,0.0,1.0);
 float3 colour=mix(deep,lit,clamp(elevation*0.58+facing*0.23,0.0,1.0));
 // Broad overcast reflections bend with the wave normal rather than scrolling.
 float sky=pow(clamp(0.5+n.y*0.46-n.x*0.24,0.0,1.0),2.0);
 colour+=float3(0.06,0.09,0.105)*sky;
 float reflection=pow(max(0.0,dot(n,halfVector)),26.0);
 colour+=float3(0.11,0.14,0.15)*reflection;
 float fine=seaNoise(p*0.42)+0.5*seaNoise(p*1.13+3.2);
 float patches=seaNoise(p*0.075+float2(t*0.075,-t*0.03));
 float threshold=mix(0.43,0.34,storm);
 float breaking=smoothstep(threshold,threshold+0.21,crest+oldCrest*0.30);
 float foam=breaking*smoothstep(0.58,1.25,fine)*smoothstep(0.28,0.68,patches);
 foam*=smoothstep(0.2,1.5,1.0/metresPerPixel);
 colour=mix(colour,float3(0.65,0.74,0.75),min(0.68,foam*0.8));
 // Very small-scale glints have a low amplitude and are filtered with distance.
 colour+=(fine-0.75)*0.007*smoothstep(0.2,1.5,1.0/metresPerPixel);
 colour=clamp(colour,0.0,1.0);
 pixels[gid.y*width+gid.x]=uchar4(uchar3(colour*255.0),255);
}
