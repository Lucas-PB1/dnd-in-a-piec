class_name ArvoreHabilidades
extends VBoxContainer
## A lista de habilidades por nível: uma linha para cada nível ("Nível 1", "Nível 2"...) com as
## habilidades dele em botões. O que ainda não chegou aparece apagado, mas dá para ler a descrição.
## Sem linhas ligando nada: simples de ler e de tocar.

## Emitido ao escolher uma habilidade (clique ou toque).
signal escolhida(habilidade: HabilidadeClasse)

const LARGURA_ROTULO := 56.0
const LARGURA_NO := 110.0
const ALTURA_NO := 18.0
const ESPACO := 1
const TAMANHO_FONTE := 11
const COR_NIVEL_LIBERADO := Color(1.0, 0.86, 0.45, 1.0)
const COR_APAGADO := Color(0.66, 0.58, 0.5, 1.0)

var _nivel: int = 1
var _nos: Dictionary[StringName, Button] = {}


## Monta a lista para uma ficha desse nível. Seleciona a primeira habilidade.
func montar(habilidades: Array[HabilidadeClasse], nivel: int) -> void:
	_nivel = nivel
	for filho in get_children():
		filho.queue_free()
	_nos.clear()
	add_theme_constant_override(&"separation", ESPACO)
	var grupo := ButtonGroup.new()  # um selecionado por vez
	for nivel_da_linha in _niveis_em_ordem(habilidades):
		add_child(_criar_linha(nivel_da_linha, habilidades, grupo))
	if not habilidades.is_empty():
		_nos[habilidades[0].id].button_pressed = true


## O botão de uma habilidade (para os testes e para selecionar por código).
func no_de(id: StringName) -> Button:
	return _nos.get(id)


func _niveis_em_ordem(habilidades: Array[HabilidadeClasse]) -> Array[int]:
	var niveis: Array[int] = []
	for habilidade in habilidades:
		if habilidade.nivel_minimo not in niveis:
			niveis.append(habilidade.nivel_minimo)
	niveis.sort()
	return niveis


func _criar_linha(nivel_da_linha: int, habilidades: Array[HabilidadeClasse], grupo: ButtonGroup) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", ESPACO)
	linha.add_child(_criar_rotulo(nivel_da_linha))
	for habilidade in habilidades:
		if habilidade.nivel_minimo == nivel_da_linha:
			var botao := _criar_no(habilidade, grupo)
			linha.add_child(botao)
			_nos[habilidade.id] = botao
	return linha


func _criar_rotulo(nivel_da_linha: int) -> Label:
	var rotulo := Label.new()
	rotulo.text = "Nível %d" % nivel_da_linha
	rotulo.custom_minimum_size = Vector2(LARGURA_ROTULO, 0.0)
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override(&"font_size", TAMANHO_FONTE)
	rotulo.add_theme_color_override(&"font_color", COR_NIVEL_LIBERADO if nivel_da_linha <= _nivel else COR_APAGADO)
	return rotulo


func _criar_no(habilidade: HabilidadeClasse, grupo: ButtonGroup) -> Button:
	var botao := Button.new()
	botao.text = habilidade.nome
	botao.toggle_mode = true
	botao.button_group = grupo
	botao.custom_minimum_size = Vector2(LARGURA_NO, ALTURA_NO)
	botao.clip_text = true
	botao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS  # nome comprido corta em vez de alargar
	botao.add_theme_font_size_override(&"font_size", TAMANHO_FONTE)
	if not habilidade.liberada(_nivel):
		botao.modulate = COR_APAGADO
	botao.pressed.connect(escolhida.emit.bind(habilidade))
	return botao
