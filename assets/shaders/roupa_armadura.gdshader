shader_type canvas_item;
// Pinta a túnica azul do herói com a armadura vestida, mantendo a luz e a sombra da arte.
// Pixels "azuis" (azul bem maior que vermelho e verde) são a túnica. Se a armadura tem um
// ladrilho de `detalhe` (anéis, placas, costuras...), ele é repetido pela roupa; senão, a cor lisa.
// Contraste e brilho nas áreas claras dão mais "peso" metálico/couro.

uniform bool vestida = false;
uniform vec4 cor_armadura : source_color = vec4(0.6, 0.6, 0.65, 1.0);
uniform bool tem_detalhe = false;
uniform sampler2D detalhe : source_color, filter_nearest, repeat_enable;
// Quanto o azul precisa passar do vermelho/verde para contar como túnica.
uniform float limite_azul = 0.1;
// Brilho do tom médio da túnica original (para normalizar a luz).
uniform float brilho_referencia = 0.403;
// Contraste em torno do cinza médio (1 = neutro; >1 = mais marcante).
uniform float contraste = 1.25;
// A partir desta luz (após normalizar) começa o brilho especular.
uniform float limiar_brilho = 1.05;
uniform float forca_brilho = 1.8;
uniform float max_brilho = 0.35;

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
		vec3 tom = clamp(cor * luz, 0.0, 1.0);
		tom = clamp((tom - vec3(0.5)) * contraste + vec3(0.5), 0.0, 1.0);
		if (luz > limiar_brilho) {
			float brilho = clamp((luz - limiar_brilho) * forca_brilho, 0.0, max_brilho);
			tom = mix(tom, vec3(1.0), brilho);
		}
		COLOR.rgb = tom;
	}
}
