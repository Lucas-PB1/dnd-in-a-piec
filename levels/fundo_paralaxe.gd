class_name FundoParalaxe
extends ParallaxBackground
## Fundo em camadas que se mexe mais devagar que a fase (parallax). Cada ambiente usa um tema
## (floresta ou fortaleza, arte CC0 do ansimuz em assets/fundos/) pintado num tom próprio.
## A `Fase` cria um para o seu `nome_ambiente`; o fundo só aparece quando o ambiente existe.

## Aumento da arte (a arte tem 272 px de altura; ×2 cobre os 360 da tela).
const ESCALA := 2.0
## Onde a arte começa na tela (px, negativo = sobe): mostra a parte de baixo, com o chão.
const TOPO := -150.0
## Largura coberta por cada camada (px) e onde ela começa (cobre a fase toda e o lado esquerdo da câmera).
const LARGURA_COBERTA := 4600.0
const INICIO_X := -300.0
## Atrás de tudo (a fase e o herói ficam na camada 0).
const CAMADA_ATRAS := -100

## Por tema: camadas [imagem, quanto acompanha a câmera (0 = parada, 1 = junto com a fase)].
const TEMAS := {
	&"floresta": [
		["res://assets/fundos/floresta/back.png", 0.15],
		["res://assets/fundos/floresta/middle.png", 0.45],
	],
	&"fortaleza": [
		["res://assets/fundos/fortaleza/back.png", 0.05],
		["res://assets/fundos/fortaleza/mountains.png", 0.3],
	],
}

## Ambiente -> [tema, tom]. O tom multiplica a cor da arte (branco = como foi desenhada).
const AMBIENTES := {
	"Clareira": [&"floresta", Color(1.0, 1.0, 1.0)],
	"Trilha": [&"floresta", Color(1.0, 0.82, 0.68)],
	"Pântano": [&"floresta", Color(0.55, 0.78, 0.62)],
	"Ruína": [&"fortaleza", Color(0.82, 0.8, 0.9)],
	"Fortaleza": [&"fortaleza", Color(1.0, 1.0, 1.0)],
}


## Cria o fundo do ambiente, ou devolve null se ele não tem fundo (ex.: a fase de teste).
static func para_ambiente(nome_ambiente: String) -> FundoParalaxe:
	if not AMBIENTES.has(nome_ambiente):
		return null
	var fundo := FundoParalaxe.new()
	fundo.name = "Fundo"
	fundo.layer = CAMADA_ATRAS
	var dados: Array = AMBIENTES[nome_ambiente]
	fundo._montar(dados[0], dados[1])
	return fundo


func _montar(tema: StringName, tom: Color) -> void:
	for dados: Array in TEMAS[tema]:
		var textura: Texture2D = load(dados[0])
		var camada := ParallaxLayer.new()
		camada.motion_scale = Vector2(dados[1], 0.0)
		camada.modulate = tom
		var imagem := Sprite2D.new()
		imagem.texture = textura
		imagem.centered = false
		imagem.scale = Vector2(ESCALA, ESCALA)
		imagem.position = Vector2(INICIO_X, TOPO)
		# Repete a imagem na horizontal em vez de espelhar (o espelho falha em camadas estreitas).
		imagem.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		imagem.region_enabled = true
		imagem.region_rect = Rect2(0.0, 0.0, LARGURA_COBERTA / ESCALA, textura.get_height())
		camada.add_child(imagem)
		add_child(camada)
