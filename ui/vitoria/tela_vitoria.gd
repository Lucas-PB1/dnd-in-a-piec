class_name TelaVitoria
extends Control
## Vitória final: epílogo (tom da intro), placar da run e opções Menu / Jogar de novo.
## Não decide nada: só avisa pelos sinais. Funciona com o jogo pausado.

## Emitido ao escolher "Jogar de novo".
signal jogar_de_novo_escolhido
## Emitido ao escolher "Menu" (volta ao título).
signal menu_escolhido

@onready var _titulo: Label = %Titulo
@onready var _epilogo: Label = %Epilogo
@onready var _resumo: Label = %Resumo
@onready var _jogar: Button = %JogarDeNovo
@onready var _menu: Button = %Menu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_jogar.pressed.connect(jogar_de_novo_escolhido.emit)
	_menu.pressed.connect(menu_escolhido.emit)
	_jogar.grab_focus()


## Preenche título e epílogo a partir do Resource.
func configurar(lore: IntroLoreRPG) -> void:
	if lore == null:
		return
	if not lore.titulo.is_empty():
		_titulo.text = lore.titulo
	if not lore.texto.is_empty():
		_epilogo.text = lore.texto
		_epilogo.visible = true


## Abates e tempos da run (a `main` monta o texto).
func mostrar_resumo(texto: String) -> void:
	_resumo.text = texto
	_resumo.visible = texto != ""
