class_name Municao
extends Item
## Munição empilhável (flecha, virote, pedra, agulha, bala). O disparo gasta 1 e esta
## imagem é o que voa. Não se equipa.

## Sprite do projétil (pode ser maior que o ícone do menu).
@export var textura: Texture2D
## Para onde a ponta aponta NA IMAGEM (graus; 0 = direita, -45 = para cima e à direita).
@export var angulo_arte: float = 0.0


func _init() -> void:
	empilhavel = true
	espaco = &""
