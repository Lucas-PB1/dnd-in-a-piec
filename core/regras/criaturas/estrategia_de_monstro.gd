class_name EstrategiaDeMonstro
extends RefCounted
## Escolhas de estratégia dos monstros, só com os números da ficha (nada de trapaça): onde vale lutar e quando recuar.
## Regra pura, sem nós.

## Vida (fração da máxima) em que o monstro ferido pensa em recuar para perto dos aliados.
const FRACAO_FERIDO := 1.0 / 3.0
## Desnível mínimo (px, 1 ladrilho) para contar como vantagem de terreno (Y do Godot cresce para baixo).
const DESNIVEL_VANTAGEM_PX := 32.0


## Vale manter distância quando o ataque à distância bate pelo menos tanto quanto o corpo a corpo: atirar de longe
## tem o mesmo dano sem o risco. Sem ataque à distância (dano 0), luta de perto.
static func prefere_distancia(dano_corpo_a_corpo: float, dano_a_distancia: float) -> bool:
	return dano_a_distancia > 0.0 and dano_a_distancia >= dano_corpo_a_corpo


## Ferido (1/3 da vida ou menos) e com aliado vivo por perto: recua para junto dele. Sozinho, luta até o fim.
static func deve_recuar_ferido(vida: int, vida_maxima: int, aliados_vivos: int) -> bool:
	return aliados_vivos > 0 and vida_maxima > 0 and vida > 0 and vida <= vida_maxima * FRACAO_FERIDO


## Está no alto em relação ao alvo (≥ 1 ladrilho). Atirador/arremessador usa isso para não descer sem necessidade.
static func vantagem_de_terreno(y_proprio: float, y_alvo: float,
		desnivel_min_px: float = DESNIVEL_VANTAGEM_PX) -> bool:
	return y_alvo - y_proprio >= desnivel_min_px


## Tem ataque à distância, está no alto e o alvo ainda não alcança o corpo a corpo: fica e atira/arremessa.
static func quer_manter_altura(tem_ataque_a_distancia: bool, no_alto: bool, alvo_ao_alcance: bool) -> bool:
	return tem_ataque_a_distancia and no_alto and not alvo_ao_alcance
