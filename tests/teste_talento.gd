extends TesteBase
## Nível 4 e escolha de talento: a ficha libera uma escolha no nível 4, valida os aumentos de
## atributo, guarda o talento e o save lembra; a tela lista os talentos escolhíveis e escolhe.
## godot --headless --debug --path . --script res://tests/teste_talento.gd

const TALENTOS_GERAIS_PLANEJADOS := 23

var _classe: ClasseRPG
var _talentos: Array[TalentoRPG] = []


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_classe = load("res://data/classe_guerreiro.tres")
	_talentos.assign(Recursos.da_pasta("res://data/talentos"))
	_testar_nivel_4()
	_testar_regras_da_escolha()
	_testar_aumento_e_teto()
	_testar_save()
	await _testar_tela()
	_testar_pericias_na_ficha()
	await _testar_pericias_na_tela()
	await _testar_na_main()
	print("PASSOU: nível 4 e escolha de talento" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(_falhas)


func _talento(id: StringName) -> TalentoRPG:
	for talento in _talentos:
		if talento.id == id:
			return talento
	return null


func _ficha_nivel_4() -> Ficha:
	var ficha := Ficha.new(_classe, {Atributos.FORCA: 15, Atributos.DESTREZA: 14, Atributos.CONSTITUICAO: 14})
	ficha.definir_nivel_inicial(4)
	return ficha


func _testar_nivel_4() -> void:
	var ficha := Ficha.new(_classe, {Atributos.CONSTITUICAO: 14})
	ficha.adicionar_experiencia(Ficha.XP_POR_NIVEL[3])
	_checar(ficha.nivel == 3 and ficha.escolhas_de_talento_pendentes() == 0, "no nível 3 não há talento a escolher")
	ficha.adicionar_experiencia(Ficha.XP_POR_NIVEL[4] - ficha.experiencia)
	_checar(ficha.nivel == 4 and ficha.escolhas_de_talento_pendentes() == 1, "no nível 4 há uma escolha de talento")
	_checar(ficha.adicionar_experiencia(100000) == 0 and ficha.nivel == Ficha.NIVEL_MAXIMO, "o nível não passa do 4")
	var nivel_3 := Ficha.new(_classe, {Atributos.CONSTITUICAO: 14})
	nivel_3.definir_nivel_inicial(3)
	var nivel_4 := Ficha.new(_classe, {Atributos.CONSTITUICAO: 14})
	nivel_4.definir_nivel_inicial(4)
	_checar(nivel_4.vida_maxima() == nivel_3.vida_maxima() + 8, "o nível 4 acrescenta 6 + CON aos PV")


func _testar_regras_da_escolha() -> void:
	var ficha := _ficha_nivel_4()
	var forca: Array[StringName] = [Atributos.FORCA]
	var destreza: Array[StringName] = [Atributos.DESTREZA]
	var nenhum: Array[StringName] = []
	var geral_planejados := _talentos.filter(func(t: TalentoRPG) -> bool: return t.escolhivel())
	_checar(geral_planejados.size() == TALENTOS_GERAIS_PLANEJADOS, "são %d talentos gerais escolhíveis" % TALENTOS_GERAIS_PLANEJADOS)
	_checar(not ficha.pode_escolher_talento(_talento(&"alerta"), nenhum), "talento de origem não se escolhe no nível 4")
	_checar(not ficha.pode_escolher_talento(_talento(&"ator"), nenhum), "talento em espera não se escolhe")
	_checar(not ficha.pode_escolher_talento(_talento(&"mestre_escudo"), destreza), "o aumento tem de ser num atributo do talento")
	_checar(not ficha.pode_escolher_talento(_talento(&"mestre_escudo"), nenhum), "falta marcar o aumento")
	_checar(ficha.escolher_talento(_talento(&"mestre_escudo"), forca), "Mestre em Escudo com +1 FOR é aceito")
	_checar(ficha.tem_talento(&"mestre_escudo") and ficha.atributos[Atributos.FORCA] == 16, "o talento entra na ficha e a FOR sobe")
	_checar(ficha.escolhas_de_talento_pendentes() == 0, "a escolha foi gasta")
	_checar(not ficha.escolher_talento(_talento(&"cortador"), forca), "sem escolha pendente nada mais entra")
	var nivel_3 := Ficha.new(_classe, {})
	nivel_3.definir_nivel_inicial(3)
	_checar(not nivel_3.escolher_talento(_talento(&"cortador"), forca), "no nível 3 não dá para escolher")


func _testar_aumento_e_teto() -> void:
	var ficha := _ficha_nivel_4()
	var aumento := _talento(&"aumento_de_atributo")
	var dois_em_forca: Array[StringName] = [Atributos.FORCA, Atributos.FORCA]
	var um_so: Array[StringName] = [Atributos.FORCA]
	_checar(not ficha.pode_escolher_talento(aumento, um_so), "o Aumento de Valor de Habilidade exige os 2 pontos")
	_checar(ficha.escolher_talento(aumento, dois_em_forca) and ficha.atributos[Atributos.FORCA] == 17, "+2 em um atributo")
	var no_teto := Ficha.new(_classe, {Atributos.FORCA: 19})
	no_teto.definir_nivel_inicial(4)
	_checar(not no_teto.pode_escolher_talento(aumento, dois_em_forca), "o atributo não passa de 20")
	var um_em_cada: Array[StringName] = [Atributos.FORCA, Atributos.DESTREZA]
	_checar(no_teto.pode_escolher_talento(aumento, um_em_cada), "+1 em dois atributos serve quando um está perto do teto")


func _testar_save() -> void:
	var caminho_antigo := Salvamento.caminho
	Salvamento.caminho = "user://save_talento_teste.json"
	var ficha := _ficha_nivel_4()
	var forca: Array[StringName] = [Atributos.FORCA]
	ficha.escolher_talento(_talento(&"cortador"), forca)
	var dados := Salvamento.para_dicionario(ficha, Inventario.new(), 1)
	var json := JSON.parse_string(JSON.stringify(dados)) as Dictionary
	var lida := Salvamento.montar_ficha(json)
	_checar(lida != null and lida.nivel == 4 and lida.tem_talento(&"cortador"), "o save guarda o nível 4 e o talento")
	_checar(lida.escolhas_de_talento_pendentes() == 0 and lida.atributos[Atributos.FORCA] == 16, "e a escolha já feita, com o aumento")
	var antiga := {"ficha": {"classe": "res://data/classe_guerreiro.tres", "nivel": 4, "talentos": ["Resistente", "Cortador"], "atributos": {}}}
	var migrada := Salvamento.montar_ficha(antiga)
	_checar(migrada != null and migrada.tem_talento(&"resistente") and migrada.tem_talento(&"cortador"), "um save antigo troca os nomes dos talentos pelos do livro")
	DirAccess.remove_absolute(Salvamento.caminho)
	Salvamento.caminho = caminho_antigo


func _testar_tela() -> void:
	var ficha := _ficha_nivel_4()
	var tela: TelaTalento = load("res://ui/talento/tela_talento.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	tela.abrir(ficha, _talentos)
	var lista: ItemList = tela.get_node("%Lista")
	var botao: Button = tela.get_node("%Escolher")
	_checar(lista.item_count == TALENTOS_GERAIS_PLANEJADOS, "a tela lista só os talentos escolhíveis")
	_checar(botao.disabled, "Escolher fica apagado até marcar o aumento")
	var indice := _indice_na_lista(lista, "Retalhador")
	lista.select(indice)
	lista.item_selected.emit(indice)
	var atributos: HFlowContainer = tela.get_node("%Atributos")
	await process_frame
	_checar(atributos.get_child_count() == 2, "o Cortador oferece 2 atributos (FOR e DES)")
	(atributos.get_child(1) as Button).pressed.emit()
	_checar(not botao.disabled, "marcado o aumento, Escolher acende")
	var escolhido: Array[TalentoRPG] = []
	tela.talento_escolhido.connect(func(t: TalentoRPG) -> void: escolhido.append(t))
	botao.pressed.emit()
	_checar(escolhido.size() == 1 and ficha.tem_talento(&"cortador") and ficha.atributos[Atributos.DESTREZA] == 15,
		"escolher grava o talento e o +1 DES na ficha")
	_checar(not tela.visible and not paused, "a tela fecha e despausa")
	tela.queue_free()
	await process_frame


func _testar_na_main() -> void:
	var main: Main = load("res://levels/main.tscn").instantiate()
	main.mostrar_inicio = false
	root.add_child(main)
	for i in 4:
		await process_frame
	var jogador: Jogador = main.get_node("Jogador")
	var tela: TelaTalento = main.get_node("Interface/TelaTalento")
	var pausa: TelaPausa = main.get_node("Interface/TelaPausa")
	main.tirar_criaturas()
	_checar(not tela.visible, "antes do nível 4 a escolha não aparece")
	jogador.ganhar_experiencia(Ficha.XP_POR_NIVEL[4])
	for i in 3:
		await process_frame
	_checar(jogador.ficha.nivel == 4 and tela.visible and paused, "subir ao nível 4 abre a escolha de talento")
	tela.fechar()
	pausa.abrir()
	_checar((pausa.get_node("%Talento") as Button).visible, "a pausa mostra o botão Escolher talento enquanto há escolha")
	pausa.fechar()
	var vida_antes := jogador.vida_maxima()
	var constituicao: Array[StringName] = [Atributos.CONSTITUICAO]
	_checar(jogador.ficha.escolher_talento(_talento(&"duravel"), constituicao), "o Durável aceita +1 CON")
	jogador.ao_mudar_ficha()
	_checar(jogador.vida_maxima() >= vida_antes, "depois da escolha o herói recalcula a vida máxima")
	pausa.abrir()
	_checar(jogador.ficha.escolhas_de_talento_pendentes() == 0, "sem escolha pendente nada sobra")
	pausa.fechar()
	main.free()
	await process_frame

func _testar_pericias_na_ficha() -> void:
	var ficha := _ficha_nivel_4()
	ficha.pericias = [Pericia.PERCEPCAO, Pericia.ATLETISMO]
	var observador := _talento(&"observador")
	var sabedoria: Array[StringName] = [Atributos.SABEDORIA]
	var vazio: Array[StringName] = []
	var intuicao: Array[StringName] = [Pericia.INTUICAO]
	var percepcao: Array[StringName] = [Pericia.PERCEPCAO]
	var atletismo: Array[StringName] = [Pericia.ATLETISMO]
	_checar(not ficha.pode_escolher_talento(observador, sabedoria, vazio), "o Observador exige escolher uma perícia")
	_checar(not ficha.pode_escolher_talento(observador, sabedoria, atletismo), "o Observador só aceita Intuição, Investigação ou Percepção")
	var antes := ficha.percepcao_passiva()
	_checar(ficha.escolher_talento(observador, sabedoria, percepcao), "o Observador com Percepção já treinada é aceito")
	_checar(ficha.pericias_especializadas.has(Pericia.PERCEPCAO) and ficha.percepcao_passiva() == antes + Ficha.BONUS_PROFICIENCIA,
		"já treinada, a Percepção ganha Especialização (passiva +2)")
	var outra := _ficha_nivel_4()
	outra.pericias = [Pericia.ATLETISMO]
	_checar(outra.escolher_talento(observador, sabedoria, intuicao) and outra.proficiente_na_pericia(Pericia.INTUICAO)
		and not outra.pericias_especializadas.has(Pericia.INTUICAO), "sem treino, o Observador dá a proficiência")
	var perito := _ficha_nivel_4()
	perito.pericias = [Pericia.ATLETISMO]
	var especialista := _talento(&"especialista_em_pericia")
	var forca: Array[StringName] = [Atributos.FORCA]
	var acrobacia_e_atletismo: Array[StringName] = [Pericia.ACROBACIA, Pericia.ATLETISMO]
	_checar(not perito.pode_escolher_talento(especialista, forca, atletismo + atletismo), "a perícia nova não pode ser uma que já treina")
	var acrobacia_e_historia: Array[StringName] = [Pericia.ACROBACIA, Pericia.HISTORIA]
	_checar(not perito.pode_escolher_talento(especialista, forca, acrobacia_e_historia), "a Especialização exige perícia treinada")
	_checar(perito.escolher_talento(especialista, forca, acrobacia_e_atletismo), "Especialista em Perícia: Acrobacia nova e Especialização em Atletismo")
	_checar(perito.proficiente_na_pericia(Pericia.ACROBACIA) and perito.pericias_especializadas.has(Pericia.ATLETISMO)
		and perito.bonus_pericia(Pericia.ATLETISMO) == perito.modificador(Atributos.FORCA) + 2 * Ficha.BONUS_PROFICIENCIA,
		"o bônus da perícia especializada soma a proficiência duas vezes")
	var json := JSON.parse_string(JSON.stringify(Salvamento.para_dicionario(perito, Inventario.new(), 1))) as Dictionary
	_checar(Salvamento.montar_ficha(json).pericias_especializadas.has(Pericia.ATLETISMO), "o save guarda a Especialização")


func _testar_pericias_na_tela() -> void:
	var ficha := _ficha_nivel_4()
	ficha.pericias = [Pericia.ATLETISMO]
	var tela: TelaTalento = load("res://ui/talento/tela_talento.tscn").instantiate()
	root.add_child(tela)
	await process_frame
	tela.abrir(ficha, _talentos)
	var lista: ItemList = tela.get_node("%Lista")
	var indice := _indice_na_lista(lista, "Especialista em Perícia")
	lista.select(indice)
	lista.item_selected.emit(indice)
	await process_frame
	await process_frame
	_checar((tela.get_node("%LinhaPericia1") as Control).visible and (tela.get_node("%LinhaPericia2") as Control).visible, "o Especialista em Perícia mostra os dois seletores")
	var painel := tela.find_children("Painel", "PanelContainer", true, false)[0] as Control
	var tamanho := painel.get_combined_minimum_size()
	_checar(tamanho.x <= 640 and tamanho.y <= 360, "com os dois seletores a tela ainda cabe em 640x360 (%dx%d)" % [tamanho.x, tamanho.y])
	(tela.get_node("%Atributos").get_child(0) as Button).pressed.emit()
	_checar(not (tela.get_node("%Escolher") as Button).disabled, "com atributo e perícias marcados, Escolher acende")
	tela.escolher()
	_checar(ficha.tem_talento(&"especialista_em_pericia") and ficha.pericias_especializadas.size() == 1, "escolher grava o talento e a Especialização")
	tela.queue_free()
	await process_frame

func _indice_na_lista(lista: ItemList, nome: String) -> int:
	for i in lista.item_count:
		if lista.get_item_text(i) == nome:
			return i
	return 0
