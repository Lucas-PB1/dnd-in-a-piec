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
## Bônus mágico (+1/+2/+3) somado à CA. 0 = comum.
@export var bonus_magico: int = 0

@export_group("Visual no herói")
## Cor principal pintada na roupa do herói (o shader mantém a luz e sombra da arte).
@export var cor: Color = Color(0.6, 0.6, 0.65)
@export var padrao: Padrao = Padrao.LISO
## Ladrilho repetido na túnica pelo shader (couro, anéis, placas, escamas, acolchoado).
@export var detalhe: Texture2D
## Imagem do escudo (só escudos).
@export var textura: Texture2D

@export_group("Referência")
## Nome no livro (inglês).
@export var nome_original: String = ""
@export var peso: String = ""
@export var livro: String = ""


## Maior bônus mágico comum (igual às armas).
const BONUS_MAGICO_MAXIMO := Arma.BONUS_MAGICO_MAXIMO


func e_escudo() -> bool:
	return categoria == Proficiencias.ESCUDO


## "CA 16", "CA 12 + DES", "CA 14 + DES (máx. 2)", "CA +2" (já com bônus mágico).
func texto_ca() -> String:
	var base := ca_base + bonus_magico
	if e_escudo():
		return "CA +%d" % base
	if not soma_destreza:
		return "CA %d" % base
	if max_destreza >= 0:
		return "CA %d + DES (máx. %d)" % [base, max_destreza]
	return "CA %d + DES" % base


## Cor do brilho mágico (igual às armas); branco se comum.
func cor_do_brilho() -> Color:
	return Arma.CORES_MAGICAS.get(bonus_magico, Color.WHITE)


## Cópia com bônus mágico (nome "Cota de Malha +1", sem Corrosão, cor do brilho).
## Bônus 0 devolve só a cópia.
func com_bonus_magico(bonus: int) -> Armadura:
	var copia := duplicate() as Armadura
	if bonus < 1:
		return copia
	copia.bonus_magico = clampi(bonus, 1, BONUS_MAGICO_MAXIMO)
	copia.nome = "%s +%d" % [nome, copia.bonus_magico]
	copia.corroivel = false
	copia.cor = copia.cor_do_brilho()
	return copia
