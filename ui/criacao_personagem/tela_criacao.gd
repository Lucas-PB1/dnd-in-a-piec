class_name TelaCriacao
extends Control
## Criação em cinco passos: quem é o herói, o antecedente (aumento de atributo, 2 perícias e o
## talento de origem), os atributos, as perícias (Guerreiro: 2, além das do antecedente) e as
## maestrias (os tipos de arma que domina; Guerreiro: 3). Não deixa avançar com o passo incompleto.
## Funciona com o jogo pausado. Ao confirmar, emite `confirmada`.

## Emitido ao clicar em "Começar", com a ficha montada e o pacote inicial escolhido
## (null se a classe não tiver pacotes).
signal confirmada(ficha: Ficha, pacote: PacoteInicial)
## Esc no primeiro passo: quem montou o jogo volta ao título.
signal voltar_ao_titulo_pedido

const LARGURA_AJUSTE := 28
## Largura dos botões de distribuição pronta (px).
const LARGURA_BUILD := 150
## Espaço entre as partes de um atributo na grade (px).
const SEPARACAO_CELULA := 6
const PONTOS_DO_AUMENTO_MAIOR := 2
## O Perito (talento de origem) dá proficiência em mais isto de perícias, à escolha entre todas.
const PERICIAS_DO_PERITO := 3
const ID_TALENTO_PERITO := &"perito"

## Classes que o jogador pode escolher (por enquanto só o Guerreiro).
@export var classes: Array[ClasseRPG] = []
## Arma da prévia do dano quando o pacote não põe nenhuma na mão (soco).
@export var arma_previa: Arma
## De onde vêm as armas que dá para dominar (Maestria em Armas).
@export var pasta_armas: String = "res://data/armas/"
## De onde vêm os antecedentes (só os acessíveis) e os talentos de origem que eles dão.
@export var pasta_antecedentes: String = "res://data/antecedentes/"
@export var pasta_talentos: String = "res://data/talentos/"

enum Passo { QUEM, ANTECEDENTE, ATRIBUTOS, PERICIAS, MAESTRIAS }

var _passo_atual: Passo = Passo.QUEM
const TITULOS := {
	Passo.QUEM: "Quem é você",
	Passo.ANTECEDENTE: "Antecedente",
	Passo.ATRIBUTOS: "Atributos",
	Passo.PERICIAS: "Perícias",
	Passo.MAESTRIAS: "Maestrias",
}

var _classe: ClasseRPG
var _pacote: PacoteInicial
var _nivel_inicial: int = 1
var _compra := CompraDePontos.new()
var _rotulos_valor: Dictionary[StringName, Label] = {}
var _rotulos_mod: Dictionary[StringName, Label] = {}
var _botoes_menos: Dictionary[StringName, Button] = {}
var _botoes_mais: Dictionary[StringName, Button] = {}
## Armas que a classe pode dominar (proficiente), na ordem da lista.
var _armas: Array[Arma] = []
## Antecedentes que o jogador pode escolher, na ordem da lista, e o escolhido.
var _antecedentes: Array[AntecedenteRPG] = []
var _antecedente: AntecedenteRPG
## Talentos de origem por id (cada antecedente aponta para um).
var _talentos_de_origem: Dictionary[StringName, TalentoRPG] = {}
## Os aumentos de atributo oferecidos para o antecedente escolhido: atributo -> pontos.
var _aumentos: Array[Dictionary] = []
## Perícias que a lista do passo mostra: as da classe e, com o Perito, todas as do jogo.
var _ids_pericias: Array[StringName] = []

