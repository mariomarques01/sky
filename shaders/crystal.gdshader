shader_type spatial;
uniform vec4 hue : source_color = vec4(1.,.73,.10,1.);
void fragment(){float rim=pow(1.-abs(dot(normalize(NORMAL),normalize(VIEW))),2.); ALBEDO=hue.rgb*(.75+.25*COLOR.r); EMISSION=hue.rgb*(.30+.12*sin(TIME*3.)+rim*.85); METALLIC=.30; ROUGHNESS=.21;}
