class_name TelaRelatorioFalha
extends Control
## Aviso de que o jogo fechou sozinho da última vez, com o relatório (últimos passos e o fim do
## log) para o jogador copiar e mandar. Monta os nós por código. Não sabe de onde vem o texto:
## quem abre passa em mostrar(). Funciona com o jogo pausado.

## Emitido ao fechar (Fechar ou depois de Copiar).
signal fechou

const TEMA := preload("res://ui/tema_menu.tres")
const TITULO := "O jogo fechou sozinho da última vez"
const DICA := "Toque em Copiar e mande o texto: ele mostra o que estava acontecendo."
const TEXTO_COPIADO := "Copiado!"
const TAMANHO_PAINEL := Vector2(560, 300)
const TAMANHO_FONTE_RELATORIO := 9
const COR_FUNDO := Color(0, 0, 0, 0.7)
const TAMANHO_BOTAO := Vector2(120, 32)

var _texto: TextEdit
var _copiar: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = TEMA
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_montar()


## Mostra o relatório.
func mostrar(relatorio: String) -> void:
	_texto.text = relatorio
	show()
	_copiar.grab_focus()


## Põe o relatório na área de transferência (no celular também).
func copiar() -> void:
	DisplayServer.clipboard_set(_texto.text)
	_copiar.text = TEXTO_COPIADO


func fechar() -> void:
	hide()
	fechou.emit()


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size = TAMANHO_PAINEL
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	painel.add_child(coluna)
	coluna.add_child(_rotulo(TITULO, &"Titulo"))
	coluna.add_child(_rotulo(DICA, &"Dica"))
	_texto = TextEdit.new()
	_texto.name = "Relatorio"
	_texto.editable = false
	_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_texto.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_RELATORIO)
	coluna.add_child(_texto)
	var rodape := HBoxContainer.new()
	rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_child(rodape)
	_copiar = _botao("Copiar", copiar)
	rodape.add_child(_copiar)
	rodape.add_child(_botao("Fechar", fechar))


func _rotulo(texto: String, variacao: StringName) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = variacao
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return rotulo


func _botao(texto: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.name = texto
	botao.text = texto
	botao.custom_minimum_size = TAMANHO_BOTAO
	botao.pressed.connect(ao_apertar)
	return botao
