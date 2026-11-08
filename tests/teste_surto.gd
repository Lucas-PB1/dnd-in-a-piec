extends SceneTree
## Surto de Ação: acende a aura e o próximo ataque vira dois golpes seguidos, cada um com a sua
## rolagem. Também confere o Fôlego (pulso verde), a Mente Tática (liga e desliga) e o botão aceso.
## godot --headless --debug --path . --script res://tests/teste_surto.gd

## Tempo (s) que o ataque leva para terminar com folga, golpe duplo incluído.
const ESPERA_ATAQUE := 1.6

var _falhas: int = 0
var _main: Main
var _jogador: Jogador
var _boneco_defesa: DefesaComponent
var _resolvidos: int = 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	OpcoesToque.caminho = "user://toque_teste.cfg"  # nunca a configuração de verdade
	DirAccess.remove_absolute(OpcoesToque.caminho)
	OpcoesToque.slots = OpcoesToque.padrao_slots()
	_main = load("res://levels/main.tscn").instantiate()
	_main.mostrar_inicio = false
	root.add_child(_main)
	for i in 6:
		await process_frame
	_jogador = _main.get_node("Jogador")
	_main.tirar_criaturas()
	_preparar_cenario()
	_jogador.ganhar_experiencia(Ficha.XP_POR_NIVEL[2])  # nível 2: Surto e Mente Tática liberados
	await _testar_golpe_normal()
	await _testar_surto()
	await _testar_botoes_acesos()
	_testar_folego()
	DirAccess.remove_absolute(OpcoesToque.caminho)
	_main.free()
	print("PASSOU: Surto de Ação, Fôlego e Mente Tática" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


## Herói com a espada curta na mão, de frente para o boneco de treino, que anota cada golpe resolvido.
func _preparar_cenario() -> void:
	_jogador.inventario.limpar()
	var espada := Salvamento.item_chamado("Espada Curta").duplicate() as Item
	_jogador.inventario.adicionar(espada)
	_jogador.inventario.equipar(espada)
	var boneco: Node2D = _main.get_node("BonecoTreino")
	_boneco_defesa = boneco.find_children("*", "DefesaComponent", true, false)[0]
	_boneco_defesa.golpe_resolvido.connect(func(_r: Combate.Resultado, _o: Vector2) -> void: _resolvidos += 1)
	_jogador.global_position = boneco.global_position + Vector2(-34.0, 0.0)
	_jogador.direcao_olhar = 1


func _atacar_e_esperar() -> void:
	_resolvidos = 0
	Input.action_press(&"atacar")
	await _esperar_quadros(3)
	Input.action_release(&"atacar")
	await create_timer(ESPERA_ATAQUE).timeout


func _testar_golpe_normal() -> void:
	await _atacar_e_esperar()
	_checar(_resolvidos == 1, "sem Surto, um ataque rola um golpe só (%d)" % _resolvidos)


func _testar_surto() -> void:
	var aura: AuraComponent = _jogador.get_node("Aura")
	_checar(_jogador.armar_surto() and _jogador.surto_ativo(), "armar o Surto acende a aura mesmo sem inimigo")
	_checar(aura.esta_ligada(), "a aura fica ligada enquanto o Surto espera o ataque")
	_checar(not _jogador.armar_surto(), "não dá para armar o Surto duas vezes")
	await _atacar_e_esperar()
	_checar(_resolvidos == 2, "com o Surto, o ataque rola dois golpes seguidos (%d)" % _resolvidos)
	_checar(not _jogador.surto_ativo() and not aura.esta_ligada(), "depois do segundo golpe a aura apaga")
	await _atacar_e_esperar()
	_checar(_resolvidos == 1, "o ataque seguinte volta a ser um golpe só (%d)" % _resolvidos)


func _testar_botoes_acesos() -> void:
	var toque: ControlesToque = _main.get_node("ControlesToque")
	_checar(toque.botao(&"mente_tatica").estado == BotaoToque.EstadoBotao.DESLIGADO, "Mente Tática desligada: botão avermelhado")
	_main._alternar_mente_tatica()
	_checar(_jogador.mente_tatica_ligada() and toque.botao(&"mente_tatica").estado == BotaoToque.EstadoBotao.ACESO, "ligada: botão aceso")
	_main._alternar_mente_tatica()
	_checar(not _jogador.mente_tatica_ligada() and toque.botao(&"mente_tatica").estado == BotaoToque.EstadoBotao.DESLIGADO, "desligada de novo: avermelhado")
	_main._surto_usado = true
	_main._atualizar_botoes_toque()
	_checar(toque.botao(&"surto_acao").estado == BotaoToque.EstadoBotao.DESLIGADO, "Surto já usado nesta fase: botão avermelhado")
	_main._surto_usado = false
	_main._usar_surto_acao()
	_checar(toque.botao(&"surto_acao").estado == BotaoToque.EstadoBotao.ACESO, "Surto armado: botão aceso")
	_jogador.reviver()  # apaga o Surto sem usar
	_main._surto_usado = false
	_main._atualizar_botoes_toque()
	_checar(toque.botao(&"surto_acao").estado == BotaoToque.EstadoBotao.NORMAL, "Surto pronto: botão normal")
	await process_frame


func _testar_folego() -> void:
	var antes := _jogador.usos_folego()
	_jogador.get_node("Vida").receber_dano(1)
	_checar(_jogador.usar_folego() and _jogador.usos_folego() == antes - 1, "o Fôlego gasta um uso e cura (com o pulso verde)")
	var toque: ControlesToque = _main.get_node("ControlesToque")
	_checar(toque.botao(&"folego").estado == BotaoToque.EstadoBotao.NORMAL, "com usos sobrando, o botão do Fôlego fica normal")


func _esperar_quadros(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		print("  ERRO - ", descricao)
		_falhas += 1
