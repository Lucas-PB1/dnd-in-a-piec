class_name TelaTitulo
extends Control
## Tela de título: nome do jogo (vem do project.godot), Continuar, Novo Jogo, Compêndio, Opções e Sair.
## Não decide nada: só avisa quem montou o jogo pelos sinais.

## Emitido ao escolher "Continuar" (só fica ativo se há jogo salvo).
signal continuar_escolhido
## Emitido ao escolher "Novo Jogo".
signal novo_jogo_escolhido
## Emitido ao escolher "Opções".
signal opcoes_escolhidas
## Emitido ao escolher "Compêndio".
signal compendio_escolhido
## Emitido ao escolher "Sair".
signal sair_escolhido

@onready var _titulo: Label = %Titulo
@onready var _botao_continuar: Button = %Continuar
@onready var _botao_novo: Button = %NovoJogo
@onready var _botao_opcoes: Button = %Opcoes
@onready var _botao_compendio: Button = %Compendio
@onready var _botao_sair: Button = %Sair


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	_titulo.text = ProjectSettings.get_setting("application/config/name")
	_botao_continuar.pressed.connect(continuar_escolhido.emit)
	_botao_novo.pressed.connect(novo_jogo_escolhido.emit)
	_botao_opcoes.pressed.connect(opcoes_escolhidas.emit)
	_botao_compendio.pressed.connect(compendio_escolhido.emit)
	_botao_sair.pressed.connect(sair_escolhido.emit)
	mostrar_continuar(false)


## Liga o botão Continuar se há jogo salvo; sem save ele fica apagado e o foco vai para Novo Jogo.
func mostrar_continuar(ha_jogo_salvo: bool) -> void:
	_botao_continuar.disabled = not ha_jogo_salvo
	if ha_jogo_salvo:
		_botao_continuar.grab_focus()
	else:
		_botao_novo.grab_focus()