@onready var _campo_nome: LineEdit = %Nome
@onready var _escolha_classe: OptionButton = %Classe
@onready var _escolha_nivel: OptionButton = %Nivel
@onready var _escolha_pacote: OptionButton = %Pacote
@onready var _pontos: Label = %Pontos
@onready var _grade: GridContainer = %Grade
## Texto abaixo da grade com o que o atributo tocado faz (nasce na primeira vez).
var _dica_atributo: Label
const LARGURA_DICA := 520.0
const TAMANHO_FONTE_DICA := 12
const COR_DICA := Color(0.85, 0.75, 0.55, 1.0)
@onready var _previa: Label = %Previa
@onready var _proficiencias: Label = %Proficiencias
@onready var _leva: Label = %Leva
@onready var _aviso: Label = %Aviso
@onready var _titulo: Label = %TituloPasso
@onready var _passo_quem: Control = %PassoQuem
@onready var _passo_antecedente: Control = %PassoAntecedente
@onready var _passo_atributos: Control = %PassoAtributos
@onready var _passo_pericias: Control = %PassoPericias
@onready var _passo_maestrias: Control = %PassoMaestrias
@onready var _lista_antecedentes: ItemList = %ListaAntecedentes
@onready var _detalhe_antecedente: Label = %DetalheAntecedente
@onready var _escolha_aumento: OptionButton = %EscolhaAumento
@onready var _lista_pericias: ItemList = %ListaPericias
@onready var _contagem_pericias: Label = %ContagemPericias
@onready var _detalhe_pericia: Label = %DetalhePericia
@onready var _lista_maestrias: ItemList = %ListaMaestrias
@onready var _contagem_maestrias: Label = %ContagemMaestrias
@onready var _detalhe_maestria: Label = %DetalheMaestria
@onready var _caixa_builds: HBoxContainer = %Builds
@onready var _botao_comecar: Button = %Comecar
## Os botões que levam ao passo seguinte; ficam apagados enquanto o passo atual está incompleto.
@onready var _botao_ir_antecedente: Button = %Atributos
@onready var _botao_ir_atributos: Button = %IrAtributos
@onready var _botao_ir_pericias: Button = %IrPericias
@onready var _botao_ir_maestrias: Button = %IrMaestrias


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	if classes.is_empty():
		classes = [ClasseRPG.new()]
	if arma_previa == null:
		arma_previa = Arma.new()
	_preparar_campos()
	for atributo in Atributos.TODOS:
		_criar_linha(atributo)
	_carregar_antecedentes()
	escolher_classe(0)
	_mostrar_passo(Passo.QUEM)
	if not _tem_teclado_virtual():  # no celular o teclado só sobe quando a pessoa toca no nome
		_campo_nome.grab_focus()


func definir_nome(texto: String) -> void:
	_campo_nome.text = texto
	_atualizar()


func escolher_classe(indice: int) -> void:
	_classe = classes[indice]
	_escolha_classe.select(indice)
	_preencher_pericias()
	_preencher_armas()
	_preencher_pacotes()
	_atualizar()


func escolher_nivel(indice: int) -> void:
	_nivel_inicial = clampi(indice + 1, 1, Ficha.NIVEL_MAXIMO)
	_escolha_nivel.select(_nivel_inicial - 1)
	_atualizar()


## Escolhe o antecedente `indice` da lista e refaz o aumento de atributo e as perícias travadas.
func escolher_antecedente(indice: int) -> void:
	if indice < 0 or indice >= _antecedentes.size():
		return
	_antecedente = _antecedentes[indice]
	_lista_antecedentes.select(indice)
	_preencher_aumentos()
	_detalhe_antecedente.text = _texto_do_antecedente(_antecedente)
	if _classe != null:
		_preencher_pericias()
	_atualizar()


## Escolhe o aumento de atributo `indice` entre os que o antecedente oferece.
func escolher_aumento(indice: int) -> void:
	if indice < 0 or indice >= _aumentos.size():
		return
	_escolha_aumento.select(indice)
	_atualizar()


func escolher_pacote(indice: int) -> void:
	_pacote = _classe.pacotes_iniciais[indice] if indice < _classe.pacotes_iniciais.size() else null
	_escolha_pacote.select(indice)
	_marcar_armas_do_pacote()
	_atualizar()


## Aplica uma distribuição pronta da classe (ex.: Guerreiro de armadura pesada).
func aplicar_build(build: BuildSugerido) -> void:
	_compra.aplicar(build.atributos)
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


## Marca ou desmarca uma arma dominada (pelo nome). Não passa da quantidade da classe.
func marcar_arma(nome_arma: String, marcada: bool) -> void:
	for i in _armas.size():
		if _armas[i].nome == nome_arma:
			_ao_marcar(i, marcada)


## Marca ou desmarca uma perícia (pelo id). Não passa da quantidade da classe.
func marcar_pericia(id: StringName, marcada: bool) -> void:
	var indice := _ids_pericias.find(id)
	if indice >= 0:
		_ao_marcar_pericia(indice, marcada)


