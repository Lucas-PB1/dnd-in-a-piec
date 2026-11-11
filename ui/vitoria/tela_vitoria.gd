class_name TelaVitoria
extends Control
## Tela "Fase concluída": escurece o jogo e oferece "Jogar de novo". Não decide nada:
## só avisa pelo sinal. Funciona com o jogo pausado.

## Emitido ao escolher "Jogar de novo".
signal jogar_de_novo_escolhido

@onready var _resumo: Label = %Resumo
@onready var _botao: Button = %JogarDeNovo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_botao.pressed.connect(jogar_de_novo_escolhido.emit)
	_botao.grab_focus()


## Abates e tempos da run (a `main` monta o texto).
func mostrar_resumo(texto: String) -> void:
	_resumo.text = texto
	_resumo.visible = texto != ""
