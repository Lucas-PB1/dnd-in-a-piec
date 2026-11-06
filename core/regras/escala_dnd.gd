class_name EscalaDnd
extends RefCounted
## Conversão das medidas do D&D para o jogo. Um quadrado de 5 pés = 1 ladrilho (32 px).
## Uma rodada (6 s no D&D) dura RODADA_SEGUNDOS no jogo, para o combate ter ritmo de ação.

const PES_POR_LADRILHO := 5.0
const PIXELS_POR_LADRILHO := 32.0
const RODADA_SEGUNDOS := 1.5


static func pes_para_pixels(pes: float) -> float:
	return pes / PES_POR_LADRILHO * PIXELS_POR_LADRILHO


## Deslocamento por rodada (pés) -> velocidade no jogo (pixels por segundo).
static func deslocamento_para_velocidade(pes_por_rodada: float) -> float:
	return pes_para_pixels(pes_por_rodada) / RODADA_SEGUNDOS