## Ids das perícias que o jogador escolheu (sem as do antecedente, que já vêm marcadas).
func pericias_marcadas() -> Array[StringName]:
	var ids: Array[StringName] = []
	var travadas := _pericias_travadas()
	for i in _lista_pericias.get_selected_items():
		if _ids_pericias[i] not in travadas:
			ids.append(_ids_pericias[i])
	return ids


## Nomes das armas marcadas.
func armas_marcadas() -> Array[String]:
	var nomes: Array[String] = []
	for i in _lista_maestrias.get_selected_items():
		nomes.append(_armas[i].nome)
	return nomes


## Só confirma com todos os passos completos.
func confirmar() -> void:
	if _falta_algo() != "":
		return
	confirmada.emit(_ficha_atual(), _pacote)


func _preparar_campos() -> void:
	_campo_nome.max_length = Ficha.TAMANHO_MAXIMO_NOME
	_campo_nome.text_changed.connect(func(_t: String) -> void: _atualizar())
	_campo_nome.text_submitted.connect(_ao_enviar_nome)
	for classe in classes:
		_escolha_classe.add_item(classe.nome)
	_escolha_classe.item_selected.connect(escolher_classe)
	for n in range(1, Ficha.NIVEL_MAXIMO + 1):
		_escolha_nivel.add_item("Nível %d · %d XP" % [n, Ficha.XP_POR_NIVEL[n]])
	_escolha_nivel.select(0)
	_escolha_nivel.item_selected.connect(escolher_nivel)
	_escolha_pacote.item_selected.connect(escolher_pacote)
	_lista_antecedentes.item_selected.connect(escolher_antecedente)
	_escolha_aumento.item_selected.connect(escolher_aumento)
	_escolha_classe.disabled = classes.size() == 1  # só uma classe por enquanto
	_botao_comecar.pressed.connect(confirmar)
	_botao_ir_antecedente.pressed.connect(_mostrar_passo.bind(Passo.ANTECEDENTE))
	(%VoltarDoAntecedente as Button).pressed.connect(_mostrar_passo.bind(Passo.QUEM))
	_botao_ir_atributos.pressed.connect(_mostrar_passo.bind(Passo.ATRIBUTOS))
	(%Voltar as Button).pressed.connect(_mostrar_passo.bind(Passo.ANTECEDENTE))
	_botao_ir_pericias.pressed.connect(_mostrar_passo.bind(Passo.PERICIAS))
	(%VoltarDasPericias as Button).pressed.connect(_mostrar_passo.bind(Passo.ATRIBUTOS))
	_botao_ir_maestrias.pressed.connect(_mostrar_passo.bind(Passo.MAESTRIAS))
	(%VoltarAtributos as Button).pressed.connect(_mostrar_passo.bind(Passo.PERICIAS))
	_lista_pericias.multi_selected.connect(_ao_marcar_pericia)
	_lista_maestrias.multi_selected.connect(_ao_marcar)


## Esc (ou o botão voltar do celular) volta um passo; no primeiro, pede para voltar ao título.
func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _fechar_teclado():
		return
	match _passo_atual:
		Passo.QUEM:
			voltar_ao_titulo_pedido.emit()
		Passo.ANTECEDENTE:
			_mostrar_passo(Passo.QUEM)
		Passo.ATRIBUTOS:
			_mostrar_passo(Passo.ANTECEDENTE)
		Passo.PERICIAS:
			_mostrar_passo(Passo.ATRIBUTOS)
		Passo.MAESTRIAS:
			_mostrar_passo(Passo.PERICIAS)


## No celular, o primeiro "voltar" com o nome em edição só fecha o teclado: não sai do passo.
func _fechar_teclado() -> bool:
	if not _tem_teclado_virtual() or not _campo_nome.has_focus():
		return false
	_campo_nome.release_focus()
	DisplayServer.virtual_keyboard_hide()
	return true


func _tem_teclado_virtual() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD)


## Enter no nome: fecha o teclado do celular e, se tudo estiver pronto, começa.
func _ao_enviar_nome(_texto: String) -> void:
	_campo_nome.release_focus()
	if _tem_teclado_virtual():
		DisplayServer.virtual_keyboard_hide()
	confirmar()


