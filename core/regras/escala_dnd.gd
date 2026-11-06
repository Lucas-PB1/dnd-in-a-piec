class_name EscalaDnd
extends RefCounted
## Conversão das medidas do D&D para o jogo.
## Distância: um quadrado de 5 pés = 1 ladrilho (32 px).
## Movimento: o deslocamento (pés por rodada) vira velocidade na tela; uma rodada dura
## RODADA_SEGUNDOS no jogo.
## Ataque: o ritmo vem da INICIATIVA, contado em tiques. Intervalo entre ataques =
## (TIQUES_BASE_ATAQUE - iniciativa) tiques; quanto maior a iniciativa, mais rápido bate.

const PES_POR_LADRILHO := 5.0
const PIXELS_POR_LADRILHO := 32.0
const RODADA_SEGUNDOS := 1.5

const SEGUNDOS_POR_TIQUE := 0.1
## Iniciativa 0 ataca a cada 10 tiques (1,0 s).
const TIQUES_BASE_ATAQUE := 10
## Ninguém ataca mais rápido que isso, mesmo com iniciativa muito alta.
const TIQUES_MINIMOS_ATAQUE := 3
## Disparada (Dash) do D&D: correndo, o deslocamento dobra.
const MULTIPLICADOR_DISPARADA := 2.0
## Até onde a ponta da arma tem de chegar à frente da mão num golpe de 5 pés (px). Com
## Alcance (Reach), 1 ladrilho a mais. Armas curtas dão um passo para chegar lá.
const PONTA_5_PES := 44.0


static func pes_para_pixels(pes: float) -> float:
	return pes / PES_POR_LADRILHO * PIXELS_POR_LADRILHO


## Deslocamento por rodada (pés) -> velocidade no jogo (pixels por segundo).
static func deslocamento_para_velocidade(pes_por_rodada: float) -> float:
	return pes_para_pixels(pes_por_rodada) / RODADA_SEGUNDOS


## Quantos tiques entre um ataque e o próximo, para a `iniciativa` dada.
static func tiques_entre_ataques(iniciativa: int) -> int:
	return maxi(TIQUES_BASE_ATAQUE - iniciativa, TIQUES_MINIMOS_ATAQUE)


## Segundos entre um ataque e o próximo. Ex.: +2 -> 0,8 s; -2 -> 1,2 s.
static func intervalo_ataque(iniciativa: int) -> float:
	return tiques_entre_ataques(iniciativa) * SEGUNDOS_POR_TIQUE
