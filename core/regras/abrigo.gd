class_name Abrigo
extends RefCounted
## Regra pura da cobertura: dado o chão à frente (andável ou não) e quais pontos estão protegidos do atirador,
## diz quantos passos faltam até o abrigo mais próximo e para que lado ir. Sem nós.

## Para um lado, em passos de `passo_px`: `protegido[i]` = o ponto i está fora da linha de tiro; `andavel[i]` = dá para
## chegar a ele andando (chão plano, sem parede no caminho). Devolve o índice do 1º abrigo alcançável, ou -1.
static func passos_ate_abrigo(protegido: Array[bool], andavel: Array[bool]) -> int:
	for i in protegido.size():
		if not andavel[i]:
			return -1
		if protegido[i]:
			return i
	return -1


## Lado a seguir (-1 esquerda, 1 direita, 0 nenhum). O mais perto ganha; no empate, o lado oposto ao atirador.
static func escolher_lado(passos_esquerda: int, passos_direita: int, lado_oposto_ao_atirador: int) -> int:
	if passos_esquerda < 0 and passos_direita < 0:
		return 0
	if passos_esquerda < 0:
		return 1
	if passos_direita < 0:
		return -1
	if passos_esquerda == passos_direita:
		return lado_oposto_ao_atirador
	return -1 if passos_esquerda < passos_direita else 1
