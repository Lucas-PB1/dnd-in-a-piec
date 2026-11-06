class_name Hud
extends CanvasLayer
## Informações na tela durante o jogo: nome e classe do personagem e pontos de vida.


@onready var _personagem: Label = %Personagem
@onready var _vida: Label = %Vida
@onready var _folego: Label = %Folego


## Mostra "Nome (Classe)".
func mostrar_personagem(nome: String, classe: String) -> void:
	_personagem.text = "%s (%s)" % [nome, classe]


## Mostra a vida no formato "PV 12/12".
func mostrar_vida(atual: int, maxima: int) -> void:
	_vida.text = "PV %d/%d" % [atual, maxima]


## Mostra os usos do Second Wind ("Fôlego 2/2"). Total 0 some com a linha.
func mostrar_folego(restantes: int, total: int) -> void:
	if total <= 0:
		_folego.text = ""
		return
	_folego.text = "Fôlego %d/%d" % [restantes, total]
