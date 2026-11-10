class_name FichaVisual
extends VBoxContainer
## A ficha do personagem como cartões e barras: nome e nível, vida e XP em barras, CA, deslocamento e iniciativa em
## etiquetas, os seis atributos em cartões (salvaguarda proficiente com borda dourada), ataque e dano, e as
## perícias e os talentos em etiquetas. Reconstrói tudo a cada `mostrar` (a ficha muda pouco e é pequena).
## Não conhece o herói: recebe a Ficha, o Inventario, a vida e o que vale como arma sem nada na mão.

const PASTA_TALENTOS := "res://data/talentos"
const LARGURA_BARRA := 230.0
const ALTURA_BARRA := 14.0
const COLUNAS_ATRIBUTOS := 3
const TAMANHO_FONTE_PEQUENO := 10
const TAMANHO_FONTE := 12
const TAMANHO_FONTE_VALOR := 15

const TEXTO_DICA_PADRAO := "Toque num atributo para ver o que ele faz."
## O atributo cuja explicação está na tela ("" = a dica padrão).
var _atributo_da_dica: StringName = &""

## id do talento -> nome do livro, lido uma vez da pasta de dados.
var _nomes_dos_talentos: Dictionary[StringName, String] = {}


func _ready() -> void:
	add_theme_constant_override(&"separation", 4)
	for recurso in Recursos.da_pasta(PASTA_TALENTOS):
		var talento := recurso as TalentoRPG
		_nomes_dos_talentos[talento.id] = talento.nome


## Monta a ficha. `mao_vazia` = a Arma do soco, para o ataque de quem está desarmado.
func mostrar(ficha: Ficha, inventario: Inventario, mao_vazia: Arma, vida_atual: int, vida_maxima: int) -> void:
	for filho in get_children():
		filho.queue_free()
		remove_child(filho)
	add_child(_cabecalho(ficha))
	add_child(_barra("BarraPV", "PV %d/%d" % [vida_atual, vida_maxima], vida_atual, vida_maxima, EstiloCartao.COR_PV))
	add_child(_barra_de_xp(ficha))
	add_child(_etiquetas_de_combate(ficha, inventario))
	add_child(_grade_de_atributos(ficha))
	add_child(_dica_do_atributo())
	add_child(_ataque(ficha, inventario, Equipamento.arma(inventario, mao_vazia)))
	_adicionar_lista("Maestrias", ficha.armas_dominadas)
	_adicionar_lista("Perícias", _nomes_das_pericias(ficha))
	_adicionar_lista("Talentos", _nomes_dos_talentos_da(ficha))


func _cabecalho(ficha: Ficha) -> Label:
	var rotulo := _rotulo("Cabecalho", "%s, %s · Nível %d" % [ficha.nome, ficha.classe.nome, ficha.nivel], TAMANHO_FONTE)
	rotulo.add_theme_color_override(&"font_color", EstiloCartao.DOURADO)
	return rotulo


func _barra_de_xp(ficha: Ficha) -> Control:
	var proximo := ficha.xp_proximo_nivel()
	var texto := "XP %d/%d" % [ficha.experiencia, proximo] if proximo > 0 else "XP %d (máx.)" % ficha.experiencia
	return _barra("BarraXP", texto, ficha.experiencia if proximo > 0 else 1, maxi(proximo, 1), EstiloCartao.COR_XP)


## Barra com o texto no meio (nó `Texto` dentro de `nome`).
func _barra(nome: String, texto: String, valor: int, maximo: int, cor: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.name = nome
	barra.custom_minimum_size = Vector2(LARGURA_BARRA, ALTURA_BARRA)
	barra.max_value = maxi(maximo, 1)
	barra.value = valor
	barra.show_percentage = false
	barra.add_theme_stylebox_override(&"background", EstiloCartao.cartao())
	barra.add_theme_stylebox_override(&"fill", EstiloCartao.preenchimento(cor))
	var rotulo := _rotulo("Texto", texto, TAMANHO_FONTE_PEQUENO)
	rotulo.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	barra.add_child(rotulo)
	return barra


func _etiquetas_de_combate(ficha: Ficha, inventario: Inventario) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 4)
	linha.add_child(_etiqueta("CA", "CA %d" % Equipamento.classe_armadura(ficha, inventario)))
	linha.add_child(_etiqueta("Deslocamento", "%d pés" % int(Equipamento.deslocamento_pes(ficha, inventario))))
	linha.add_child(_etiqueta("Iniciativa", "Inic. %s" % Atributos.texto_bonus(ficha.iniciativa())))
	linha.add_child(_etiqueta("Ouro", "%d po" % ficha.ouro))
	return linha


func _grade_de_atributos(ficha: Ficha) -> GridContainer:
	var grade := GridContainer.new()
	grade.columns = COLUNAS_ATRIBUTOS
	grade.add_theme_constant_override(&"h_separation", 4)
	grade.add_theme_constant_override(&"v_separation", 4)
	for atributo in Atributos.TODOS:
		grade.add_child(_cartao_de_atributo(ficha, atributo))
	return grade


