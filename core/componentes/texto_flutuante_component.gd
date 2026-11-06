class_name TextoFlutuanteComponent
extends Node2D
## Mostra textos que sobem e somem (dano, "Errou!", "Crítico!") na posição deste nó.

## Quanto o texto sobe antes de sumir (px).
@export var subida: float = 20.0
## Quanto tempo o texto fica na tela (s).
@export var duracao: float = 0.6

const COR_DANO := Color(1.0, 0.9, 0.4)
const COR_CRITICO := Color(1.0, 0.55, 0.2)
const COR_ERRO := Color(0.8, 0.82, 0.88)
const COR_DANO_SOFRIDO := Color(1.0, 0.45, 0.45)
## Cura (Second Wind).
const COR_CURA := Color(0.45, 0.95, 0.55)
## Condições das maestrias (Caído!, Lento!, Salvou!...).
const COR_CONDICAO := Color(0.78, 0.62, 1.0)
## Textos que aparecem juntos (ex.: dano e "Caído!") sobem empilhados, sem se cobrir (px).
const ALTURA_LINHA := 16.0
const TAMANHO_NORMAL := 16
const TAMANHO_CURA := 22


func mostrar(texto: String, cor: Color) -> void:
	_soltar(texto, cor, TAMANHO_NORMAL, subida, duracao)


## Cura em destaque: número maior, sobe mais e demora mais para sumir.
func mostrar_cura(texto: String) -> void:
	_soltar(texto, COR_CURA, TAMANHO_CURA, subida * 2.0, duracao * 1.6)


func _soltar(texto: String, cor: Color, tamanho: int, sobe: float, tempo: float) -> void:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_constant_override("outline_size", 4)
	var inicio := -ALTURA_LINHA * get_child_count()  # empilha sobre os que ainda estão subindo
	rotulo.position = Vector2(-16, inicio)
	add_child(rotulo)
	var tween := create_tween().set_parallel()
	tween.tween_property(rotulo, "position:y", inicio - sobe, tempo)
	tween.tween_property(rotulo, "modulate:a", 0.0, tempo)
	tween.chain().tween_callback(rotulo.queue_free)


## Mostra o resultado de um ataque: o dano, "Crítico X!", "Errou!" ou "Raspão X" (errou, mas
## a maestria causou dano); se o alvo resistiu
## ao tipo de dano, acrescenta "(resistiu)". `cor_dano` muda a cor do dano (ex.: vermelho
## quando é o herói que apanha).
func mostrar_resultado(resultado: Combate.Resultado, cor_dano: Color = COR_DANO) -> void:
	if not resultado.acertou:
		mostrar("Raspão %d" % resultado.dano if resultado.raspao else "Errou!", COR_ERRO)
		return
	var texto := ("Crítico %d!" % resultado.dano) if resultado.critico else str(resultado.dano)
	if resultado.resistido:
		texto += " (resistiu)"
	mostrar(texto, COR_CRITICO if resultado.critico else cor_dano)
