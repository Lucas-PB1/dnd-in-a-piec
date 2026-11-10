class_name SaltoDnd
extends RefCounted
## Regra pura do salto dos monstros: o quanto cada criatura salta (Força, como no livro) e o que fazer diante do
## terreno à frente (degrau, buraco ou queda). Sem nós: recebe o perfil do chão e devolve um plano.
##
## Livro (PHB 2024, Salto): salto em altura = 3 pés + mod. de Força; salto em distância = valor de Força em pés
## (os dois com 10 pés de corrida, o que a perseguição já dá).
## Regras da casa (aprovadas pelo usuário em 2026-11-09): o monstro se apoia com os braços (ALCANCE_DOS_BRACOS_PES) para subir num
## degrau; e desce até QUEDA_SEGURA_PES sem se machucar, só quando o alvo está mais embaixo.

enum Tipo { NENHUM, SUBIR, VAO, DESCER }

## Quanto além do salto em altura o monstro alcança agarrando a borda (pés).
const ALCANCE_DOS_BRACOS_PES := 3.0
## Queda que o monstro aceita para chegar ao alvo (pés).
const QUEDA_SEGURA_PES := 15.0
## Diferença de altura (px) que ainda conta como "o mesmo nível".
const TOLERANCIA_PX := 4.0
## Queda pequena (px) que o monstro desce mesmo sem o alvo estar embaixo.
const QUEDA_PEQUENA_PX := 32.0
## Valores especiais do perfil: sem chão na sondagem e parede alta demais (ou teto baixo).
const SEM_CHAO := -1.0e9
const MURO := 1.0e9


## O que fazer: o tipo, a distância horizontal até o pouso (px) e o desnível do pouso (px, positivo = mais alto).
class Plano:
	var tipo: Tipo = Tipo.NENHUM
	var distancia_px: float = 0.0
	var desnivel_px: float = 0.0

	func _init(tipo_do_plano: Tipo = Tipo.NENHUM, distancia: float = 0.0, desnivel: float = 0.0) -> void:
		tipo = tipo_do_plano
		distancia_px = distancia
		desnivel_px = desnivel


## Degrau mais alto que o monstro sobe (px).
static func altura_px(forca: int) -> float:
	var pes := 3.0 + Atributos.modificador(forca) + ALCANCE_DOS_BRACOS_PES
	return EscalaDnd.pes_para_pixels(maxf(pes, 0.0))


## Vão mais largo que o monstro atravessa (px).
static func distancia_px(forca: int) -> float:
	return EscalaDnd.pes_para_pixels(float(forca))


static func queda_segura_px() -> float:
	return EscalaDnd.pes_para_pixels(QUEDA_SEGURA_PES)


## `perfil`: altura do chão (relativa aos pés; positivo = mais alto) a cada `passo_px`, a partir de `inicio_px` à
## frente. `alvo_embaixo`: o alvo está bem abaixo dos pés (vale a pena descer).
static func planejar(perfil: Array[float], passo_px: float, inicio_px: float, altura_max: float, distancia_max: float,
		alvo_embaixo: bool) -> Plano:
	if perfil.is_empty() or perfil[0] == MURO:
		return Plano.new()
	if perfil[0] > TOLERANCIA_PX:
		return Plano.new(Tipo.SUBIR, inicio_px, perfil[0]) if perfil[0] <= altura_max else Plano.new()
	if perfil[0] > -TOLERANCIA_PX:
		return Plano.new()
	return _procurar_pouso(perfil, passo_px, inicio_px, altura_max, distancia_max, alvo_embaixo)


static func _procurar_pouso(perfil: Array[float], passo_px: float, inicio_px: float, altura_max: float,
		distancia_max: float, alvo_embaixo: bool) -> Plano:
	for i in perfil.size():
		var altura := perfil[i]
		var distancia := inicio_px + i * passo_px
		if altura == MURO or distancia > distancia_max or altura > altura_max:
			return Plano.new()
		if altura == SEM_CHAO:
			continue
		if altura < -queda_segura_px():
			return Plano.new()
		if i > 0:
			return Plano.new(Tipo.VAO, distancia, altura)
		var vale_descer := alvo_embaixo or altura >= -QUEDA_PEQUENA_PX
		return Plano.new(Tipo.DESCER, distancia, altura) if vale_descer else Plano.new()
	return Plano.new()