## Só avança de passo com o atual completo. Voltar é sempre livre.
func _mostrar_passo(passo: Passo) -> void:
	if passo > _passo_atual and _falta_no_passo(_passo_atual) != "":
		return
	_passo_atual = passo
	_passo_quem.visible = passo == Passo.QUEM
	_passo_antecedente.visible = passo == Passo.ANTECEDENTE
	_passo_atributos.visible = passo == Passo.ATRIBUTOS
	_passo_pericias.visible = passo == Passo.PERICIAS
	_passo_maestrias.visible = passo == Passo.MAESTRIAS
	_titulo.text = TITULOS[passo]


## O que falta para sair deste passo ("" = pode avançar).
func _falta_no_passo(passo: Passo) -> String:
	match passo:
		Passo.QUEM:
			return "" if Ficha.nome_valido(_campo_nome.text) else "Escreva um nome"
		Passo.ANTECEDENTE:
			return "" if _antecedente != null or _antecedentes.is_empty() else "Escolha um antecedente"
		Passo.ATRIBUTOS:
			return "" if _compra.pontos_restantes() == 0 else "Gaste todos os pontos"
		Passo.PERICIAS:
			var pedidas := _quantidade_pericias()
			if pericias_marcadas().size() != pedidas:
				return "Escolha %d perícias" % pedidas
			if _marcadas_da_classe() < _classe.quantidade_pericias:
				return "Escolha %d da lista do Guerreiro" % _classe.quantidade_pericias
			return ""
		Passo.MAESTRIAS:
			var pedidas := _classe.quantidade_maestrias
			return "" if armas_marcadas().size() == pedidas else "Escolha %d armas" % pedidas
	return ""


## Lê os antecedentes acessíveis e os talentos de origem que eles dão.
func _carregar_antecedentes() -> void:
	for recurso in Recursos.da_pasta(pasta_talentos):
		var talento := recurso as TalentoRPG
		_talentos_de_origem[talento.id] = talento
	_lista_antecedentes.clear()
	for recurso in Recursos.da_pasta(pasta_antecedentes):
		var antecedente := recurso as AntecedenteRPG
		if antecedente.no_jogo:
			_antecedentes.append(antecedente)
			_lista_antecedentes.add_item(antecedente.nome)
	escolher_antecedente(0)


## Os aumentos que o livro permite: +2 em um e +1 em outro (6 jeitos) ou +1 nos três.
func _preencher_aumentos() -> void:
	_aumentos.clear()
	_escolha_aumento.clear()
	var tres := _antecedente.atributos
	for maior in tres:
		for menor in tres:
			if maior != menor:
				_aumentos.append({maior: PONTOS_DO_AUMENTO_MAIOR, menor: 1})
				_escolha_aumento.add_item("+2 %s, +1 %s" % [Atributos.SIGLAS[maior], Atributos.SIGLAS[menor]])
	var cada: Dictionary = {}
	var siglas: Array[String] = []
	for atributo in tres:
		cada[atributo] = 1
		siglas.append(Atributos.SIGLAS[atributo])
	_aumentos.append(cada)
	_escolha_aumento.add_item("+1 em cada (%s)" % ", ".join(siglas))
	_escolha_aumento.select(0)


## O aumento de atributo escolhido: atributo -> pontos (vazio sem antecedente).
func _aumento_atual() -> Dictionary:
	var indice := _escolha_aumento.selected
	if _antecedente == null or indice < 0 or indice >= _aumentos.size():
		return {}
	return _aumentos[indice]


func _texto_do_antecedente(a: AntecedenteRPG) -> String:
	var talento := _talentos_de_origem.get(a.talento) as TalentoRPG
	var perícias: Array[String] = []
	for id in a.pericias:
		perícias.append(Pericia.nome_de(id))
	return "%s\n\nPerícias: %s\nFerramenta: %s\nTalento: %s" % [
		a.descricao, ", ".join(perícias), a.ferramenta, talento.nome if talento else "—"]


## Lista as perícias da classe e marca as sugeridas (até a quantidade).
func _preencher_pericias() -> void:
	_lista_pericias.clear()
	_ids_pericias = _pericias_da_lista()
	var travadas := _pericias_travadas()
	for i in _ids_pericias.size():
		var id := _ids_pericias[i]
		var texto := Pericia.texto_da_lista(id)
		_lista_pericias.add_item(texto + " (antecedente)" if id in travadas else texto)
		if id in travadas:
			_lista_pericias.select(i, false)
	for id in _classe.pericias_sugeridas:
		marcar_pericia(id, true)


