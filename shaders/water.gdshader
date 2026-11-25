shader_type spatial;
render_mode cull_disabled;
uniform bool simple = false;
void fragment(){
	float t = TIME*1.65;
	float ribbons = sin(UV.x*91.0 + sin(UV.y*9.0-t)*0.8);
	float streak = smoothstep(0.57,1.0,ribbons)*smoothstep(-0.65,0.85,sin(UV.y*22.0-t*4.0+UV.x*63.0));
	if(!simple){streak += 0.24*smoothstep(0.2,0.95,sin(UV.x*203.0+UV.y*2.0+sin(t)));}
	float foam = smoothstep(0.93,1.0,UV.y)+1.0-smoothstep(0.0,0.06,UV.y);
	ALBEDO = mix(vec3(.035,.43,.70),vec3(.84,.98,1.0),clamp(streak+foam,0.0,1.0));
	ROUGHNESS=.32; ALPHA=.88;
}
