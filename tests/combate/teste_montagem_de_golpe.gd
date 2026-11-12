extends TesteBase
## Montagem do golpe do herói: estilos, Rajada, Investida e a marca de autor, sem a cena.


func _initialize() -> void:
	_testar_selvageria()
	_testar_artilheiro_e_pelos_pes()
	_testar_rajada_e_investida()
	_testar_assinatura_e_recarga()
	_terminar("montagem de golpe")


func _testar_selvageria() -> void:
	var ficha := _ficha()
	ficha.definir_estilos([&"selvageria"])
	var espada: Arma = load("res://data/armas/espada_curta.tres")
	var golpe := _golpe(ficha, espada)
	var antes := golpe.dano.bonus
	var estilos := EstilosDoHeroi.new()
	_checar(MontagemDeGolpe.aplicar_estilos(golpe, espada, false, ficha, estilos, false, false), "Selvageria liga na hora")
	_checar(golpe.dano.bonus == antes + ficha.bonus_proficiencia() and estilos.selvageria_ativa, "Selvageria soma a proficiência")
	var de_novo := _golpe(ficha, espada)
	var bonus_parado := de_novo.dano.bonus
	_checar(not MontagemDeGolpe.aplicar_estilos(de_novo, espada, false, ficha, estilos, false, false), "a segunda não liga de novo")
	_checar(de_novo.dano.bonus == bonus_parado, "Selvageria já ativa não soma outra vez")


func _testar_artilheiro_e_pelos_pes() -> void:
	var ficha := _ficha()
	ficha.definir_estilos([&"artilheiro"])
	var arco: Arma = load("res://data/armas/arco_curto.tres")
	var estilos := EstilosDoHeroi.new()
	var longe := _golpe(ficha, arco)
	var bonus_longe := longe.dano.bonus
	MontagemDeGolpe.aplicar_estilos(longe, arco, false, ficha, estilos, false, false)
	_checar(longe.dano.bonus == bonus_longe, "Artilheiro longe não soma")
	var perto := _golpe(ficha, arco)
	MontagemDeGolpe.aplicar_estilos(perto, arco, false, ficha, estilos, true, false)
	_checar(perto.dano.bonus == bonus_longe + Ficha.BONUS_ARTILHEIRO_PERTO, "Artilheiro perto soma +2")
	ficha.definir_estilos([&"pelos_pes"])
	var espada: Arma = load("res://data/armas/espada_curta.tres")
	var golpe := _golpe(ficha, espada)
	MontagemDeGolpe.aplicar_estilos(golpe, espada, false, ficha, EstilosDoHeroi.new(), false, true)
	_checar(golpe.vantagem, "Pelos Pés dá vantagem contra inimigo maior")


func _testar_rajada_e_investida() -> void:
	var ficha := _ficha()
	ficha.definir_estilos([&"rajada"])
	var espada: Arma = load("res://data/armas/espada_curta.tres")
	var arco: Arma = load("res://data/armas/arco_curto.tres")
	_checar(MontagemDeGolpe.cabe_rajada(espada, false, ficha, true), "Rajada ligada cabe no corpo a corpo")
	_checar(not MontagemDeGolpe.cabe_rajada(espada, true, ficha, true), "o golpe extra não leva Rajada")
	_checar(not MontagemDeGolpe.cabe_rajada(arco, false, ficha, true), "disparo não leva Rajada")
	ficha.talentos.append(Ficha.TALENTO_INVESTIDA)
	_checar(MontagemDeGolpe.cabe_investida(espada, ficha, true, false), "Investida pronta entra no corpo a corpo")
	_checar(not MontagemDeGolpe.cabe_investida(arco, ficha, true, false), "disparo não leva Investida")
	_checar(not MontagemDeGolpe.cabe_investida(espada, ficha, true, true), "em recarga a Investida espera")


func _testar_assinatura_e_recarga() -> void:
	var ficha := _ficha()
	var espada: Arma = load("res://data/armas/espada_curta.tres")
	var golpe := _golpe(ficha, espada)
	golpe.trespassar = Golpe.new("eco", 0, Dado.de_texto("1d4"))
	MontagemDeGolpe.assinar(golpe, 42, ficha, true)
	_checar(golpe.autor_id == 42 and golpe.vantagem and golpe.trespassar.autor_id == 42 and golpe.trespassar.vantagem, "Sorte e autor passam ao Trespassar")
	_checar(golpe.limiar_critico == ficha.limiar_critico() and golpe.trespassar.limiar_critico == golpe.limiar_critico, "o crítico é o da ficha")
	var recargas := RecargasPorRodada.new()
	var efeito := EfeitosDeTalento.Derrubada.new()
	efeito.por_rodada = true
	efeito.id = &"teste_recarga"
	golpe.efeitos = [efeito]
	recargas.gastar(efeito.id)
	_checar(MontagemDeGolpe.sem_os_em_recarga(golpe.efeitos, recargas).is_empty(), "efeito em recarga sai do golpe")


func _ficha() -> Ficha:
	var classe: ClasseRPG = load("res://data/classe_guerreiro.tres")
	return Ficha.new(classe, classe.atributos_sugeridos, "Teste")


func _golpe(ficha: Ficha, arma: Arma) -> Golpe:
	var mochila := Inventario.new()
	mochila.adicionar(arma)
	return Equipamento.golpe(ficha, mochila, arma, false)
