extends SceneTree
## Gera data/estilos/*.tres — rode uma vez; depois edite os .tres se precisar.

const PASTA := "res://data/estilos/"


func _initialize() -> void:
	var linhas: Array = [
		["defesa", "Defesa", "PHB 2024", EstiloDeLutaRPG.Efeito.DEFESA, "Enquanto usa armadura Leve, Média ou Pesada, +1 na CA."],
		["duelismo", "Duelismo", "PHB 2024", EstiloDeLutaRPG.Efeito.DUELISMO, "Com uma arma corpo a corpo numa mão e sem outra arma, +2 no dano dessa arma (escudo ok)."],
		["arquearia", "Arquearia", "PHB 2024", EstiloDeLutaRPG.Efeito.ARQUEARIA, "+2 nas jogadas de ataque com armas à distância (disparo)."],
		["arremesso", "Combate com Armas de Arremesso", "PHB 2024", EstiloDeLutaRPG.Efeito.ARREMESSO, "+2 no dano de ataque à distância com arma que tem a propriedade Arremesso."],
		["duas_armas", "Combate com Duas Armas", "PHB 2024", EstiloDeLutaRPG.Efeito.DUAS_ARMAS, "No ataque extra da arma Leve, soma o modificador de atributo ao dano."],
		["armas_grandes", "Combate com Armas Grandes", "PHB 2024", EstiloDeLutaRPG.Efeito.ARMAS_GRANDES, "Com arma Duas Mãos ou Versátil a duas mãos, trata 1 ou 2 nos dados de dano como 3."],
		["desarmado", "Combate Desarmado", "PHB 2024", EstiloDeLutaRPG.Efeito.DESARMADO, "Soco: 1d6+FOR (1d8 sem arma nem escudo). No início do turno, 1d4 em criatura Agarrada por você."],
		["luta_cegas", "Luta às Cegas", "PHB 2024", EstiloDeLutaRPG.Efeito.LUTA_CEGAS, "No jogo: +1 na Percepção passiva (útil contra inimigos escondidos)."],
		["glima", "Glima", "Northlands", EstiloDeLutaRPG.Efeito.GLIMA, "Acerto desarmado pode forçar salvaguarda de Força; falha = Caído."],
		["selvageria", "Selvageria", "Northlands", EstiloDeLutaRPG.Efeito.SELVAGERIA, "No 1º ataque C/C do turno: +proficiência no dano, −2 CA até o próximo turno."],
		["escaramucador", "Escaramuçador", "Northlands", EstiloDeLutaRPG.Efeito.ESCARAMUCADOR, "+3 m de deslocamento. +proficiência no dano se moveu antes do golpe."],
		["pelos_pes", "Pelos Pés", "Northlands", EstiloDeLutaRPG.Efeito.PELOS_PES, "Vantagem no ataque contra inimigo maior quando bem perto."],
		["artilheiro", "Artilheiro de Combate Próximo", "Grim Hollow", EstiloDeLutaRPG.Efeito.ARTILHEIRO, "Sem desvantagem de disparo perto do inimigo; +2 dano à queima-roupa."],
		["disparo_duplo", "Disparo Duplo", "Grim Hollow", EstiloDeLutaRPG.Efeito.DISPARO_DUPLO, "Com arco/besta, pode fazer 2º ataque no mesmo combo (ambos com desvantagem)."],
		["rajada", "Rajada", "Grim Hollow", EstiloDeLutaRPG.Efeito.RAJADA, "Abre mão da vantagem num ataque para atacar outro alvo perto em seguida."],
		["combatente_movel", "Combatente Móvel", "Grim Hollow", EstiloDeLutaRPG.Efeito.COMBATENTE_MOVEL, "Ao atacar, +3 m de deslocamento até o fim do turno."],
		["oportunista", "Oportunista", "Grim Hollow", EstiloDeLutaRPG.Efeito.OPORTUNISTA, "No jogo: +2 ataque e dano no 1º golpe depois de levar dano (janela curta)."],
		["defesa_chao", "Defesa no Chão", "Grim Hollow", EstiloDeLutaRPG.Efeito.DEFESA_CHAO, "Caído: sem desvantagem no ataque; levantar custa só 1,5 m de movimento."],
	]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	for d in linhas:
		var e := EstiloDeLutaRPG.new()
		e.no_jogo = true
		e.id = StringName(str(d[0]))
		e.nome = str(d[1])
		e.fonte = str(d[2])
		e.efeito = d[3] as EstiloDeLutaRPG.Efeito
		e.descricao = str(d[4])
		var caminho: String = PASTA + str(d[0]) + ".tres"
		var err := ResourceSaver.save(e, caminho)
		print("  ", caminho, " → ", err)
	print("PASSOU: estilos gerados")
	quit(0)
