shader_type spatial;
render_mode cull_disabled;
varying vec3 local_p;
void vertex(){local_p=VERTEX;}
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){
	vec3 i=floor(p),f=fract(p); f=f*f*(3.-2.*f);
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
	mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1)),f.x),f.y),f.z);
}
void fragment(){
	float grain=noise3(local_p*9.);
	float mottling=noise3(local_p*2.5)+.35*grain;
	ALBEDO=pow(COLOR.rgb,vec3(1.5))*(.67+.47*mottling);
	ROUGHNESS=.92;
}
