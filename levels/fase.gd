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
## Porta da saída (arte CC0 do rubberduck, ver assets/CREDITOS.md): com os pés no chão do ponto da porta.
const TEXTURA_PORTA := preload("res://assets/tiles/castelo/porta.png")
## O teto invisível fica isto acima do topo da fase (px): o Atleta que escala não sai do mapa.
const ALTURA_DO_TETO_ACIMA_PX := 96.0
const CAMADA_MUNDO := 1

## Número da fase na campanha (1 a 5). A fase reta de teste fica em 0.
@export var indice: int = 0
## True na última fase: a porta conclui o jogo em vez de abrir a próxima.
@export var ultima: bool = false
## Nome do ambiente, só para leitura (a cor já está nos ladrilhos).
@export var nome_ambiente: String = ""
## Título da missão da fase (ex.: "Limpe a clareira"); o resto do texto vem da Missao.
@export var missao: String = ""
## Quantos pontos de armadilha ocupar ao entrar. Há mais pontos do que este número.
@export var quantidade: int = 0
## Tipos que o sorteio pode colocar: "ooze", "minion", "warrior", "hobgoblin", "bugbear", "kobold".
@export var tipos_permitidos: Array[StringName] = []
## Chefe da fase (id do tipo, ex.: "ankheg"; vazio = sem chefe). Nasce no marcador "Chefe" e entra na cota da porta.
@export var chefe: StringName = &""
## A fase é ao ar livre de dia: quem tem Sensibilidade à Luz Solar (Kobold) ataca com desvantagem.
@export var luz_do_sol: bool = false
## Onde fica a banca do lojista em relação ao ponto de partida (px): à vista, em chão firme e longe do baú (a 70 px do
## começo; as áreas de interação não podem se sobrepor, senão o E abriria a loja em vez do arsenal).
@export var deslocamento_loja: Vector2 = Vector2(250, 0)

@onready var _terreno: TileMapLayer = $Terreno
@onready var _inicio: Marker2D = $InicioJogador


func _ready() -> void:
	_criar_fundo()
	_criar_limites()
	var porta := get_node_or_null("Porta") as Area2D
	if porta == null:
		return
	_desenhar_porta(porta)
	porta.body_entered.connect(_ao_tocar_porta)
	porta.body_exited.connect(_ao_sair_da_porta)


## Fecha o mapa: parede de cada lado e um teto, invisíveis e sem fim, no mesmo mundo do chão. Quem escala
## (Atleta) não passa por cima das paredes das pontas nem sobe para fora da fase.
func _criar_limites() -> void:
	var area := area_jogavel()
	var corpo := StaticBody2D.new()
	corpo.name = "Limites"
	corpo.collision_layer = 1 << (CAMADA_MUNDO - 1)
	corpo.collision_mask = 0
	add_child(corpo)
	_adicionar_plano(corpo, Vector2.RIGHT, area.position.x)  # parede da esquerda: sólido onde x < inicio
	_adicionar_plano(corpo, Vector2.LEFT, -area.end.x)  # parede da direita: sólido onde x > fim
	_adicionar_plano(corpo, Vector2.DOWN, area.position.y - ALTURA_DO_TETO_ACIMA_PX)  # teto: sólido onde y < topo


func _adicionar_plano(corpo: StaticBody2D, normal: Vector2, distancia: float) -> void:
	var forma := CollisionShape2D.new()
	var plano := WorldBoundaryShape2D.new()
	plano.normal = normal
	plano.distance = distancia
	forma.shape = plano
	corpo.add_child(forma)


## A porta de verdade: um sprite de arco de madeira com moldura de pedra, atrás do herói.
func _desenhar_porta(porta: Area2D) -> void:
	var desenho := Sprite2D.new()
	desenho.name = "Desenho"
	desenho.texture = TEXTURA_PORTA
	desenho.position = Vector2(0.0, -TEXTURA_PORTA.get_height() / 2.0)
	desenho.z_index = -1
	porta.add_child(desenho)

## Põe o fundo em camadas do ambiente (se tiver) e esconde o céu liso que ficava no lugar.
func _criar_fundo() -> void:
	var fundo := FundoParalaxe.para_ambiente(nome_ambiente)
	if fundo == null:
		return
	add_child(fundo)
	var ceu := get_node_or_null("Ceu") as CanvasItem
	if ceu:
		ceu.hide()


func posicao_inicio() -> Vector2:
	return _inicio.global_position


## Onde a porta espera o herói. Sem porta, devolve o início.
func posicao_porta() -> Vector2:
	var porta := get_node_or_null("Porta") as Node2D
	if porta == null:
		return posicao_inicio()
	return porta.global_position


## Onde o chefe nasce (o marcador "Chefe"). Sem marcador, devolve o início.
func posicao_chefe() -> Vector2:
	var marcador := get_node_or_null("Chefe") as Node2D
	return marcador.global_position if marcador else posicao_inicio()


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
