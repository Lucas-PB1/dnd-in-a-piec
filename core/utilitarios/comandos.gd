class_name Comandos
extends RefCounted
## Atalhos do teclado: qual tecla está em cada ação, gravados em user://comandos.cfg.
## A main chama carregar() no começo. Não é autoload.

const ARQUIVO := "user://comandos.cfg"
const SEM_TECLA := "—"

const ACOES: Array[StringName] = [
	&"mover_esquerda",
	&"mover_direita",
	&"pular",
	&"mover_baixo",
	&"atacar",
	&"arremessar",
	&"folego",
	&"inventario",
	&"interagir",
	&"comandos",
	&"correr",
	&"surto_acao",
	&"mente_tatica",
	&"sorte",
	&"defesa",
	&"investida",
	&"rajada",
	&"dado_de_vida",
	&"veneno",
]

const NOMES: Dictionary[StringName, String] = {
	&"mover_esquerda": "Esquerda",
	&"mover_direita": "Direita",
	&"pular": "Pular",
	&"mover_baixo": "Abaixar",
	&"atacar": "Atacar",
	&"arremessar": "Arremessar",
	&"folego": "Fôlego",
	&"inventario": "Inventário",
	&"interagir": "Interagir",
	&"comandos": "Comandos",
	&"correr": "Correr (segurar)",
	&"surto_acao": "Surto de Ação",
	&"mente_tatica": "Mente Tática",
	&"sorte": "Sorte",
	&"defesa": "Defesa (parry)",
	&"investida": "Investida (modo)",
	&"rajada": "Rajada (estilo)",
	&"dado_de_vida": "Dado de vida",
	&"veneno": "Veneno",
}


static func nome(acao: StringName) -> String:
	return NOMES.get(acao, String(acao))


## Troca a tecla da ação. A tecla sai de qualquer outra ação que já a usava.
static func aplicar_tecla(acao: StringName, tecla: Key) -> void:
	if tecla == KEY_NONE or not InputMap.has_action(acao):
		return
	for outra in ACOES:
		if outra != acao:
			_tirar(outra, tecla)
	InputMap.action_erase_events(acao)
	_adicionar(acao, tecla)


## Texto da primeira tecla da ação (ex.: "J").
static func tecla_de(acao: StringName) -> String:
	var tecla := _primeira_tecla(acao)
	if tecla == KEY_NONE:
		return SEM_TECLA
	return OS.get_keycode_string(tecla)


## Aplica o arquivo salvo. Sem arquivo, ficam as teclas do projeto.
static func carregar(caminho: String = ARQUIVO) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(caminho) != OK:
		return
	for acao in ACOES:
		if not cfg.has_section_key("teclas", String(acao)) or not InputMap.has_action(acao):
			continue
		InputMap.action_erase_events(acao)
		_aplicar_salvas(acao, cfg.get_value("teclas", String(acao)))


## Grava todas as teclas atuais, para a próxima vez que o jogo abrir.
static func salvar(caminho: String = ARQUIVO) -> void:
	var cfg := ConfigFile.new()
	for acao in ACOES:
		var teclas: Array = []
		for evento in InputMap.action_get_events(acao):
			if evento is InputEventKey:
				teclas.append(int((evento as InputEventKey).physical_keycode))
		cfg.set_value("teclas", String(acao), teclas)
	cfg.save(caminho)


static func _aplicar_salvas(acao: StringName, valor: Variant) -> void:
	if valor is PackedInt32Array:
		for codigo in valor as PackedInt32Array:
			_adicionar(acao, codigo as Key)
		return
	if valor is Array:
		for codigo in valor as Array:
			_adicionar(acao, int(codigo) as Key)


static func _adicionar(acao: StringName, tecla: Key) -> void:
	if tecla == KEY_NONE:
		return
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	InputMap.action_add_event(acao, evento)


static func _tirar(acao: StringName, tecla: Key) -> void:
	if not InputMap.has_action(acao):
		return
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventKey and (evento as InputEventKey).physical_keycode == tecla:
			InputMap.action_erase_event(acao, evento)


static func _primeira_tecla(acao: StringName) -> Key:
	if not InputMap.has_action(acao):
		return KEY_NONE
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventKey:
			return (evento as InputEventKey).physical_keycode
	return KEY_NONE