## As perícias que a lista mostra: as da classe; com o Perito, todas as do jogo (as da classe primeiro).
func _pericias_da_lista() -> Array[StringName]:
	var ids: Array[StringName] = _classe.pericias_escolhiveis.duplicate()
	if _tem_perito():
		for id: StringName in Pericia.ATRIBUTO:
			if id not in ids:
				ids.append(id)
	return ids


func _tem_perito() -> bool:
	return _antecedente != null and _antecedente.talento == ID_TALENTO_PERITO


## Quantas perícias o jogador marca: as da classe mais as do Perito.
func _quantidade_pericias() -> int:
	return _classe.quantidade_pericias + (PERICIAS_DO_PERITO if _tem_perito() else 0)


## Das marcadas, quantas estão na lista do Guerreiro (ele precisa de pelo menos as 2 dele).
func _marcadas_da_classe() -> int:
	var quantas := 0
	for id in pericias_marcadas():
		if id in _classe.pericias_escolhiveis:
			quantas += 1
	return quantas


## Perícias do antecedente que também estão na lista da classe: já vêm marcadas e não se desmarcam.
func _pericias_travadas() -> Array[StringName]:
	var travadas: Array[StringName] = []
	if _antecedente == null:
		return travadas
	for id in _antecedente.pericias:
		if id in _ids_pericias:
			travadas.append(id)
	return travadas


## Marcou (ou desmarcou) a perícia `indice`. Passou do limite = não marca. As do antecedente não mudam.
func _ao_marcar_pericia(indice: int, marcada: bool) -> void:
	var id := _ids_pericias[indice]
	if id in _pericias_travadas():
		_lista_pericias.select(indice, false)
		_detalhe_pericia.text = "%s Vem do antecedente." % Pericia.descricao(id)
		return
	var outras := pericias_marcadas().filter(func(p: StringName) -> bool: return p != id).size()
	if marcada and outras < _quantidade_pericias():
		_lista_pericias.select(indice, false)
	else:
		_lista_pericias.deselect(indice)
	_detalhe_pericia.text = Pericia.descricao(id)
	_atualizar()


## Lista as armas em que a classe é proficiente: "Espada Longa (Enfraquecer)".
func _preencher_armas() -> void:
	_armas.clear()
	for recurso in Recursos.da_pasta(pasta_armas):
		var arma := recurso as Arma
		if arma and arma.maestria != &"" and arma.categoria in _classe.proficiencias_armas:
			_armas.append(arma)
	_lista_maestrias.clear()
	for arma in _armas:
		_lista_maestrias.add_item("%s (%s)" % [arma.nome, Proficiencias.NOMES_MAESTRIAS[arma.maestria]], arma.icone)


## Começa com as armas do pacote marcadas (até a quantidade da classe).
func _marcar_armas_do_pacote() -> void:
	_lista_maestrias.deselect_all()
	if _pacote == null:
		return
	for item in _pacote.itens:
		if item is Arma:
			marcar_arma(item.nome, true)


## Marcou (ou desmarcou) a arma `indice`. Passou do limite = não marca. Mostra a maestria.
func _ao_marcar(indice: int, marcada: bool) -> void:
	var nome_arma := _armas[indice].nome
	var outras := armas_marcadas().filter(func(n: String) -> bool: return n != nome_arma).size()
	if marcada and outras < _classe.quantidade_maestrias:
		_lista_maestrias.select(indice, false)
	else:
		_lista_maestrias.deselect(indice)
	var arma := _armas[indice]
	_detalhe_maestria.text = "%s — %s: %s" % [arma.nome, Proficiencias.NOMES_MAESTRIAS[arma.maestria],
		Proficiencias.DESCRICOES_MAESTRIAS[arma.maestria]]
	_atualizar()


## Lista os pacotes da classe ("Pacote A") e escolhe o primeiro. O que leva fica numa linha.
func _preencher_pacotes() -> void:
	_escolha_pacote.clear()
	for pacote in _classe.pacotes_iniciais:
		_escolha_pacote.add_item(pacote.nome)
	_escolha_pacote.disabled = _classe.pacotes_iniciais.is_empty()
	escolher_pacote(0)


