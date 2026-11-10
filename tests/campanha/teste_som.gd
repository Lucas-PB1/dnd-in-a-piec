extends TesteBase
## Som: volumes (e o arquivo de opções), barramentos, efeitos tocando nos eventos certos, música
## por tela e por fase, e a aba Som das Opções.
## godot --headless --debug --path . --script res://tests/campanha/teste_som.gd


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	OpcoesSom.caminho = "user://som_teste.cfg"  # nunca a configuração de verdade
	DirAccess.remove_absolute(OpcoesSom.caminho)
	await _testar_volumes()
	await _testar_no_jogo()
	DirAccess.remove_absolute(OpcoesSom.caminho)
	print("PASSOU: som, volumes e música" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _testar_volumes() -> void:
	OpcoesSom.preparar_barramentos()
	for nome in OpcoesSom.BARRAMENTOS:
		_checar(AudioServer.get_bus_index(nome) >= 0, "o barramento %s existe" % nome)
	OpcoesSom.definir(OpcoesSom.EFEITOS, 0.5)
	var indice := AudioServer.get_bus_index(OpcoesSom.EFEITOS)
	_checar(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(indice)), 0.5), "o volume vira decibéis no barramento")
	OpcoesSom.definir(OpcoesSom.MUSICA, 0.0)
	_checar(AudioServer.is_bus_mute(AudioServer.get_bus_index(OpcoesSom.MUSICA)), "volume zero silencia o barramento")
	OpcoesSom.salvar()
	OpcoesSom.volume_efeitos = 0.1
	OpcoesSom.carregar()
	_checar(is_equal_approx(OpcoesSom.volume_efeitos, 0.5) and OpcoesSom.volume_musica == 0.0, "os volumes gravados voltam ao carregar")
	OpcoesSom.volume_musica = OpcoesSom.VOLUME_MUSICA_PADRAO
	OpcoesSom.volume_efeitos = OpcoesSom.VOLUME_EFEITOS_PADRAO
	OpcoesSom.aplicar()
	await process_frame


