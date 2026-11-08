class_name TelaPausa
extends Control
## Menu de pausa (aberto pela `main` com Esc ou com o botão Menu no celular; Esc ou Menu de novo fecham): Continuar, Mochila, Opções, Salvar e
## Menu principal. Pausa o jogo enquanto está aberto. Não conhece o herói: avisa quem montou o
## jogo pelos sinais e a `main` responde.

signal mochila_escolhida
signal bestiario_escolhido
signal compendio_escolhido
signal habilidades_escolhidas
signal opcoes_escolhidas
signal salvar_escolhido
## O jogador confirmou que quer voltar ao título.
signal titulo_escolhido
## Ao fechar, para quem controla a interface de toque.
signal fechou

@onready var _aviso: Label = %Aviso
@onready var _botao_continuar: Button = %Continuar
@onready var _botao_mochila: Button = %Mochila
@onready var _botao_bestiario: Button = %Bestiario
@onready var _botao_compendio: Button = %Compendio
@onready var _botao_habilidades: Button = %Habilidades
@onready var _botao_opcoes: Button = %Opcoes
@onready var _botao_salvar: Button = %Salvar
@onready var _botao_titulo: Button = %Titulo
@onready var _confirmacao: ConfirmationDialog = %Confirmacao


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_botao_continuar.pressed.connect(fechar)
	_botao_mochila.pressed.connect(_escolher.bind(mochila_escolhida))
	_botao_habilidades.pressed.connect(_escolher.bind(habilidades_escolhidas))
	_botao_bestiario.pressed.connect(_escolher.bind(bestiario_escolhido))
	_botao_compendio.pressed.connect(_escolher.bind(compendio_escolhido))
	_botao_opcoes.pressed.connect(_escolher.bind(opcoes_escolhidas))
	_botao_salvar.pressed.connect(salvar_escolhido.emit)
	_botao_titulo.pressed.connect(_confirmacao.popup_centered)
	_confirmacao.confirmed.connect(titulo_escolhido.emit)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and (evento.is_action_pressed(&"pausa") or evento.is_action_pressed(&"ui_cancel")):
		fechar()
		get_viewport().set_input_as_handled()


func abrir() -> void:
	_aviso.text = ""
	show()
	_botao_continuar.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


## Mensagem curta embaixo dos botões (ex.: "Jogo salvo").
func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto


## Abre outra tela por cima: esta se esconde sem despausar (a outra tela cuida da pausa).
func _escolher(sinal: Signal) -> void:
	hide()
	sinal.emit()
