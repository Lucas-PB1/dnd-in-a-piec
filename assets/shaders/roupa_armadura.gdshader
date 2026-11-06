shader_type canvas_item;
// Pinta a túnica azul do herói com a armadura vestida, mantendo a luz e a sombra da arte.
// Pixels "azuis" (azul bem maior que vermelho e verde) são a túnica.
// padrao: 0 liso, 1 malha, 2 tachas, 3 placas, 4 acolchoado, 5 escamas (Armadura.Padrao).

uniform bool vestida = false;
uniform vec4 cor_armadura : source_color = vec4(0.6, 0.6, 0.65, 1.0);
uniform int padrao = 0;
// Quanto o azul precisa passar do vermelho/verde para contar como túnica.
uniform float limite_azul = 0.1;
// Brilho do tom médio da túnica original (para normalizar a luz).
uniform float brilho_referencia = 0.403;

const vec3 PESOS_BRILHO = vec3(0.3, 0.59, 0.11);
const vec3 COR_TACHA = vec3(0.86, 0.8, 0.58);

float detalhe(vec2 px) {
	if (padrao == 1) { // malha: xadrez miudinho
		return mod(px.x + px.y, 2.0) < 1.0 ? 1.18 : 0.82;
	}
	if (padrao == 3) { // placas: emenda escura e borda brilhante
		float linha = mod(px.y, 5.0);
		return linha < 1.0 ? 0.68 : (linha < 2.0 ? 1.28 : 1.0);
	}
	if (padrao == 4) { // acolchoado: costuras em grade
		return (mod(px.x, 4.0) < 1.0 || mod(px.y, 4.0) < 1.0) ? 0.82 : 1.0;
	}
	if (padrao == 5) { // escamas: fileiras desencontradas
		float fileira = floor(px.y / 3.0);
		return (mod(px.y, 3.0) < 1.0 && mod(px.x + fileira * 2.0, 4.0) < 2.0) ? 0.72 : 1.05;
	}
	return 1.0;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	COLOR = original;
	float azul = original.b - max(original.r, original.g);
	if (vestida && original.a > 0.5 && azul > limite_azul) {
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		float luz = clamp(dot(original.rgb, PESOS_BRILHO) / brilho_referencia, 0.3, 1.3);
		vec3 cor = cor_armadura.rgb * luz * detalhe(px);
		if (padrao == 2 && mod(px.x, 4.0) < 1.0 && mod(px.y, 4.0) < 1.0) {
			cor = COR_TACHA * luz; // tachas de metal
		}
		COLOR.rgb = clamp(cor, 0.0, 1.0);
	}
}