## A ficha como está agora: compra de pontos + aumento do antecedente, perícias dele e as escolhidas,
## e o talento de origem.
func _ficha_atual() -> Ficha:
	var ficha := Ficha.new(_classe, _valores_finais(), _campo_nome.text)
	ficha.definir_nivel_inicial(_nivel_inicial)
	ficha.armas_dominadas = armas_marcadas()
	ficha.pericias = pericias_marcadas()
	if _antecedente != null:
		ficha.antecedente = _antecedente.id
		for id in _antecedente.pericias:
			ficha.pericias.append(id)
		var talento := _talentos_de_origem.get(_antecedente.talento) as TalentoRPG
		if talento != null:
			ficha.talentos.append(talento.id)
	return ficha


## Os atributos da compra de pontos mais o aumento do antecedente (teto 20).
func _valores_finais() -> Dictionary:
	var valores: Dictionary = _compra.valores.duplicate()
	var aumento := _aumento_atual()
	for atributo in aumento:
		valores[atributo] = mini(valores[atributo] + aumento[atributo], Ficha.ATRIBUTO_MAXIMO)
	return valores


## O que impede de começar ("" = nada): o primeiro passo incompleto.
func _falta_algo() -> String:
	for passo in Passo.values():
		var falta := _falta_no_passo(passo)
		if falta != "":
			return falta
	return ""


func _criar_linha(atributo: StringName) -> void:
	var celula := HBoxContainer.new()  # sigla, valor, modificador, - e +: um atributo por célula da grade
	celula.add_theme_constant_override(&"separation", SEPARACAO_CELULA)
	var sigla := _rotulo(Atributos.SIGLAS[atributo])
	sigla.tooltip_text = Atributos.dica(atributo)
	sigla.mouse_filter = Control.MOUSE_FILTER_STOP
	sigla.gui_input.connect(_ao_tocar_sigla.bind(atributo))
	celula.add_child(sigla)
	_rotulos_valor[atributo] = _rotulo("")
	_rotulos_mod[atributo] = _rotulo("")
	_botoes_menos[atributo] = _botao("-", mudar_atributo.bind(atributo, -1))
	_botoes_mais[atributo] = _botao("+", mudar_atributo.bind(atributo, 1))
	_botoes_menos[atributo].pressed.connect(_mostrar_dica.bind(atributo))
	_botoes_mais[atributo].pressed.connect(_mostrar_dica.bind(atributo))
	for no in [_rotulos_valor[atributo], _rotulos_mod[atributo], _botoes_menos[atributo], _botoes_mais[atributo]]:
		celula.add_child(no)
	_grade.add_child(celula)


## Tocar ou clicar na sigla mostra o que o atributo faz (no celular não há dica ao passar o mouse).
func _ao_tocar_sigla(evento: InputEvent, atributo: StringName) -> void:
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed:
		_mostrar_dica(atributo)


## A linha de texto abaixo da grade diz o que o atributo faz; nasce na primeira vez que é preciso.
func _mostrar_dica(atributo: StringName) -> void:
	if _dica_atributo == null:
		_dica_atributo = Label.new()
		_dica_atributo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_dica_atributo.custom_minimum_size = Vector2(LARGURA_DICA, 0)
		_dica_atributo.add_theme_font_size_override(&"font_size", TAMANHO_FONTE_DICA)
		_dica_atributo.add_theme_color_override(&"font_color", COR_DICA)
		var pai := _grade.get_parent()
		pai.add_child(_dica_atributo)
		pai.move_child(_dica_atributo, _grade.get_index() + 1)
	_dica_atributo.text = Atributos.dica(atributo)


## Um botão por distribuição pronta da classe. Só refaz se a classe mudou.
func _montar_builds() -> void:
	var builds := _classe.builds_sugeridos
	if _caixa_builds.get_child_count() == builds.size():
		return
	for botao in _caixa_builds.get_children():
		botao.queue_free()
	for build in builds:
		var botao := _botao(build.nome, aplicar_build.bind(build))
		botao.custom_minimum_size = Vector2(LARGURA_BUILD, 0)
		_caixa_builds.add_child(botao)


