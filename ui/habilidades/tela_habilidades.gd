class_name TelaHabilidades
extends Control
## Árvore de habilidades da classe: o que o herói já tem, o que chega em cada nível e o que ainda
## não existe no jogo. Escolher uma habilidade mostra a descrição ao lado. Pausa o jogo. Não conhece
## o herói: a `main` entrega a classe e a ficha.

## Emitido ao fechar a tela, para quem controla a interface de toque.
signal fechou

var _ficha: Ficha

@onready var _arvore: ArvoreHabilidades = %Arvore
@onready var _subtitulo: Label = %Subtitulo
@onready var _nome: Label = %Nome
@onready var _situacao: Label = %Situacao
@onready var _descricao: Label = %Descricao
@onready var _tecla: Label = %Tecla
@onready var _botao_fechar: Button = %Fechar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_arvore.escolhida.connect(_mostrar_habilidade)
	_botao_fechar.pressed.connect(fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


func abrir(ficha: Ficha) -> void:
	_ficha = ficha
	_subtitulo.text = "%s · nível %d" % [ficha.classe.nome, ficha.nivel]
	_arvore.montar(ficha.classe.habilidades, ficha.nivel)
	show()
	if not ficha.classe.habilidades.is_empty():
		_mostrar_habilidade(ficha.classe.habilidades[0])
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


func _mostrar_habilidade(habilidade: HabilidadeClasse) -> void:
	_nome.text = habilidade.nome
	_situacao.text = _texto_situacao(habilidade)
	_descricao.text = habilidade.descricao
	_tecla.text = "Tecla: %s" % Comandos.tecla_de(habilidade.acao) if habilidade.acao != &"" else ""


func _texto_situacao(habilidade: HabilidadeClasse) -> String:
	if habilidade.em_breve:
		return "Em breve"
	if habilidade.liberada(_ficha.nivel):
		return "Nível %d · você já tem" % habilidade.nivel_minimo
	return "Chega no nível %d" % habilidade.nivel_minimo
