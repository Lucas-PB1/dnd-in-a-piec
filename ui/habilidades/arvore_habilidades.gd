class_name ArvoreHabilidades
extends Control
## A árvore em si: uma coluna por nível, um botão por habilidade e linhas ligando cada uma ao que
## ela exige. Habilidade ainda não liberada aparece apagada (mas dá para ler a descrição).

## Emitido ao escolher uma habilidade (clique ou toque).
signal escolhida(habilidade: HabilidadeClasse)

const LARGURA_NO := 120.0
const ALTURA_NO := 32.0
const ESPACO_COLUNAS := 16.0
const ESPACO_LINHAS := 10.0
## Altura do título de cada coluna ("Nível 1").
const ALTURA_TITULO := 18.0
const COR_LINHA_LIBERADA := Color(1.0, 0.84, 0.4, 1.0)
const COR_LINHA_APAGADA := Color(0.35, 0.25, 0.15, 1.0)
const COR_NO_APAGADO := Color(0.62, 0.55, 0.5, 1.0)
const LARGURA_LINHA := 2.0

var _habilidades: Array[HabilidadeClasse] = []
var _nivel: int = 1
var _nos: Dictionary[StringName, Button] = {}


## Monta a árvore para uma ficha desse nível. Seleciona a primeira habilidade.
func montar(habilidades: Array[HabilidadeClasse], nivel: int) -> void:
	_habilidades = habilidades
	_nivel = nivel
	for filho in get_children():
		filho.queue_free()
	_nos.clear()
	var niveis := _niveis_em_ordem()
	var grupo := ButtonGroup.new()  # um selecionado por vez
	for coluna in niveis.size():
		_criar_coluna(coluna, niveis[coluna], grupo)
	custom_minimum_size = _tamanho_total(niveis)
	queue_redraw()
	if not habilidades.is_empty():
		_nos[habilidades[0].id].button_pressed = true


## O botão de uma habilidade (para os testes e para selecionar por código).
func no_de(id: StringName) -> Button:
	return _nos.get(id)


func _draw() -> void:
	for habilidade in _habilidades:
		if not _nos.has(habilidade.id):
			continue
		var cor := COR_LINHA_LIBERADA if habilidade.liberada(_nivel) else COR_LINHA_APAGADA
		for pai in habilidade.requer:
			if _nos.has(pai):
				draw_line(_ponta_direita(_nos[pai]), _ponta_esquerda(_nos[habilidade.id]), cor, LARGURA_LINHA)


func _niveis_em_ordem() -> Array[int]:
	var niveis: Array[int] = []
	for habilidade in _habilidades:
		if habilidade.nivel_minimo not in niveis:
			niveis.append(habilidade.nivel_minimo)
	niveis.sort()
	return niveis


func _criar_coluna(coluna: int, nivel: int, grupo: ButtonGroup) -> void:
	var x := coluna * (LARGURA_NO + ESPACO_COLUNAS)
	var titulo := Label.new()
	titulo.text = "Nível %d" % nivel
	titulo.theme_type_variation = &"Dica"
	titulo.position = Vector2(x, 0.0)
	titulo.custom_minimum_size = Vector2(LARGURA_NO, 0.0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(titulo)
	var linha := 0
	for habilidade in _habilidades:
		if habilidade.nivel_minimo != nivel:
			continue
		var botao := _criar_no(habilidade, grupo)
		botao.position = Vector2(x, ALTURA_TITULO + linha * (ALTURA_NO + ESPACO_LINHAS))
		add_child(botao)
		_nos[habilidade.id] = botao
		botao.size = Vector2(LARGURA_NO, ALTURA_NO)
		linha += 1


func _criar_no(habilidade: HabilidadeClasse, grupo: ButtonGroup) -> Button:
	var botao := Button.new()
	botao.text = habilidade.nome
	botao.toggle_mode = true
	botao.button_group = grupo
	botao.custom_minimum_size = Vector2(LARGURA_NO, ALTURA_NO)
	botao.clip_text = true
	botao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS  # nome comprido corta em vez de alargar o botão
	botao.add_theme_font_size_override(&"font_size", 12)
	if not habilidade.liberada(_nivel):
		botao.modulate = COR_NO_APAGADO
	botao.pressed.connect(escolhida.emit.bind(habilidade))
	return botao


func _tamanho_total(niveis: Array[int]) -> Vector2:
	var maior_coluna := 0
	for nivel in niveis:
		var quantas := 0
		for habilidade in _habilidades:
			if habilidade.nivel_minimo == nivel:
				quantas += 1
		maior_coluna = maxi(maior_coluna, quantas)
	return Vector2(
		niveis.size() * LARGURA_NO + maxi(niveis.size() - 1, 0) * ESPACO_COLUNAS,
		ALTURA_TITULO + maior_coluna * ALTURA_NO + maxi(maior_coluna - 1, 0) * ESPACO_LINHAS)


func _ponta_direita(no: Control) -> Vector2:
	return no.position + Vector2(no.size.x, no.size.y / 2.0)


func _ponta_esquerda(no: Control) -> Vector2:
	return no.position + Vector2(0.0, no.size.y / 2.0)
