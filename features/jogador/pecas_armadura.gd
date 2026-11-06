class_name PecasArmadura
extends Node2D
## Peças da armadura desenhadas por cima do corpo do herói: ombreira no ombro da frente,
## saiote pendurado no cinto e elmo sobre o cabelo. Cada peça segue o seu ponto do corpo
## em cada quadro (PontosMao: ombros, cinturas, cabecas). O dono chama vestir() quando o
## equipamento muda e seguir() todo quadro (call down).

## Do ombro da frente até o centro da ombreira (px, herói olhando para a direita).
const DO_OMBRO := Vector2(-3.0, 2.0)
## Do cinto até o centro do saiote: logo abaixo do cinto.
const DO_CINTO := Vector2(0.0, 6.0)
## Do topo da cabeça até o centro do elmo: a cúpula cobre o cabelo de cima.
const DA_CABECA := Vector2(1.0, 14.0)

var _ombreira := Sprite2D.new()
var _saiote := Sprite2D.new()
var _elmo := Sprite2D.new()


func _ready() -> void:
	for peca in [_saiote, _ombreira, _elmo]:  # o saiote fica por baixo das outras
		add_child(peca)
	vestir(null)


## Mostra as peças da `armadura` (null = nenhuma).
func vestir(armadura: Armadura) -> void:
	_mostrar(_ombreira, armadura.ombreira if armadura else null)
	_mostrar(_saiote, armadura.saiote if armadura else null)
	_mostrar(_elmo, armadura.elmo if armadura else null)


## Pontos em pixels, relativos aos pés, já espelhados. `direcao`: 1 direita, -1 esquerda.
func seguir(ombro: Vector2, cintura: Vector2, cabeca: Vector2, direcao: int) -> void:
	_por(_ombreira, ombro, DO_OMBRO, direcao)
	_por(_saiote, cintura, DO_CINTO, direcao)
	_por(_elmo, cabeca, DA_CABECA, direcao)


func _mostrar(peca: Sprite2D, textura: Texture2D) -> void:
	peca.texture = textura
	peca.visible = textura != null


func _por(peca: Sprite2D, ponto: Vector2, deslocamento: Vector2, direcao: int) -> void:
	peca.position = ponto + Vector2(deslocamento.x * direcao, deslocamento.y)
	peca.flip_h = direcao < 0