## Cartão do atributo: sigla, valor grande e modificador. Salvaguarda proficiente: borda dourada e a marca "salv.".
func _cartao_de_atributo(ficha: Ficha, atributo: StringName) -> PanelContainer:
	var valor: int = ficha.atributos[atributo]
	var salva := ficha.proficiente_em_salvaguarda(atributo)
	var cartao := PanelContainer.new()
	cartao.name = "Atributo_%s" % atributo
	cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cartao.tooltip_text = Atributos.dica(atributo)
	cartao.gui_input.connect(_ao_tocar_atributo.bind(atributo))
	cartao.add_theme_stylebox_override(&"panel", EstiloCartao.cartao(EstiloCartao.DOURADO if salva else EstiloCartao.BORDA))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override(&"separation", 0)
	cartao.add_child(coluna)
	var sigla := _rotulo("Sigla", Atributos.SIGLAS[atributo] + (" · salv." if salva else ""), TAMANHO_FONTE_PEQUENO)
	sigla.add_theme_color_override(&"font_color", EstiloCartao.DOURADO if salva else EstiloCartao.TEXTO_FRACO)
	coluna.add_child(sigla)
	coluna.add_child(_rotulo("Valor", "%d  %s" % [valor, Atributos.texto_modificador(valor)], TAMANHO_FONTE_VALOR))
	return cartao


## Tocar num cartão de atributo diz o que ele faz (no celular não há dica ao passar o mouse).
func _ao_tocar_atributo(evento: InputEvent, atributo: StringName) -> void:
	if not (evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed):
		return
	_atributo_da_dica = atributo
	var dica := get_node_or_null("Dica") as Label
	if dica:
		dica.text = Atributos.dica(atributo)


func _dica_do_atributo() -> Label:
	var texto := Atributos.dica(_atributo_da_dica) if _atributo_da_dica != &"" else TEXTO_DICA_PADRAO
	var rotulo := _rotulo("Dica", texto, TAMANHO_FONTE_PEQUENO)
	rotulo.add_theme_color_override(&"font_color", EstiloCartao.TEXTO_FRACO)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.custom_minimum_size = Vector2(LARGURA_BARRA, 0)
	return rotulo


func _ataque(ficha: Ficha, inventario: Inventario, arma: Arma) -> Label:
	var texto := "Ataque %s   Dano %s" % [_texto_do_ataque(ficha, inventario, arma), Equipamento.texto_dano(ficha, inventario, arma)]
	var rotulo := _rotulo("Ataque", texto, TAMANHO_FONTE)
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.custom_minimum_size = Vector2(LARGURA_BARRA, 0)
	return rotulo


## "+4 (FOR +2, prof. +2)"; sem proficiência "sem prof."; arma corroída soma a conta do desgaste.
func _texto_do_ataque(ficha: Ficha, inventario: Inventario, arma: Arma) -> String:
	var atributo := ficha.atributo_do_ataque(arma)
	var partes: PackedStringArray = ["%s %s" % [Atributos.SIGLAS[atributo], Atributos.texto_modificador(ficha.atributos[atributo])]]
	partes.append("prof. +%d" % ficha.bonus_proficiencia() if ficha.proficiente_com(arma) else "sem prof.")
	var desgaste := inventario.penalidade(arma)
	if desgaste > 0:
		partes.append("corroída -%d" % desgaste)
	return "%s (%s)" % [Atributos.texto_bonus(Equipamento.bonus_ataque(ficha, inventario, arma)), ", ".join(partes)]


## Um título e as etiquetas que quebram de linha. Lista vazia não aparece.
func _adicionar_lista(titulo: String, nomes: Array) -> void:
	if nomes.is_empty():
		return
	var cabecalho := _rotulo("Titulo_%s" % titulo, titulo, TAMANHO_FONTE_PEQUENO)
	cabecalho.add_theme_color_override(&"font_color", EstiloCartao.TEXTO_FRACO)
	add_child(cabecalho)
	var fluxo := HFlowContainer.new()
	fluxo.name = "Lista_%s" % titulo
	fluxo.custom_minimum_size = Vector2(LARGURA_BARRA, 0)
	fluxo.add_theme_constant_override(&"h_separation", 3)
	fluxo.add_theme_constant_override(&"v_separation", 3)
	for nome in nomes:
		fluxo.add_child(_etiqueta("", str(nome)))
	add_child(fluxo)


func _nomes_das_pericias(ficha: Ficha) -> Array:
	var nomes: Array = []
	for pericia in ficha.pericias:
		var texto := Pericia.nome_de(pericia)
		nomes.append(texto + " ★" if pericia in ficha.pericias_especializadas else texto)
	return nomes


func _nomes_dos_talentos_da(ficha: Ficha) -> Array:
	var nomes: Array = []
	for id in ficha.talentos:
		nomes.append(_nomes_dos_talentos.get(id, String(id)))
	return nomes


## Etiqueta pequena (cartãozinho com um texto).
func _etiqueta(nome: String, texto: String) -> PanelContainer:
	var cartao := PanelContainer.new()
	if nome != "":
		cartao.name = "Chip_%s" % nome
	cartao.add_theme_stylebox_override(&"panel", EstiloCartao.cartao())
	cartao.add_child(_rotulo("Texto", texto, TAMANHO_FONTE_PEQUENO))
	return cartao


func _rotulo(nome: String, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.name = nome
	rotulo.text = texto
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	return rotulo
