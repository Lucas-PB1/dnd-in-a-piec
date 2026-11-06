class_name TelaTitulo
extends Control
## Tela de título: nome do jogo (vem do project.godot), Novo Jogo e Sair.
## Não decide nada: só avisa quem montou o jogo pelos sinais.

## Emitido ao escolher "Novo Jogo".
signal novo_jogo_escolhido
## Emitido ao escolher "Sair".
signal sair_escolhido

@onready var _titulo: Label = %Titulo
@onready var _botao_novo: Button = %NovoJogo
@onready var _botao_sair: Button = %Sair


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	_titulo.text = ProjectSettings.get_setting("application/config/name")
	_botao_novo.pressed.connect(novo_jogo_escolhido.emit)
	_botao_sair.pressed.connect(sair_escolhido.emit)
	_botao_novo.grab_focus()