func _testar_no_jogo() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 6:
		await process_frame
	var sons: Sons = main.get_node("Sons")
	var musica: Musica = main.get_node("Musica")
	var jogador: Jogador = main.get_node("Jogador")
	main.tirar_criaturas()
	_checar(musica.faixa_atual == Musica.TITULO and musica.esta_tocando(), "a Clareira toca a música da floresta")
	_checar(musica.ambiente_atual == Musica.AMBIENTE_FLORESTA and musica.ambiente_esta_tocando(), "a Clareira toca o ambiente da floresta")
	var antes := musica.faixa_atual
	musica.tocar(Musica.TITULO)
	_checar(musica.faixa_atual == antes and musica.esta_tocando(), "pedir a mesma faixa não recomeça")
	_checar(musica.ambiente_atual == "" and not musica.ambiente_esta_tocando(), "tela de título cala o ambiente")
	musica.tocar_da_fase(3)
	_checar(musica.faixa_atual == Musica.TAVERNA, "a fase 3 troca para a música da trilha")
	_checar(musica.ambiente_atual == Musica.AMBIENTE_FLORESTA, "a fase 3 mantém o ambiente da floresta")
	musica.tocar_da_fase(5)
	_checar(musica.faixa_atual == Musica.BATALHA, "a fase 5 troca para a música de batalha")
	_checar(musica.ambiente_atual == Musica.AMBIENTE_RUINAS, "a fase 5 toca o ambiente das ruínas")
	musica.tocar_da_fase(8)
	_checar(musica.faixa_atual == Musica.CAVERNA, "a fase 8 toca a música da caverna")
	_checar(musica.ambiente_atual == Musica.AMBIENTE_SUBTERRANEO, "a fase 8 toca o ambiente subterrâneo")
	musica.tocar_da_fase(10)
	_checar(musica.faixa_atual == Musica.CHEFE, "a fase do chefe final toca a música de chefe")
	_checar(musica.ambiente_atual == Musica.AMBIENTE_COVIL, "o Covil toca o ambiente de lava")
	musica.tocar(Musica.DERROTA)
	_checar(musica.faixa_atual == Musica.DERROTA and musica.esta_tocando(), "a derrota toca a música de derrota")
	_checar(musica.ambiente_atual == "", "a derrota cala o ambiente")
	musica.tocar_da_fase(1)

	# Efeitos
	sons.tocados.clear()
	jogador.pulou.emit()
	_checar(sons.tocados.get(&"pulo", 0) == 1, "pular toca o som do pulo")
	jogador.golpe_iniciado.emit(null, false)
	_checar(sons.tocados.get(&"golpe", 0) == 1, "golpear toca o golpe no ar")
	var boneco_defesa: DefesaComponent = main.get_node("BonecoTreino").find_children("*", "DefesaComponent", true, false)[0]
	var resultado := Combate.Resultado.new()
	resultado.golpe = Golpe.new("teste", 0, Dado.new(1, 4))
	resultado.acertou = true
	boneco_defesa.golpe_resolvido.emit(resultado, Vector2.ZERO)
	_checar(sons.tocados.get(&"acerto", 0) == 1, "um acerto toca a pancada")
	resultado.critico = true
	boneco_defesa.golpe_resolvido.emit(resultado, Vector2.ZERO)
	_checar(sons.tocados.get(&"critico", 0) == 1, "um crítico toca o som do crítico")
	var erro := Combate.Resultado.new()
	erro.golpe = resultado.golpe
	boneco_defesa.golpe_resolvido.emit(erro, Vector2.ZERO)
	_checar(sons.tocados.get(&"acerto", 0) == 1 and sons.tocados.get(&"critico", 0) == 1, "um golpe que erra não toca pancada")
	jogador.get_node("Defesa").golpe_resolvido.emit(resultado, Vector2.ZERO)
	_checar(sons.tocados.get(&"apanhar", 0) == 1, "o herói acertado toca o som de apanhar")
	jogador.ganhar_experiencia(Ficha.XP_POR_NIVEL[2])
	_checar(sons.tocados.get(&"nivel", 0) == 1, "subir de nível toca a fanfarra")
	jogador.armar_surto()
	_checar(sons.tocados.get(&"surto_ativar", 0) == 1, "ativar o Surto toca o som mágico")
	jogador.get_node("Vida").receber_dano(1)
	jogador.usar_folego()
	_checar(sons.tocados.get(&"folego", 0) == 1, "usar o Fôlego toca o brilho de cura")
	jogador.comecou_a_morrer.emit()
	_checar(sons.tocados.get(&"morte_heroi", 0) == 1, "morrer toca a queda do herói")
	var espada := Salvamento.item_chamado("Espada Curta").duplicate() as Item
	jogador.inventario.adicionar(espada)
	_checar(sons.tocados.get(&"pegar_item", 0) == 1, "pegar um item toca o som de pegar")
	jogador.inventario.equipar(espada)
	_checar(sons.tocados.get(&"equipar", 0) == 1, "equipar toca o som de equipar")
	jogador.inventario.em_silencio(func() -> void:
		jogador.inventario.adicionar(Salvamento.item_chamado("Adaga").duplicate() as Item)
	)
	_checar(sons.tocados.get(&"pegar_item", 0) == 1, "pacote/save em silêncio não toca pegar")
	# Criaturas e chefes
	var goblin: Goblin = load("res://features/goblin/goblin.tscn").instantiate()
	main.add_child(goblin)
	await process_frame
	sons.tocados.clear()
	goblin.preparar_aviso()
	_checar(sons.tocados.get(&"aviso_goblin", 0) == 1, "o aviso do goblin toca a voz dele")
	var hitbox_goblin: HitboxComponent = goblin.find_children("*", "HitboxComponent", true, false)[0]
	hitbox_goblin.ligar(Golpe.new("Adaga", 4, Dado.de_texto("1d4")))
	_checar(sons.tocados.get(&"ataque_goblin", 0) == 1, "o golpe do goblin toca a voz de ataque")
	goblin.queue_free()
	var chefe := Node2D.new()
	for sinal in [&"despertou", &"morreu"]:
		chefe.add_user_signal(sinal)
	chefe.add_user_signal(&"abalou_o_chao", [{"name": "forca", "type": TYPE_FLOAT}, {"name": "duracao", "type": TYPE_FLOAT}])
	main.add_child(chefe)
	var hitbox := HitboxComponent.new()
	hitbox.collision_mask = 8
	main.add_child(hitbox)
	await process_frame
	chefe.emit_signal(&"despertou")
	chefe.emit_signal(&"abalou_o_chao", 1.0, 0.2)
	chefe.emit_signal(&"morreu")
	hitbox.ligar(Golpe.new("Garra", 5, Dado.de_texto("1d6")))
	_checar(sons.tocados.get(&"rugido", 0) == 1 and sons.tocados.get(&"tremor", 0) == 1, "o chefe ruge ao despertar e treme o chão")
	_checar(sons.tocados.get(&"rugido_morte", 0) == 1, "o chefe ruge ao morrer")
	_checar(sons.tocados.get(&"golpe_monstro", 0) == 1, "o golpe sem voz própria soa o whoosh")
	chefe.queue_free()
	hitbox.queue_free()
	var botao := Button.new()
	main.get_node("Interface").add_child(botao)
	await process_frame
	botao.pressed.emit()
	_checar(sons.tocados.get(&"clique", 0) >= 1, "todo botão de menu faz clique")
	var pausa: TelaPausa = main.get_node("Interface/TelaPausa")
	var abriu: int = sons.tocados.get(&"abrir_tela", 0)
	pausa.abrir()
	_checar(sons.tocados.get(&"abrir_tela", 0) == abriu + 1, "abrir uma tela toca o som de abrir")
	pausa.fechar()

	# Aba Som das Opções
	var opcoes: TelaComandos = main.get_node("Interface/TelaComandos")
	opcoes.abrir()
	var grade: GridContainer = opcoes.get_node("%GradeSom")
	var barra := grade.get_node("Volume_Efeitos") as HSlider
	barra.value = 0.3
	_checar(is_equal_approx(OpcoesSom.volume_efeitos, 0.3), "mexer na barra da aba Som muda o volume")
	opcoes.fechar()
	OpcoesSom.volume_efeitos = OpcoesSom.VOLUME_EFEITOS_PADRAO
	OpcoesSom.aplicar()
	main.free()
	await process_frame