func _atualizar() -> void:
	if _classe == null:
		return
	var restantes := _compra.pontos_restantes()
	_pontos.text = "Pontos restantes: %d de %d" % [restantes, CompraDePontos.PONTOS_TOTAIS]
	var aumento := _aumento_atual()
	for atributo in Atributos.TODOS:
		var total: int = _valores_finais()[atributo]
		_rotulos_valor[atributo].text = str(total) if not aumento.has(atributo) else "%d (+%d)" % [total, aumento[atributo]]
		_rotulos_mod[atributo].text = Atributos.texto_modificador(total)
		_botoes_menos[atributo].disabled = not _compra.pode_diminuir(atributo)
		_botoes_mais[atributo].disabled = not _compra.pode_aumentar(atributo)
	var ficha := _ficha_atual()
	_contagem_pericias.text = "Escolha %d perícias (%d/%d)%s. Do antecedente: %s. Percepção passiva: %d." % [
		_quantidade_pericias(), pericias_marcadas().size(), _quantidade_pericias(), _texto_do_perito(),
		_nomes_das_pericias_do_antecedente(), ficha.percepcao_passiva()]
	_previa.text = _texto_previa(ficha)
	_aviso.text = _texto_aviso(ficha)
	_leva.text = "Leva: %s" % _pacote.texto_itens() if _pacote else ""
	_proficiencias.text = "Proficiência: %s · %s" % [Proficiencias.texto_armas(_classe.proficiencias_armas),
		Proficiencias.texto_armaduras(_classe.treinamento_armaduras)]
	_montar_builds()
	_contagem_maestrias.text = "Domine %d tipos de arma (%d/%d marcadas). Só com elas a maestria vale." % [
		_classe.quantidade_maestrias, armas_marcadas().size(), _classe.quantidade_maestrias]
	_atualizar_botoes_de_avanco()
	var falta := _falta_algo()
	_botao_comecar.disabled = falta != ""
	_botao_comecar.text = "Começar" if falta == "" else falta


## Com o Perito, lembra que 3 das escolhas valem em qualquer perícia.
func _texto_do_perito() -> String:
	return " · %d delas do Perito, em qualquer perícia" % PERICIAS_DO_PERITO if _tem_perito() else ""


func _nomes_das_pericias_do_antecedente() -> String:
	if _antecedente == null:
		return "nenhum"
	var nomes: Array[String] = []
	for id in _antecedente.pericias:
		nomes.append(Pericia.nome_de(id))
	return ", ".join(nomes)


## Cada botão "seguinte" fica apagado e diz o que falta enquanto o passo dele estiver incompleto.
func _atualizar_botoes_de_avanco() -> void:
	_ajustar_avanco(_botao_ir_antecedente, Passo.QUEM, "Antecedente")
	_ajustar_avanco(_botao_ir_atributos, Passo.ANTECEDENTE, "Atributos")
	_ajustar_avanco(_botao_ir_pericias, Passo.ATRIBUTOS, "Perícias")
	_ajustar_avanco(_botao_ir_maestrias, Passo.PERICIAS, "Maestrias")


func _ajustar_avanco(botao: Button, passo: Passo, texto: String) -> void:
	var falta := _falta_no_passo(passo)
	botao.disabled = falta != ""
	botao.text = texto if falta == "" else falta


## "Vida 12 · CA 16 · 30 pés · Dano 2d6+2".
func _texto_previa(ficha: Ficha) -> String:
	var armadura := _pacote.armadura() if _pacote else null
	var arma := _pacote.arma() if _pacote and _pacote.arma() else arma_previa
	return "Nível %d · Vida %d · CA %d · %d pés · Dano %s" % [ficha.nivel, ficha.vida_maxima(), ficha.classe_armadura(armadura),
		int(ficha.deslocamento_pes(armadura)), ficha.texto_dano(arma, arma.e_versatil())]


func _texto_aviso(ficha: Ficha) -> String:
	var armadura := _pacote.armadura() if _pacote else null
	var arma := _pacote.arma() if _pacote and _pacote.arma() else arma_previa
	var avisos: PackedStringArray = []
	if ficha.falta_forca_para(armadura):
		avisos.append("A %s pede FOR %d: -%d pés" % [armadura.nome, armadura.forca_minima, Ficha.PERDA_DESLOCAMENTO_SEM_FORCA])
	if ficha.fraco_para(arma):
		avisos.append("%s é Pesada: FOR abaixo de %d, desvantagem" % [arma.nome, Ficha.FORCA_MINIMA_ARMA_PESADA])
	return "\n".join(avisos)


func _rotulo(texto: String) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	return rotulo


func _botao(texto: String, ao_apertar: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(LARGURA_AJUSTE, 0)
	botao.pressed.connect(ao_apertar)
	return botao
