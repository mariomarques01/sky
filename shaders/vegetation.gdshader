shader_type spatial;
render_mode cull_disabled;
void vertex(){
	VERTEX.x += .023*sin(TIME*1.6+VERTEX.y*1.4+MODEL_MATRIX[3].x)*clamp(VERTEX.y+.2,0.,1.);
}
void fragment(){ALBEDO=COLOR.rgb;ROUGHNESS=.9;}
