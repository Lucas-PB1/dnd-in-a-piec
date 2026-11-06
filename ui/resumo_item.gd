class_name ResumoItem
extends RefCounted
## Texto curto de um item para os menus. Sem ficha: dado cru, peso e preço (arsenal).
## Com ficha: dano já com o modificador e os avisos desta pessoa (inventário).


static func texto(item: Item, ficha: Ficha = null, inventario: Inventario = null) -> String:
	if item is Arma:
		return _arma(item as Arma, ficha, inventario)
	if item is Armadura:
		return _armadura(item as Armadura, ficha, inventario)
	return ""


static func _arma(arma: Arma, ficha: Ficha, inventario: Inventario) -> String:
	var dano := arma.dados_dano
	var sufixo := ""
	if ficha and inventario:
		dano = Equipamento.texto_dano(ficha, inventario, arma)
		if Equipamento.duas_maos(inventario, arma):
			sufixo = " (duas mãos)"
	var partes: PackedStringArray = ["Dano %s %s%s" % [dano, TiposDano.nome(arma.tipo_dano), sufixo]]
	var props := arma.texto_propriedades()
	if props != "":
		partes.append(props)
	if ficha == null:
		_referencia(partes, arma.peso, arma.preco)
		return " · ".join(partes)
	_avisos_arma(partes, arma, ficha, inventario)
	return "\n".join(partes)


static func _armadura(armadura: Armadura, ficha: Ficha, inventario: Inventario) -> String:
	var partes: PackedStringArray = [armadura.texto_ca()]
	if ficha == null:
		_referencia(partes, armadura.peso, armadura.preco)
		return " · ".join(partes)
	_avisos_armadura(partes, armadura, ficha, inventario)
	return "\n".join(partes)


static func _referencia(partes: PackedStringArray, peso: String, preco: String) -> void:
	if peso != "":
		partes.append(peso)
	if preco != "":
		partes.append(preco)


static func _avisos_arma(partes: PackedStringArray, arma: Arma, ficha: Ficha, inventario: Inventario) -> void:
	if arma.maestria != &"":
		var nome_maestria: String = Proficiencias.NOMES_MAESTRIAS[arma.maestria]
		if ficha.domina(arma):
			partes.append("Maestria %s: %s" % [nome_maestria, Proficiencias.DESCRICOES_MAESTRIAS[arma.maestria]])
		else:
			partes.append("Maestria %s: não domina esta arma" % nome_maestria)
	if ficha.fraco_para(arma):
		partes.append("Pesada: FOR abaixo de %d, desvantagem" % Ficha.FORCA_MINIMA_ARMA_PESADA)
	if not ficha.proficiente_com(arma):
		partes.append("Sem proficiência: -%d no ataque" % Ficha.BONUS_PROFICIENCIA)
	if inventario and inventario.penalidade(arma) > 0:
		partes.append("Corroída: -%d no ataque" % inventario.penalidade(arma))


static func _avisos_armadura(partes: PackedStringArray, armadura: Armadura, ficha: Ficha, inventario: Inventario) -> void:
	if not ficha.treinado_com(armadura):
		var efeito := "não soma CA" if armadura.e_escudo() else "desvantagem em FOR e DES"
		partes.append("Sem treinamento: %s" % efeito)
	if ficha.falta_forca_para(armadura):
		partes.append("Precisa FOR %d: -%d pés" % [armadura.forca_minima, Ficha.PERDA_DESLOCAMENTO_SEM_FORCA])
	if armadura.desvantagem_furtividade:
		partes.append("Desvantagem em Furtividade")
	if inventario and inventario.penalidade(armadura) > 0:
		partes.append("Corroída: -%d na CA" % inventario.penalidade(armadura))
