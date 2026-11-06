class_name TelaCriacao
extends Control
## Tela de criação do personagem: nome, classe, pacote de equipamento inicial e compra de pontos (27) dos
## seis atributos, com prévia de vida, CA, deslocamento e dano. Funciona com o jogo pausado.
## Ao confirmar, emite `confirmada`.

## Emitido ao clicar em "Começar", com a ficha montada e o pacote inicial escolhido
## (null se a classe não tiver pacotes).
signal confirmada(ficha: Ficha, pacote: PacoteInicial)

## Classes que o jogador pode escolher (por enquanto só o Guerreiro).
@export var classes: Array[ClasseRPG] = []
## Arma da prévia do dano quando o pacote não põe nenhuma na mão (soco).
@export var arma_previa: Arma

var _classe: ClasseRPG
var _pacote: PacoteInicial
var _compra := CompraDePontos.new()
var _rotulos_valor: Dictionary[StringName, Label] = {}
var _rotulos_mod: Dictionary[StringName, Label] = {}
var _botoes_menos: Dictionary[StringName, Button] = {}
var _botoes_mais: Dictionary[StringName, Button] = {}

@onready var _campo_nome: LineEdit = %Nome
@onready var _escolha_classe: OptionButton = %Classe
@onready var _escolha_pacote: OptionButton = %Pacote
@onready var _pontos: Label = %Pontos
@onready var _grade: GridContainer = %Grade
@onready var _previa: Label = %Previa
@onready var _proficiencias: Label = %Proficiencias
@onready var _botao_sugestao: Button = %Sugestao
@onready var _botao_comecar: Button = %Comecar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	if classes.is_empty():
		classes = [ClasseRPG.new()]
	if arma_previa == null:
		arma_previa = Arma.new()
	_preparar_campos()
	for atributo in Atributos.TODOS:
		_criar_linha(atributo)
	escolher_classe(0)
	_campo_nome.grab_focus()


func definir_nome(texto: String) -> void:
	_campo_nome.text = texto
	_atualizar()


func escolher_classe(indice: int) -> void:
	_classe = classes[indice]
	_escolha_classe.select(indice)
	_preencher_pacotes()
	_atualizar()


func escolher_pacote(indice: int) -> void:
	_pacote = _classe.pacotes_iniciais[indice] if indice < _classe.pacotes_iniciais.size() else null
	_escolha_pacote.select(indice)
	_atualizar()


## Usa a distribuição sugerida da classe escolhida.
func aplicar_sugestao() -> void:
	_compra.aplicar(_classe.atributos_sugeridos)
	_atualizar()


func mudar_atributo(atributo: StringName, quanto: int) -> void:
	if quanto > 0:
		_compra.aumentar(atributo)
	else:
		_compra.diminuir(atributo)
	_atualizar()


## Só confirma com um nome e todos os pontos gastos.
func confirmar() -> void:
	if _falta_algo() != "":
		return
	confirmada.emit(_ficha_atual(), _pacote)


func _preparar_campos() -> void:
	_campo_nome.max_length = Ficha.TAMANHO_MAXIMO_NOME
	_campo_nome.text_changed.connect(func(_t: String) -> void: _atualizar())
	_campo_nome.text_submitted.connect(func(_t: String) -> void: confirmar())
	for classe in classes:
		_escolha_classe.add_item(classe.nome)
	_escolha_classe.item_selected.connect(escolher_classe)
	_escolha_pacote.item_selected.connect(escolher_pacote)
	_escolha_classe.disabled = classes.size() == 1  # só uma classe por enquanto
	_botao_sugestao.pressed.connect(aplicar_sugestao)
	_botao_comecar.pressed.connect(confirmar)


## Lista os pacotes iniciais da classe ("Pacote A: Cota de Malha + Espada Grande") e escolhe o primeiro.
func _preencher_pacotes() -> void:
	_escolha_pacote.clear()
	for pacote in _classe.pacotes_iniciais:
		_escolha_pacote.add_item(_nome_curto(pacote))
	_escolha_pacote.disabled = _classe.pacotes_iniciais.is_empty()
	escolher_pacote(0)


