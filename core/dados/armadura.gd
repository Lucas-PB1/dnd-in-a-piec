class_name Armadura
extends Item
## Armadura ou escudo do D&D 5e (item equipável). Uma armadura nova = um .tres em
## data/armaduras/ (gerados por tools/gerar_armaduras.gd a partir da tabela dos livros).

## Padrões visuais da roupa do herói: o gerador desenha o ladrilho `detalhe` a partir dele.
enum Padrao { LISO, MALHA, TACHAS, PLACAS, ACOLCHOADO, ESCAMAS }

## Categoria (Proficiencias): leve, media, pesada ou escudo.
@export var categoria: StringName = Proficiencias.ARMADURA_LEVE
## Armadura: CA base. Escudo: bônus somado à CA.
@export var ca_base: int = 11
## Soma o modificador de Destreza (armaduras leves e médias).
@export var soma_destreza: bool = true
## Máximo de Destreza somado (médias: 2). -1 = sem limite.
@export var max_destreza: int = -1
## Força mínima para usar sem perder deslocamento (0 = não tem). Abaixo dela: -10 pés.
@export var forca_minima: int = 0
@export var desvantagem_furtividade: bool = false
## Armadura não mágica: sofre a corrosão do Pseudópode do Gray Ooze.
@export var corroivel: bool = true

@export_group("Visual no herói")
## Cor principal pintada na roupa do herói (o shader mantém a luz e sombra da arte).
@export var cor: Color = Color(0.6, 0.6, 0.65)
@export var padrao: Padrao = Padrao.LISO
## Ladrilho de textura (anéis, placas com rebites, costuras...) repetido na roupa pelo shader,
## já nas cores da armadura (gerado por tools/gerar_armaduras.gd).
@export var detalhe: Texture2D
## Peças desenhadas por cima do corpo (null = não tem): ombreira no ombro da frente, saiote
## na cintura (médias e pesadas) e elmo (só pesadas). Geradas com o mesmo ladrilho.
@export var ombreira: Texture2D
@export var saiote: Texture2D
@export var elmo: Texture2D
## Imagem do escudo (só escudos).
@export var textura: Texture2D

@export_group("Referência")
## Nome no livro (inglês).
@export var nome_original: String = ""
@export var peso: String = ""
@export var preco: String = ""
@export var livro: String = ""


func e_escudo() -> bool:
	return categoria == Proficiencias.ESCUDO


## "CA 16", "CA 12 + DES", "CA 14 + DES (máx. 2)", "CA +2".
func texto_ca() -> String:
	if e_escudo():
		return "CA +%d" % ca_base
	if not soma_destreza:
		return "CA %d" % ca_base
	if max_destreza >= 0:
		return "CA %d + DES (máx. %d)" % [ca_base, max_destreza]
	return "CA %d + DES" % ca_base
