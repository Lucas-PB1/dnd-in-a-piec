class_name FundoParalaxe
extends ParallaxBackground
## Fundo em camadas que se mexe mais devagar que a fase (parallax). Cada ambiente usa um tema
## (floresta, fortaleza, pântano ou ruína; arte CC0 do ansimuz em assets/fundos/) pintado num tom próprio.
## A `Fase` cria um para o seu `nome_ambiente`; o fundo só aparece quando o ambiente existe.

## Aumento da arte (a arte de floresta tem 272 px de altura; ×2 cobre os 360 da tela).
const ESCALA := 2.0
## Onde a arte começa na tela (px, negativo = sobe): mostra a parte de baixo, com o chão.
const TOPO := -150.0
## Altura de referência (px da textura) para alinhar o rodapé das camadas de alturas diferentes.
const ALTURA_REFERENCIA_PX := 272.0
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
	&"pantano": [
		["res://assets/fundos/pantano/back.png", 0.12],
		["res://assets/fundos/pantano/middle.png", 0.4],
		["res://assets/fundos/pantano/front.png", 0.65],
	],
	&"ruina": [
		["res://assets/fundos/ruina/back.png", 0.05],
		["res://assets/fundos/ruina/mountains.png", 0.28],
		["res://assets/fundos/ruina/graveyard.png", 0.55],
	],
}

## Ambiente -> [tema, tom]. O tom multiplica a cor da arte (branco = como foi desenhada).
const AMBIENTES := {
	"Clareira": [&"floresta", Color(1.0, 1.0, 1.0)],
	"Trilha": [&"floresta", Color(1.0, 0.82, 0.68)],
	"Pântano": [&"pantano", Color(1.0, 1.0, 1.0)],
	"Ruína": [&"ruina", Color(1.0, 1.0, 1.0)],
	"Fortaleza": [&"fortaleza", Color(1.0, 1.0, 1.0)],
	"Labirinto": [&"fortaleza", Color(0.7, 0.72, 0.85)],
	"Mina": [&"fortaleza", Color(0.62, 0.5, 0.42)],
	"Caverna Úmida": [&"fortaleza", Color(0.42, 0.6, 0.62)],
	"Cripta": [&"fortaleza", Color(0.5, 0.55, 0.7)],
	"Covil": [&"fortaleza", Color(0.9, 0.42, 0.32)],
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
	var base_y := TOPO + ALTURA_REFERENCIA_PX * ESCALA
	for dados: Array in TEMAS[tema]:
		var textura: Texture2D = load(dados[0])
		var camada := ParallaxLayer.new()
		camada.motion_scale = Vector2(dados[1], 0.0)
		camada.modulate = tom
		var imagem := Sprite2D.new()
		imagem.texture = textura
		imagem.centered = false
		imagem.scale = Vector2(ESCALA, ESCALA)
		# Alinha o rodapé das camadas (pacotes com alturas diferentes, ex.: cemitério).
		imagem.position = Vector2(INICIO_X, base_y - textura.get_height() * ESCALA)
		# Repete a imagem na horizontal em vez de espelhar (o espelho falha em camadas estreitas).
		imagem.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		imagem.region_enabled = true
		imagem.region_rect = Rect2(0.0, 0.0, LARGURA_COBERTA / ESCALA, textura.get_height())
		camada.add_child(imagem)
		add_child(camada)