func _nome_curto(pacote: PacoteInicial) -> String:
	var vestidos: PackedStringArray = []
	for item in pacote.equipar:
		vestidos.append(item.nome)
	return "%s: %s" % [pacote.nome, " + ".join(vestidos)]


func _ficha_atual() -> Ficha:
	return Ficha.new(_classe, _compra.valores, _campo_nome.text)


## O que impede de começar ("" = nada).
func _falta_algo() -> String:
	if not Ficha.nome_valido(_campo_nome.text):
		return "Escreva um nome"
	if _compra.pontos_restantes() != 0:
		return "Gaste todos os pontos"
	return ""


func _criar_linha(atributo: StringName) -> void:
	_grade.add_child(_rotulo("%s (%s)" % [Atributos.NOMES[atributo], Atributos.SIGLAS[atributo]]))
	_botoes_menos[atributo] = _botao("-", mudar_atributo.bind(atributo, -1))
	_rotulos_valor[atributo] = _rotulo("")
	_botoes_mais[atributo] = _botao("+", mudar_atributo.bind(atributo, 1))
	_rotulos_mod[atributo] = _rotulo("")
	for no in [_botoes_menos[atributo], _rotulos_valor[atributo], _botoes_mais[atributo], _rotulos_mod[atributo]]:
		_grade.add_child(no)


func _atualizar() -> void:
	if _classe == null:
		return
	var restantes := _compra.pontos_restantes()
	_pontos.text = "Pontos restantes: %d de %d" % [restantes, CompraDePontos.PONTOS_TOTAIS]
	for atributo in Atributos.TODOS:
		var valor: int = _compra.valores[atributo]
		_rotulos_valor[atributo].text = str(valor)
		_rotulos_mod[atributo].text = "mod %s" % Atributos.texto_modificador(valor)
		_botoes_menos[atributo].disabled = not _compra.pode_diminuir(atributo)
		_botoes_mais[atributo].disabled = not _compra.pode_aumentar(atributo)
	_previa.text = _texto_previa(_ficha_atual())
	_proficiencias.text = "Proficiência: %s · %s" % [Proficiencias.texto_armas(_classe.proficiencias_armas),
		Proficiencias.texto_armaduras(_classe.treinamento_armaduras)]
	_botao_sugestao.text = "Sugestão do %s" % _classe.nome
	var falta := _falta_algo()
	_botao_comecar.disabled = falta != ""
	_botao_comecar.text = "Começar" if falta == "" else falta


## "Vida 11 PV · CA 16 · 30 pés · Dano 2d6+2", os itens do pacote e os avisos de Força.
## Os pacotes não têm escudo: arma Versátil aparece com o dado de duas mãos.
func _texto_previa(ficha: Ficha) -> String:
	var armadura := _pacote.armadura() if _pacote else null
	var arma := _pacote.arma() if _pacote and _pacote.arma() else arma_previa
	var texto := "Vida %d PV (d%d + CON) · CA %d · %d pés · Dano %s" % [
		ficha.vida_maxima(), _classe.dado_vida, ficha.classe_armadura(armadura),
		ficha.deslocamento_pes(armadura), ficha.texto_dano(arma, arma.e_versatil())]
	if _pacote:
		texto += "\nLeva: %s" % _pacote.texto_itens()
	if ficha.falta_forca_para(armadura):
		texto += "\nA %s pede FOR %d: -%d pés de deslocamento" % [
			armadura.nome, armadura.forca_minima, Ficha.PERDA_DESLOCAMENTO_SEM_FORCA]
	if ficha.fraco_para(arma):
		texto += "\n%s é Pesada: com FOR abaixo de %d, ataca com desvantagem" % [
			arma.nome, Ficha.FORCA_MINIMA_ARMA_PESADA]
	return texto


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
