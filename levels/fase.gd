class_name Fase
extends Node2D
## Script raiz de uma fase: diz onde o herói começa e qual o tamanho jogável.
## Quem usa a fase fala só com estas funções, nunca com os nós internos.

## Margem abaixo do fundo da fase para considerar que o herói caiu num buraco (px).
const MARGEM_QUEDA := 64.0
## Ladrilhos de parede em cada ponta, que a câmera não deve mostrar.
const PAREDES_POR_LADO := 1

@onready var _terreno: TileMapLayer = $Terreno
@onready var _inicio: Marker2D = $InicioJogador


func posicao_inicio() -> Vector2:
	return _inicio.global_position


## Área jogável em pixels: sem as paredes das pontas e sem o céu acima da fase.
func area_jogavel() -> Rect2:
	var celulas := _terreno.get_used_rect()
	var tam := Vector2(_terreno.tile_set.tile_size)
	return Rect2(
		Vector2(celulas.position.x + PAREDES_POR_LADO, 0) * tam,
		Vector2(celulas.size.x - 2 * PAREDES_POR_LADO, celulas.end.y) * tam)


## Altura (Y) abaixo da qual o herói caiu para fora da fase.
func limite_queda() -> float:
	return area_jogavel().end.y + MARGEM_QUEDA
