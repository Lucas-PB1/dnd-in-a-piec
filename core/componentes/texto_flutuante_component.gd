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


func mostrar(texto: String, cor: Color) -> void:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	rotulo.add_theme_constant_override("outline_size", 4)
	rotulo.position = Vector2(-12, 0)
	add_child(rotulo)
	var tween := create_tween().set_parallel()
	tween.tween_property(rotulo, "position:y", -subida, duracao)
	tween.tween_property(rotulo, "modulate:a", 0.0, duracao)
	tween.chain().tween_callback(rotulo.queue_free)


## Mostra o resultado de um ataque: o dano, "Crítico X!" ou "Errou!".
## `cor_dano` muda a cor do dano (ex.: vermelho quando é o herói que apanha).
func mostrar_resultado(resultado: Combate.Resultado, cor_dano: Color = COR_DANO) -> void:
	if not resultado.acertou:
		mostrar("Errou!", COR_ERRO)
	elif resultado.critico:
		mostrar("Crítico %d!" % resultado.dano, COR_CRITICO)
	else:
		mostrar(str(resultado.dano), cor_dano)
