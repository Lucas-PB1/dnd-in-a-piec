class_name TaticasDeMatilha
extends RefCounted
## Táticas de Matilha (Hobgoblin, Kobold): vantagem no ataque contra uma criatura se pelo menos um aliado de quem
## ataca estiver a até 5 pés dela e não estiver Incapacitado. Regra pura: quem chama diz onde estão os aliados em pé.

const ALCANCE_PES := 5.0


## `aliados_em_pe` = posições dos aliados que podem agir (sem Caídos nem mortos).
static func vale(alvo: Vector2, aliados_em_pe: Array[Vector2]) -> bool:
	var alcance := EscalaDnd.pes_para_pixels(ALCANCE_PES)
	for posicao in aliados_em_pe:
		if posicao.distance_to(alvo) <= alcance:
			return true
	return false
