class_name BuscaDeAbrigo
extends RefCounted
## Procura, andando para os dois lados, um ponto onde a parede protege do atirador. Junta o sensor (física) e a
## regra pura `Abrigo`.

## Quanto o chão pode variar entre passos para ainda ser "andável" (px).
const VARIACAO_ANDAVEL_PX := 4.0


## X de um abrigo alcançável a pé em até `quantidade` passos de `passo_px`, ou NAN se não houver.
## `pe`: pés de quem procura; `peito`: altura do peito acima dos pés; `origem_tiro`: de onde vem o ataque.
static func procurar(espaco: PhysicsDirectSpaceState2D, pe: Vector2, peito: float, origem_tiro: Vector2, passo_px: float,
		quantidade: int, mascara: int) -> float:
	var esquerda := _passos(espaco, pe, peito, origem_tiro, -1.0, passo_px, quantidade, mascara)
	var direita := _passos(espaco, pe, peito, origem_tiro, 1.0, passo_px, quantidade, mascara)
	var oposto := -1 if origem_tiro.x > pe.x else 1
	var lado := Abrigo.escolher_lado(esquerda, direita, oposto)
	if lado == 0:
		return NAN
	return pe.x + lado * (maxi(esquerda if lado < 0 else direita, 0) + 1) * passo_px


static func _passos(espaco: PhysicsDirectSpaceState2D, pe: Vector2, peito: float, origem_tiro: Vector2, direcao: float,
		passo_px: float, quantidade: int, mascara: int) -> int:
	var chao := SensorDeTerreno.perfil(espaco, pe, direcao, passo_px, passo_px, quantidade, VARIACAO_ANDAVEL_PX,
		VARIACAO_ANDAVEL_PX, mascara)
	var protegido: Array[bool] = []
	var andavel: Array[bool] = []
	for i in quantidade:
		var x := pe.x + direcao * (i + 1) * passo_px
		andavel.append(absf(chao[i]) <= VARIACAO_ANDAVEL_PX)
		protegido.append(not SensorDeTerreno.linha_livre(espaco, origem_tiro, Vector2(x, pe.y - peito), mascara))
	return Abrigo.passos_ate_abrigo(protegido, andavel)
