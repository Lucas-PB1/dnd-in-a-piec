class_name TelaDerrota
extends Control
## Tela "Você caiu!": escurece o jogo e oferece "Tentar de novo". Não decide nada: só avisa
## pelo sinal. Funciona com o jogo pausado.

## Emitido ao escolher "Tentar de novo".
signal tentar_de_novo_escolhido

@onready var _subtitulo: Label = %Subtitulo
@onready var _resumo: Label = %Resumo
@onready var _botao: Button = %TentarDeNovo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_botao.pressed.connect(tentar_de_novo_escolhido.emit)
	_botao.grab_focus()


## Mostra quem caiu (ex.: "Aldric, o Guerreiro, foi derrotado.").
func mostrar_personagem(nome: String, classe: String) -> void:
	_subtitulo.text = "%s, o %s, foi derrotado." % [nome, classe]


## Abates e tempos até a queda (a `main` monta o texto).
func mostrar_resumo(texto: String) -> void:
	_resumo.text = texto
	_resumo.visible = texto != ""
