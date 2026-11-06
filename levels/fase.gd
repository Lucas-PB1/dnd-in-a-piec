class_name Fase
extends Node2D
## Script raiz de uma fase: início, pontos de armadilha e a porta.
## Quem usa a fase fala só com estas funções, nunca com os nós internos.

## Emitido quando um corpo entra na porta. A main decide se a cota deixa passar.
signal porta_tocada(corpo: Node2D)
## Emitido quando esse corpo sai da porta.
signal porta_liberada(corpo: Node2D)

## Margem abaixo do fundo da fase para considerar que o herói caiu num buraco (px).
const MARGEM_QUEDA := 64.0
## Ladrilhos de parede em cada ponta, que a câmera não deve mostrar.
const PAREDES_POR_LADO := 1

## Número da fase na campanha (1 a 5). A fase reta de teste fica em 0.
@export var indice: int = 0
## True na última fase: a porta conclui o jogo em vez de abrir a próxima.
@export var ultima: bool = false
## Nome do ambiente, só para leitura (a cor já está nos ladrilhos).
@export var nome_ambiente: String = ""
## Quantos pontos de armadilha ocupar ao entrar. Há mais pontos do que este número.
@export var quantidade: int = 0
## Tipos que o sorteio pode colocar: "ooze", "minion", "warrior".
@export var tipos_permitidos: Array[StringName] = []

@onready var _terreno: TileMapLayer = $Terreno
@onready var _inicio: Marker2D = $InicioJogador


func _ready() -> void:
	var porta := get_node_or_null("Porta") as Area2D
	if porta == null:
		return
	porta.body_entered.connect(_ao_tocar_porta)
	porta.body_exited.connect(_ao_sair_da_porta)


func posicao_inicio() -> Vector2:
	return _inicio.global_position


## Onde a porta espera o herói. Sem porta, devolve o início.
func posicao_porta() -> Vector2:
	var porta := get_node_or_null("Porta") as Node2D
	if porta == null:
		return posicao_inicio()
	return porta.global_position


## Pontos onde um inimigo pode nascer, da esquerda para a direita.
func pontos_armadilha() -> Array[Vector2]:
	var pontos: Array[Vector2] = []
	for no in get_children():
		if no is Marker2D and no.is_in_group(&"armadilha"):
			pontos.append((no as Marker2D).global_position)
	pontos.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	return pontos


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


func _ao_tocar_porta(corpo: Node2D) -> void:
	porta_tocada.emit(corpo)


func _ao_sair_da_porta(corpo: Node2D) -> void:
	porta_liberada.emit(corpo)
