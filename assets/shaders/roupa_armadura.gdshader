shader_type canvas_item;
// Pinta a túnica azul do herói com a armadura vestida, mantendo a luz e a sombra da arte.
// Pixels "azuis" (azul bem maior que vermelho e verde) são a túnica. Se a armadura tem um
// ladrilho de `detalhe` (anéis, placas, costuras...), ele é repetido pela roupa; senão, a cor lisa.

uniform bool vestida = false;
uniform vec4 cor_armadura : source_color = vec4(0.6, 0.6, 0.65, 1.0);
uniform bool tem_detalhe = false;
uniform sampler2D detalhe : source_color, filter_nearest, repeat_enable;
// Quanto o azul precisa passar do vermelho/verde para contar como túnica.
uniform float limite_azul = 0.1;
// Brilho do tom médio da túnica original (para normalizar a luz).
uniform float brilho_referencia = 0.403;

const vec3 PESOS_BRILHO = vec3(0.3, 0.59, 0.11);

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	COLOR = original;
	float azul = original.b - max(original.r, original.g);
	if (vestida && original.a > 0.5 && azul > limite_azul) {
		float luz = clamp(dot(original.rgb, PESOS_BRILHO) / brilho_referencia, 0.3, 1.3);
		vec3 cor = cor_armadura.rgb;
		if (tem_detalhe) {
			ivec2 px = ivec2(floor(UV / TEXTURE_PIXEL_SIZE));
			ivec2 tamanho = textureSize(detalhe, 0);
			cor = texelFetch(detalhe, ivec2(px.x % tamanho.x, px.y % tamanho.y), 0).rgb;
		}
		COLOR.rgb = clamp(cor * luz, 0.0, 1.0);
	}
}
