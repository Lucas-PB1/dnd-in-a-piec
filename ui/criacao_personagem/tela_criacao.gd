class_name TelaCriacao
extends Control
## Tela de criação do personagem: compra de pontos (27) dos seis atributos, com prévia
## da vida e do dano. Funciona com o jogo pausado. Ao confirmar, emite `confirmada`.

## Emitido ao clicar em "Começar", com a ficha montada.
signal confirmada(ficha: Ficha)

## Classe do personagem (dado de vida e sugestão de atributos).
@export var classe: ClasseRPG
## Arma usada só para mostrar a prévia do dano.
@export var arma_previa: Arma

var _compra := CompraDePontos.new()
var _rotulos_valor: Dictionary[StringName, Label] = {}
var _rotulos_mod: Dictionary[StringName, Label] = {}
var _botoes_menos: Dictionary[StringName, Button] = {}
var _botoes_mais: Dictionary[StringName, Button] = {}

@onready var _titulo: Label = %Titulo
@onready var _pontos: Label = %Pontos
@onready var _grade: GridContainer = %Grade
@onready var _previa: Label = %Previa
@onready var _botao_sugestao: Button = %Sugestao
@onready var _botao_comecar: Button = %Comecar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	if classe == null:
		classe = ClasseRPG.new()
	if arma_previa == null:
		arma_previa = Arma.new()
	_titulo.text = "Criar %s" % classe.nome
	for atributo in Atributos.TODOS:
		_criar_linha(atributo)
	_botao_sugestao.pressed.connect(aplicar_sugestao)
	_botao_comecar.pressed.connect(confirmar)
	_atualizar()
	_botao_sugestao.grab_focus()


## Usa a distribuição sugerida da classe.
func aplicar_sugestao() -> void:
	_compra.aplicar(classe.atributos_sugeridos)
	_atualizar()


func mudar_atributo(atributo: StringName, quanto: int) -> void:
	if quanto > 0:
		_compra.aumentar(atributo)
	else:
		_compra.diminuir(atributo)
	_atualizar()


## Só confirma quando todos os pontos foram gastos.
func confirmar() -> void:
	if _compra.pontos_restantes() != 0:
		return
	confirmada.emit(_ficha_atual())


func _ficha_atual() -> Ficha:
	return Ficha.new(classe, _compra.valores)


func _criar_linha(atributo: StringName) -> void:
	_grade.add_child(_rotulo("%s (%s)" % [Atributos.NOMES[atributo], Atributos.SIGLAS[atributo]]))
	_botoes_menos[atributo] = _botao("-", mudar_atributo.bind(atributo, -1))
	_rotulos_valor[atributo] = _rotulo("")
	_botoes_mais[atributo] = _botao("+", mudar_atributo.bind(atributo, 1))
	_rotulos_mod[atributo] = _rotulo("")
	for no in [_botoes_menos[atributo], _rotulos_valor[atributo], _botoes_mais[atributo], _rotulos_mod[atributo]]:
		_grade.add_child(no)


func _atualizar() -> void:
	var restantes := _compra.pontos_restantes()
	_pontos.text = "Pontos restantes: %d de %d" % [restantes, CompraDePontos.PONTOS_TOTAIS]
	for atributo in Atributos.TODOS:
		var valor: int = _compra.valores[atributo]
		_rotulos_valor[atributo].text = str(valor)
		_rotulos_mod[atributo].text = "mod %s" % Atributos.texto_modificador(valor)
		_botoes_menos[atributo].disabled = not _compra.pode_diminuir(atributo)
		_botoes_mais[atributo].disabled = not _compra.pode_aumentar(atributo)
	var ficha := _ficha_atual()
	_previa.text = "Vida: %d PV    Dano (%s): %s" % [ficha.vida_maxima(), arma_previa.nome, ficha.texto_dano(arma_previa)]
	_botao_comecar.disabled = restantes != 0
	_botao_comecar.text = "Começar" if restantes == 0 else "Gaste todos os pontos"


func _rotulo(texto: String) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	return rotulo


func _botao(texto: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(24, 0)
	botao.pressed.connect(ao_apertar)
	return botao
