extends SceneTree
## Teste das armaduras: as 21 do Empório, CA por categoria, limite de DES, Força mínima,
## treinamento (desvantagem / escudo sem CA), escudo, desvantagem no d20 e no herói.
## godot --headless --debug --path . --script res://tests/teste_armaduras.gd

const PASTA := "res://data/armaduras/"
const ROLAGENS := 400

var _falhas := 0
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 77
	_testar_tabela()
	_testar_ca()
	_testar_forca_e_treinamento()
	_testar_desvantagem()
	_rodar_no_jogo.call_deferred()


func _rodar_no_jogo() -> void:
	await _testar_heroi_vestido()
	if _falhas == 0:
		print("PASSOU: todos os testes das armaduras")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _a(arquivo: String) -> Armadura:
	return load(PASTA + arquivo + ".tres")


## Confere os números com o Empório (Player's Handbook, Obojima, Northlands).
func _testar_tabela() -> void:
	var arquivos := DirAccess.get_files_at(PASTA)
	var tres := Array(arquivos).filter(func(n: String) -> bool: return n.ends_with(".tres"))
	_checar(tres.size() == 21, "21 armaduras (deu %d)" % tres.size())
	var cota := _a("cota_malha")
	_checar(cota.categoria == Proficiencias.ARMADURA_PESADA and cota.ca_base == 16 and not cota.soma_destreza
		and cota.forca_minima == 13 and cota.desvantagem_furtividade, "Cota de Malha: pesada, CA 16, FOR 13, desv. Furtividade")
	var couro_batido := _a("couro_batido")
	_checar(couro_batido.categoria == Proficiencias.ARMADURA_LEVE and couro_batido.ca_base == 12 and couro_batido.soma_destreza
		and couro_batido.max_destreza == -1 and not couro_batido.desvantagem_furtividade, "Couro Batido: leve, CA 12 + DES")
	_checar(_a("placas").ca_base == 18 and _a("placas").forca_minima == 15, "Placas: CA 18, FOR 15")
	_checar(_a("couro").detalhe != null and _a("placas").detalhe != null and _a("cota_malha").detalhe != null
		and _a("escudo").detalhe == null and _a("couro").icone.get_width() == 16,
		"a armadura é o ladrilho na túnica; escudo não tem; ícone 16x16")
	_checar(_a("meia_armadura").max_destreza == 2 and _a("meia_armadura").desvantagem_furtividade, "Meia-Armadura: DES máx. 2, desv.")
	_checar(_a("scumweed").max_destreza == 1, "Scumweed (Obojima): DES máx. 1")
	_checar(_a("escudo").e_escudo() and _a("escudo").ca_base == 2 and _a("tampa_panela").ca_base == 1, "Escudo +2, Tampa de Panela +1")
	_checar(cota.espaco == Item.ESPACO_CORPO and _a("escudo").espaco == Item.ESPACO_MAO_SECUNDARIA, "armadura no corpo, escudo na mão secundária")


func _testar_ca() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var des_16 := Ficha.new(guerreiro, {Atributos.DESTREZA: 16, Atributos.FORCA: 15})  # DES +3
	_checar(des_16.classe_armadura() == 13, "sem armadura: 10 + DES (+3) = 13")
	_checar(des_16.classe_armadura(_a("couro_batido")) == 15, "Couro Batido: 12 + DES (+3) = 15")
	_checar(des_16.classe_armadura(_a("camisao_malha")) == 15, "Camisão de Malha: 13 + DES (máx. 2) = 15")
	_checar(des_16.classe_armadura(_a("scumweed")) == 16, "Scumweed: 15 + DES (máx. 1) = 16")
	_checar(des_16.classe_armadura(_a("cota_malha")) == 16, "Cota de Malha: 16 fixo (DES não soma)")
	_checar(des_16.classe_armadura(_a("cota_malha"), _a("escudo")) == 18, "Cota de Malha + Escudo = 18")
	_checar(des_16.classe_armadura(null, _a("escudo")) == 15, "só escudo: 10 + DES + 2 = 15")
	_checar(des_16.classe_armadura(_a("cota_malha"), null, 3) == 13, "Cota de Malha corroída -3 = 13")


