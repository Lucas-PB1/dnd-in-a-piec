class_name TelaBestiario
extends Control
## Bestiário: lista de criaturas à esquerda e a página da escolhida à direita (retrato, ficha do
## livro, descrição e dica). Só mostra a ficha de quem o herói já derrotou; as outras ficam como
## "???" e em silhueta. Pausa o jogo. Não conhece o herói: a `main` entrega o registro e as páginas.

## Emitido ao fechar a tela, para quem controla a interface de toque.
signal fechou

const NOME_DESCONHECIDO := "???"
const DICA_DESCONHECIDA := "Derrote esta criatura para descobrir seus segredos."

var _bestiario: Bestiario
var _entradas: Array[EntradaBestiario] = []

@onready var _lista: ItemList = %Lista
@onready var _retrato: TextureRect = %Retrato
@onready var _nome: Label = %Nome
@onready var _tipo: Label = %Tipo
@onready var _ficha: Label = %Ficha
@onready var _descricao: Label = %Descricao
@onready var _dica: Label = %Dica
@onready var _contagem: Label = %Contagem
@onready var _botao_fechar: Button = %Fechar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	hide()
	_lista.item_selected.connect(_mostrar_pagina)
	_botao_fechar.pressed.connect(fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()


func abrir(bestiario: Bestiario, entradas: Array[EntradaBestiario]) -> void:
	_bestiario = bestiario
	_entradas = entradas
	_lista.clear()
	for entrada in _entradas:
		_lista.add_item(_nome_na_lista(entrada))
	_contagem.text = "Descobertas: %d de %d" % [_bestiario.conhecidas(), _entradas.size()]
	show()
	if _lista.item_count > 0:
		_lista.select(0)
		_mostrar_pagina(0)
	_lista.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false
	fechou.emit()


func _nome_na_lista(entrada: EntradaBestiario) -> String:
	return entrada.criatura.nome if _bestiario.foi_derrotada(entrada.criatura.nome) else NOME_DESCONHECIDO


func _mostrar_pagina(indice: int) -> void:
	var entrada := _entradas[indice]
	var criatura := entrada.criatura
	var conhecida := _bestiario.foi_derrotada(criatura.nome)
	_retrato.texture = entrada.retrato
	_retrato.modulate = Color.WHITE if conhecida else Color.BLACK  # silhueta
	_nome.text = criatura.nome if conhecida else NOME_DESCONHECIDO
	_tipo.text = entrada.tipo_texto if conhecida else ""
	_ficha.text = _texto_ficha(criatura) if conhecida else ""
	_descricao.text = entrada.descricao if conhecida else DICA_DESCONHECIDA
	_dica.text = "Dica: %s" % entrada.dica if conhecida else ""


## A ficha do livro em poucas linhas: defesa, ataques, resistências e traços.
func _texto_ficha(c: CriaturaRPG) -> String:
	var linhas: Array[String] = [
		"CA %d · PV %d (%s) · %d pés" % [c.classe_armadura, c.dado_vida().media(), c.dados_vida, int(c.deslocamento_pes)],
		"%s: %+d, %s %s, alcance %d pés" % [c.ataque_nome, c.ataque_bonus, c.ataque_dano,
			TiposDano.nome(c.ataque_tipo_dano), int(c.ataque_alcance_pes)],
	]
	linhas.append_array(_texto_distancia(c))
	linhas.append_array(_texto_tracos(c))
	linhas.append("Derrotada %d vez(es) · vale %d XP" % [_bestiario.quantidade(c.nome), c.experiencia])
	return "\n".join(linhas)


func _texto_distancia(c: CriaturaRPG) -> Array[String]:
	var linhas: Array[String] = []
	if c.arremessos > 0:
		linhas.append("Arremessa %d adagas (%d/%d pés)" % [c.arremessos, int(c.arremesso_normal_pes), int(c.arremesso_longo_pes)])
	if c.disparos != 0:
		linhas.append("%s: %s, %d/%d pés" % [c.disparo_nome, c.disparo_dano, int(c.disparo_normal_pes), int(c.disparo_longo_pes)])
	return linhas


func _texto_tracos(c: CriaturaRPG) -> Array[String]:
	var tracos: Array[String] = []
	if not c.resistencias.is_empty():
		var nomes: Array[String] = []
		for tipo in c.resistencias:
			nomes.append(TiposDano.nome(tipo))
		tracos.append("Resiste a: %s" % ", ".join(nomes))
	if c.corrosao_por_toque > 0:
		tracos.append("Corrói a arma que a fere")
	if c.tem_furtividade:
		tracos.append("Furtividade %+d" % c.bonus_furtividade)
	if c.fuga_agil:
		tracos.append("Fuga Ágil (recua depois de atacar)")
	return tracos
