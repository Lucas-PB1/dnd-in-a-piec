class_name Equipamento
extends RefCounted
## Regras que juntam a ficha com o que está equipado no inventário (arma, armadura, escudo).
## Usado pelo herói (combate e movimento) e pela tela de inventário (ficha), para os dois
## calcularem igual. Regra pura.


## Arma na mão, ou o ataque `desarmado` se a mão estiver vazia.
static func arma(inventario: Inventario, desarmado: Arma) -> Arma:
	var na_mao := inventario.equipado(Item.ESPACO_MAO) as Arma
	return na_mao if na_mao else desarmado


static func armadura(inventario: Inventario) -> Armadura:
	return inventario.equipado(Item.ESPACO_CORPO) as Armadura


static func escudo(inventario: Inventario) -> Armadura:
	return inventario.equipado(Item.ESPACO_MAO_SECUNDARIA) as Armadura


## Arma leve na outra mão, ou null (escudo não conta).
static func arma_secundaria(inventario: Inventario) -> Arma:
	return inventario.equipado(Item.ESPACO_MAO_SECUNDARIA) as Arma


## CA com a armadura e o escudo vestidos, já com o desgaste da armadura.
## `penalidade_ca_extra` = ex.: Selvageria (−2 até o próximo turno).
static func classe_armadura(ficha: Ficha, inventario: Inventario, penalidade_ca_extra: int = 0) -> int:
	var vestida := armadura(inventario)
	var ca := ficha.classe_armadura(vestida, escudo(inventario), inventario.penalidade(vestida))
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.DEFESA) and vestida != null and not vestida.e_escudo():
		ca += Ficha.BONUS_DEFESA_CA
	return ca - penalidade_ca_extra


## Deslocamento (pés), com a perda por falta de Força para a armadura.
static func deslocamento_pes(ficha: Ficha, inventario: Inventario) -> float:
	return ficha.deslocamento_pes(armadura(inventario))


## Bônus de ataque com a arma, já sem o desgaste dela.
static func bonus_ataque(ficha: Ficha, inventario: Inventario, com_arma: Arma) -> int:
	return ficha.bonus_ataque(com_arma) - inventario.penalidade(com_arma) + _bonus_ataque_estilo(ficha, com_arma)


## O golpe da arma: desgaste da arma, desvantagem (armadura sem treinamento, arma Pesada
## sem Força) e o dado Versátil se a mão secundária estiver livre.
static func golpe(ficha: Ficha, inventario: Inventario, com_arma: Arma, ataque_extra: bool = false) -> Golpe:
	var livre := inventario.livre(Item.ESPACO_MAO_SECUNDARIA)
	var montado := ficha.golpe_com(com_arma, inventario.penalidade(com_arma), armadura(inventario),
		duas_maos(inventario, com_arma), ataque_extra, livre)
	montado.bonus_ataque += _bonus_ataque_estilo(ficha, com_arma)
	montado.dano = montado.dano.com_bonus(_bonus_dano_estilo(ficha, inventario, com_arma, ataque_extra))
	# Mestre em Escudos: com escudo na outra mão, o acerto corpo a corpo também golpeia com ele.
	if ficha.tem_talento(Ficha.TALENTO_MESTRE_ESCUDOS) and escudo(inventario) != null and not com_arma.disparavel() and not ataque_extra:
		montado.efeitos.append(EfeitosDeTalento.GolpeDeEscudo.new(ficha.cd_golpe_de_escudo()))
	return montado


## Texto do dano como no golpe (ex.: Espada Longa sem escudo = "1d10+3").
static func texto_dano(ficha: Ficha, inventario: Inventario, com_arma: Arma) -> String:
	var livre := inventario.livre(Item.ESPACO_MAO_SECUNDARIA)
	var base := ficha.texto_dano(com_arma, duas_maos(inventario, com_arma), false, livre)
	var extra := _bonus_dano_estilo(ficha, inventario, com_arma, false)
	if extra == 0:
		return base
	# Só para a ficha visual: o golpe já embute o bônus no Dado.
	var dado := ficha.dado_dano(com_arma, duas_maos(inventario, com_arma), false, livre).com_bonus(extra)
	if dado.faces == 1:
		return str(maxi(dado.minimo(), Ficha.DANO_MINIMO))
	return dado.texto()


## Dano do golpe extra (2ª arma leve): sem modificador positivo (exceto Estilo Duas Armas).
static func texto_dano_extra(ficha: Ficha, com_arma: Arma) -> String:
	return ficha.texto_dano(com_arma, false, true)


## Arma Versátil empunhada com as duas mãos: a mão secundária está vazia.
static func duas_maos(inventario: Inventario, com_arma: Arma) -> bool:
	return com_arma.e_versatil() and inventario.livre(Item.ESPACO_MAO_SECUNDARIA)


static func _bonus_ataque_estilo(ficha: Ficha, com_arma: Arma) -> int:
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.ARQUEARIA) and com_arma.disparavel():
		return Ficha.BONUS_ARQUEARIA
	return 0


## Bônus de dano dos estilos estáveis (Duelismo). Escaramuçador/Selvageria/Oportunista/Artilheiro/
## Arremesso dependem de estado ou do modo do golpe e entram pelo herói.
static func _bonus_dano_estilo(ficha: Ficha, inventario: Inventario, com_arma: Arma, _ataque_extra: bool) -> int:
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.DUELISMO) and _vale_duelismo(inventario, com_arma):
		return Ficha.BONUS_DUELISMO
	return 0


## Uma arma corpo a corpo numa mão e nada de outra arma (escudo ok).
static func _vale_duelismo(inventario: Inventario, com_arma: Arma) -> bool:
	if com_arma.disparavel() or com_arma.duas_maos or com_arma.categoria == &"":
		return false
	return arma_secundaria(inventario) == null