func _testar_forca_e_treinamento() -> void:
	var guerreiro: ClasseRPG = load("res://data/classe_guerreiro.tres")
	var fraco := Ficha.new(guerreiro, {Atributos.FORCA: 12})
	var forte := Ficha.new(guerreiro, {Atributos.FORCA: 13})
	_checar(fraco.falta_forca_para(_a("cota_malha")) and fraco.deslocamento_pes(_a("cota_malha")) == 20.0,
		"FOR 12 de Cota de Malha (pede 13): deslocamento 30 -> 20 pés")
	_checar(not forte.falta_forca_para(_a("cota_malha")) and forte.deslocamento_pes(_a("cota_malha")) == 30.0,
		"FOR 13 de Cota de Malha: deslocamento normal")
	_checar(forte.falta_forca_para(_a("placas")), "FOR 13 não basta para Placas (pede 15)")
	_checar(not fraco.desvantagem_por_armadura(_a("placas")), "Guerreiro é treinado: sem desvantagem nem com Placas")
	var mago := guerreiro.duplicate() as ClasseRPG
	mago.treinamento_armaduras = []
	var ficha_mago := Ficha.new(mago, {Atributos.DESTREZA: 14})
	_checar(ficha_mago.desvantagem_por_armadura(_a("couro")), "sem treinamento em leves: Couro dá desvantagem")
	_checar(ficha_mago.golpe_com(load("res://data/ataque_desarmado.tres"), 0, _a("couro")).desvantagem,
		"o ataque de quem veste armadura sem treinamento tem desvantagem")
	_checar(ficha_mago.classe_armadura(null, _a("escudo")) == 12, "escudo sem treinamento não soma CA (10 + 2 = 12)")


func _testar_desvantagem() -> void:
	var soma_normal := 0
	var soma_desv := 0
	var desv_ok := true
	for i in ROLAGENS:
		soma_normal += Combate.rolar_d20(_rng)
		var d := Combate.rolar_d20(_rng, true)
		soma_desv += d
		desv_ok = desv_ok and d >= 1 and d <= 20
	_checar(desv_ok and soma_desv < soma_normal * 0.85,
		"desvantagem: fica com o menor de 2d20 (média %.1f contra %.1f)" % [float(soma_desv) / ROLAGENS, float(soma_normal) / ROLAGENS])


## No jogo: vestir Cota de Malha muda a CA, pinta a roupa; escudo aparece; Pseudópode corrói.
func _testar_heroi_vestido() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	cena.mostrar_inicio = false
	root.add_child(cena)
	var jogador: Jogador = cena.get_node("Jogador")
	cena.get_node("GrayOoze").free()
	await physics_frame
	var material := (jogador.get_node("Sprite") as CanvasItem).material as ShaderMaterial
	_checar(jogador.classe_armadura() == 12 and not material.get_shader_parameter(&"vestida"), "sem armadura: CA 12, túnica normal")
	var cota := _a("cota_malha").duplicate() as Armadura
	jogador.inventario.adicionar(cota)
	jogador.inventario.equipar(cota)
	await physics_frame
	_checar(jogador.classe_armadura() == 16 and (jogador.get_node("Defesa") as DefesaComponent).classe_armadura == 16,
		"vestiu Cota de Malha: CA 16 (e a Defesa usa 16)")
	_checar(material.get_shader_parameter(&"vestida") and material.get_shader_parameter(&"tem_detalhe")
		and material.get_shader_parameter(&"detalhe") == cota.detalhe, "Cota de Malha aparece no herói (shader com o ladrilho de anéis)")
	_checar(jogador.get_node_or_null("Pecas") == null, "não há peças por cima do corpo")
	var escudo := _a("escudo").duplicate() as Armadura
	jogador.inventario.adicionar(escudo)
	jogador.inventario.equipar(escudo)
	await physics_frame
	var sprite_escudo := jogador.get_node("Escudo") as Sprite2D
	var mao_tras := (jogador.get_node("Sprite") as AnimacaoJogador).ponto_da_mao_de_tras()
	_checar(jogador.classe_armadura() == 18 and sprite_escudo.visible and sprite_escudo.position.distance_to(mao_tras) < 1.0,
		"escudo: CA 18, seguro pela mão de trás (centro na mão)")
	var sprite_heroi := jogador.get_node("Sprite") as CanvasItem
	_checar(sprite_escudo.z_index >= sprite_heroi.z_index and sprite_escudo.get_index() > sprite_heroi.get_index(),
		"o escudo é desenhado por cima do corpo e cobre a mão de trás (a mão fica atrás da alça)")
	var pseudopode := (load("res://data/gray_ooze.tres") as CriaturaRPG).golpe()
	pseudopode.bonus_ataque = 100  # só erra com 1 natural
	var hurtbox: HurtboxComponent = jogador.get_node("Hurtbox")
	(jogador.get_node("Vida") as HealthComponent).configurar(999)
	for i in 5:
		if jogador.inventario.penalidade(jogador.armadura_atual()) > 0:
			break
		(jogador.get_node("Defesa") as DefesaComponent).invulneravel = false
		hurtbox.receber_golpe(pseudopode, jogador.global_position + Vector2.RIGHT)
	_checar(jogador.inventario.penalidade(jogador.armadura_atual()) == 1 and jogador.classe_armadura() == 17,
		"Pseudópode corrói a armadura: -1 na CA (16 -> 15, com escudo 17)")
	jogador.inventario.desequipar(Item.ESPACO_CORPO)
	await physics_frame
	_checar(not material.get_shader_parameter(&"vestida"), "desvestiu: túnica volta ao normal")
	cena.queue_free()


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
