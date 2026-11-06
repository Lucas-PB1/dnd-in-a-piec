class_name Hud
extends CanvasLayer
## Informações na tela durante o jogo: nome e classe do personagem e pontos de vida.


@onready var _personagem: Label = %Personagem
@onready var _vida: Label = %Vida


## Mostra "Nome (Classe)".
func mostrar_personagem(nome: String, classe: String) -> void:
	_personagem.text = "%s (%s)" % [nome, classe]


## Mostra a vida no formato "PV 12/12".
func mostrar_vida(atual: int, maxima: int) -> void:
	_vida.text = "PV %d/%d" % [atual, maxima]
