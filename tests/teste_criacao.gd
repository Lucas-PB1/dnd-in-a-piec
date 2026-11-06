extends SceneTree
## Teste da tela de criação e do fluxo da main (criar -> entrar no jogo).
## godot --headless --debug --path . --script res://tests/teste_criacao.gd

var _falhas := 0


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	await _testar_tela_sozinha()
	await _testar_fluxo_da_main()
	if _falhas == 0:
		print("PASSOU: todos os testes da criação de personagem")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


## A cena da tela roda sozinha (como no F6).
func _testar_tela_sozinha() -> void:
	var tela: TelaCriacao = load("res://ui/criacao_personagem/tela_criacao.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	var recebida: Array[Ficha] = []
	tela.confirmada.connect(func(f: Ficha) -> void: recebida.append(f))
	tela.confirmar()
	_checar(recebida.is_empty(), "não deixa começar com pontos sobrando")
	tela.aplicar_sugestao()
	tela.mudar_atributo(Atributos.FORCA, -1)
	tela.mudar_atributo(Atributos.FORCA, 1)
	tela.confirmar()
	_checar(recebida.size() == 1 and recebida[0].atributos[Atributos.FORCA] == 15, "confirma com a sugestão e devolve a ficha")
	tela.queue_free()


func _testar_fluxo_da_main() -> void:
	var cena: Node = load("res://levels/main.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	_checar(paused, "jogo começa pausado na tela de criação")
	var tela: TelaCriacao = null
	for filho in cena.get_node("Interface").get_children():
		if filho is TelaCriacao:
			tela = filho
	_checar(tela != null, "a main abre a tela de criação")
	var jogador: Jogador = cena.get_node("Jogador")
	var x_inicial := jogador.global_position.x
	Input.action_press("mover_direita")
	for i in 10:
		await physics_frame
	Input.action_release("mover_direita")
	_checar(jogador.global_position.x == x_inicial, "herói não anda enquanto cria o personagem")
	var compra := CompraDePontos.new()
	compra.aplicar({Atributos.FORCA: 8, Atributos.DESTREZA: 15, Atributos.CONSTITUICAO: 15,
		Atributos.INTELIGENCIA: 15})
	tela.confirmada.emit(Ficha.new(jogador.classe, compra.valores))
	await process_frame
	_checar(not paused, "ao confirmar, o jogo despausa")
	_checar(jogador.vida_maxima() == 12, "ficha da tela vira a vida do herói (CON 15 -> 12 PV)")
	var hud_texto: String = (cena.get_node("Hud/Vida") as Label).text
	_checar(hud_texto == "PV 12/12", "HUD mostra a vida (%s)" % hud_texto)
	cena.queue_free()


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
