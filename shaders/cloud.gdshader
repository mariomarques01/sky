shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 light_color : source_color = vec4(.99,.98,1.,1.);
void fragment(){
	vec2 p=UV*2.-1.;
	float edge = 1.-length(p*vec2(1.,1.28));
	edge+=.075*sin(16.*p.x+sin(p.y*8.)+TIME*.09)+.045*sin(p.x*29.+p.y*8.);
	ALBEDO=mix(vec3(.56,.68,.89),light_color.rgb,clamp(.57-p.y*.77+edge*.61,0.,1.));
	ALPHA=smoothstep(-.05,.23,edge)*.92;
}
