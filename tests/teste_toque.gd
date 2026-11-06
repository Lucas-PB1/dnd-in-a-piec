extends SceneTree
## Controles de toque (celular): botões apertam as ações, o analógico anda e corre, as
## setas fazem o toque duplo, "correr" segurado corre, nada aperta com o jogo pausado.
## Edição do layout: arrastar, tamanho, transparência, salvar, carregar e Padrão. O
## user://toque.cfg de verdade é guardado antes e devolvido no fim.
## godot --headless --debug --path . --script res://tests/teste_toque.gd

const DEDO_BOTAO := 1
const DEDO_ANALOGICO := 0
## Fração do raio do analógico: andar (antes da zona de corrida) e correr (na borda).
const ANDAR := 0.5
const CORRER := 1.0
## Para onde o botão Pular é arrastado na edição (metade de cima e da esquerda da tela).
const DESTINO_ARRASTO := Vector2(200, 150)
const PASSOS_TAMANHO := 2
const OPACIDADE_TESTE := 0.5

var _falhas := 0
var _main: Main
var _jogador: Jogador
var _controles: ControlesToque
var _config_original: PackedByteArray = PackedByteArray()
var _tinha_config: bool = false


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_guardar_config()
	_testar_opcoes()
	_main = load("res://levels/main.tscn").instantiate()
	_main.mostrar_inicio = false
	root.add_child(_main)
	_jogador = _main.get_node("Jogador")
	_controles = _main.get_node("ControlesToque")
	_main.tirar_criaturas()
	OpcoesToque.mostrar = OpcoesToque.Mostrar.SEMPRE
	OpcoesToque.modo = OpcoesToque.Modo.ANALOGICO
	_controles.atualizar()
	await _esperar(30)

	await _testar_botao()
	await _testar_analogico()
	await _testar_setas()
	await _testar_correr_segurado()
	_testar_pausa()
	await _testar_edicao()
	_main.queue_free()
	_devolver_config()

	if _falhas == 0:
		print("PASSOU: todos os testes do toque")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_opcoes() -> void:
	OpcoesToque.mostrar = OpcoesToque.Mostrar.SEMPRE
	var sempre := OpcoesToque.visiveis()
	OpcoesToque.mostrar = OpcoesToque.Mostrar.NUNCA
	_checar(sempre and not OpcoesToque.visiveis(), "opção Sempre mostra e Nunca esconde os controles")


func _testar_botao() -> void:
	_checar(_controles.esta_visivel() and _controles.analogico().is_visible_in_tree()
		and not _controles.botao(&"mover_esquerda").is_visible_in_tree(), "modo analógico: aparece o analógico, não as setas")
	_checar(_controles.botao(&"surto_acao") != null,
		"os controles de toque incluem o botão do Surto de Ação")
	var pular := _controles.botao(&"pular")
	_tocar(DEDO_BOTAO, _centro(pular), true)
	_checar(Input.is_action_pressed(&"pular"), "dedo no botão Pular aperta a ação pular")
	_tocar(DEDO_BOTAO, _centro(pular), false)
	_checar(not Input.is_action_pressed(&"pular"), "tirar o dedo solta a ação")
	_tocar(DEDO_BOTAO, Vector2(2, 2), true)
	_checar(not Input.is_action_pressed(&"pular") and not Input.is_action_pressed(&"atacar"), "toque fora dos botões não aperta nada")
	_tocar(DEDO_BOTAO, Vector2(2, 2), false)
	await _esperar(10)  # o pulo pedido pelo botão sai no próximo quadro (buffer)
	await _no_chao()


func _testar_analogico() -> void:
	var analogico := _controles.analogico()
	var centro := _centro(analogico)
	var raio := analogico.size.x / 2.0
	_tocar(DEDO_ANALOGICO, centro, true)
	_arrastar(DEDO_ANALOGICO, centro + Vector2(raio * ANDAR, 0.0))
	await _esperar(10)
	_checar(Input.is_action_pressed(&"mover_direita") and not Input.is_action_pressed(&"correr")
		and _jogador.nome_estado() == &"Andando", "analógico pela metade: anda")
	_arrastar(DEDO_ANALOGICO, centro + Vector2(raio * CORRER, 0.0))
	await _esperar(10)
	_checar(_jogador.nome_estado() == &"Correndo", "analógico na borda: corre")
	_arrastar(DEDO_ANALOGICO, centro + Vector2(raio * ANDAR, 0.0))
	await _esperar(5)
	_checar(_jogador.nome_estado() == &"Andando", "voltou o analógico do fim: anda de novo")
	_arrastar(DEDO_ANALOGICO, centro + Vector2(0.0, -raio))
	_checar(Input.is_action_pressed(&"mirar_cima") and not Input.is_action_pressed(&"pular"), "para cima mira (não pula)")
	_tocar(DEDO_ANALOGICO, centro, false)
	_checar(not Input.is_action_pressed(&"mover_direita") and not Input.is_action_pressed(&"mirar_cima"), "soltou: nada apertado")
	await _esperar(30)


func _testar_setas() -> void:
	OpcoesToque.modo = OpcoesToque.Modo.SETAS
	_controles.atualizar()
	_checar(not _controles.analogico().is_visible_in_tree() and _controles.botao(&"mover_direita").is_visible_in_tree(),
		"modo setas: aparecem as setas, não o analógico")
	var direita := _centro(_controles.botao(&"mover_direita"))
	_tocar(DEDO_BOTAO, direita, true)
	await _esperar(2)
	_tocar(DEDO_BOTAO, direita, false)
	await _esperar(2)
	_tocar(DEDO_BOTAO, direita, true)
	await _esperar(8)
	_checar(_jogador.nome_estado() == &"Correndo", "dois toques na seta: corre (toque duplo)")
	_tocar(DEDO_BOTAO, direita, false)
	await _esperar(30)
	OpcoesToque.modo = OpcoesToque.Modo.ANALOGICO
	_controles.atualizar()


func _testar_correr_segurado() -> void:
	Input.action_press(&"correr")
	Input.action_press(&"mover_esquerda")
	await _esperar(8)
	_checar(_jogador.nome_estado() == &"Correndo", "segurar correr (Shift) com a direção: corre")
	Input.action_release(&"correr")
	await _esperar(3)
	_checar(_jogador.nome_estado() == &"Andando", "largar o correr: volta a andar")
	Input.action_release(&"mover_esquerda")
	await _esperar(30)


func _testar_pausa() -> void:
	paused = true
	var atacar := _controles.botao(&"atacar")
	_tocar(DEDO_BOTAO, _centro(atacar), true)
	_checar(not Input.is_action_pressed(&"atacar"), "com o jogo pausado (menu aberto) o botão não aperta")
	_tocar(DEDO_BOTAO, _centro(atacar), false)
	paused = false
	_main.call(&"_pausar", true)
	_checar(not _controles.esta_visivel(), "telas de pausa (título, criação) escondem os controles")
	_main.call(&"_pausar", false)
	_checar(_controles.esta_visivel(), "voltou ao jogo: os controles voltam")


func _testar_edicao() -> void:
	var comandos: TelaComandos = _main.get_node("Interface/TelaComandos")
	comandos.abrir()
	(comandos.find_child("AjustarToque", true, false) as Button).pressed.emit()
	_checar(_controles.esta_editando() and paused and not comandos.visible, "Ajustar botões (tela de comandos) abre a edição com o jogo pausado")
	var pular := _controles.botao(&"pular")
	var raio_antes := pular.size.x / 2.0
	_tocar(DEDO_BOTAO, _centro(pular), true)
	_checar(not Input.is_action_pressed(&"pular"), "na edição, tocar no botão não aperta a ação")
	_arrastar(DEDO_BOTAO, DESTINO_ARRASTO)
	_tocar(DEDO_BOTAO, DESTINO_ARRASTO, false)
	_checar(_centro(pular).distance_to(DESTINO_ARRASTO) < 1.0, "arrastar leva o botão para onde o dedo soltou")
	var salvo: Array = OpcoesToque.posicoes.get("pular", [])
	_checar(salvo.size() == 5 and salvo[0] == 0.0 and salvo[1] == 0.0, "o botão fica preso ao canto mais perto (alto à esquerda)")
	_controles.mudar_tamanho(PASSOS_TAMANHO)
	_checar(is_equal_approx(pular.size.x / 2.0, raio_antes + PASSOS_TAMANHO * ControlesToque.PASSO_RAIO)
		and _centro(pular).distance_to(DESTINO_ARRASTO) < 1.0, "+ aumenta o selecionado sem tirar do lugar")
	_controles.mudar_opacidade(OPACIDADE_TESTE)
	_checar(is_equal_approx(_controles.get_node("Raiz").modulate.a, OPACIDADE_TESTE), "a barra muda a transparência")
	_controles.terminar_edicao()
	_checar(not _controles.esta_editando() and not paused, "Pronto: sai da edição e o jogo volta")
	OpcoesToque.posicoes = {}
	OpcoesToque.carregar()
	var outro: ControlesToque = load("res://ui/controles_toque/controles_toque.tscn").instantiate()
	root.add_child(outro)
	await process_frame
	_checar(_centro(outro.botao(&"pular")).distance_to(DESTINO_ARRASTO) < 1.0
		and is_equal_approx(OpcoesToque.opacidade, OPACIDADE_TESTE), "o layout salvo volta ao abrir o jogo de novo")
	outro.queue_free()
	_controles.restaurar_padrao()
	await process_frame
	_checar(_centro(pular).distance_to(DESTINO_ARRASTO) > 50.0 and is_equal_approx(OpcoesToque.opacidade, OpcoesToque.OPACIDADE_PADRAO),
		"Padrão devolve lugares e transparência de fábrica")


## Guarda o user://toque.cfg do jogador: o teste salva um layout de mentira.
func _guardar_config() -> void:
	_tinha_config = FileAccess.file_exists(OpcoesToque.ARQUIVO)
	if _tinha_config:
		_config_original = FileAccess.get_file_as_bytes(OpcoesToque.ARQUIVO)


func _devolver_config() -> void:
	if _tinha_config:
		var arquivo := FileAccess.open(OpcoesToque.ARQUIVO, FileAccess.WRITE)
		arquivo.store_buffer(_config_original)
		arquivo.close()
	else:
		DirAccess.remove_absolute(OpcoesToque.ARQUIVO)


func _centro(controle: Control) -> Vector2:
	return controle.global_position + controle.size / 2.0


func _tocar(dedo: int, onde: Vector2, apertado: bool) -> void:
	var toque := InputEventScreenTouch.new()
	toque.index = dedo
	toque.position = onde
	toque.pressed = apertado
	root.push_input(toque, true)


func _arrastar(dedo: int, onde: Vector2) -> void:
	var arrasto := InputEventScreenDrag.new()
	arrasto.index = dedo
	arrasto.position = onde
	root.push_input(arrasto, true)


func _no_chao() -> void:
	for i in 120:
		if _jogador.is_on_floor() and _jogador.nome_estado() == &"Parado":
			return
		await physics_frame


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _checar(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  ok   - ", descricao)
	else:
		_falhas += 1
		print("  ERRO - ", descricao)
