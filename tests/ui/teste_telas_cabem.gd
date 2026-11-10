extends TesteBase
## Garante que as telas de menu cabem na tela do jogo (640x360), cada passo da criação inclusive.
## O tema novo deixou a criação maior que a tela uma vez; este teste evita que volte a acontecer.
## godot --headless --debug --path . --script res://tests/ui/teste_telas_cabem.gd

const LARGURA := 640
const ALTURA := 360
const TELAS: Dictionary[String, String] = {
	"título": "res://ui/titulo/tela_titulo.tscn",
	"pausa": "res://ui/pausa/tela_pausa.tscn",
	"bestiário": "res://ui/bestiario/tela_bestiario.tscn",
	"compêndio": "res://ui/compendio/tela_compendio.tscn",
	"talento": "res://ui/talento/tela_talento.tscn",
	"subclasse": "res://ui/subclasse/tela_subclasse.tscn",
	"habilidades": "res://ui/habilidades/tela_habilidades.tscn",
	"inventário": "res://ui/inventario/tela_inventario.tscn",
	"baú": "res://ui/bau/tela_bau.tscn",
	"comandos": "res://ui/comandos/tela_comandos.tscn",
	"derrota": "res://ui/derrota/tela_derrota.tscn",
	"vitória": "res://ui/vitoria/tela_vitoria.tscn",
}


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	for nome in TELAS:
		await _conferir(nome, TELAS[nome], false)
	await _conferir("criação", "res://ui/criacao_personagem/tela_criacao.tscn", true)
	print("PASSOU: todas as telas cabem em 640x360" if _falhas == 0 else "FALHOU: %d tela(s) não cabem" % _falhas)
	quit(_falhas)


## Mostra a tela (cada passo da criação, um de cada vez) e compara o painel com a tela do jogo.
func _conferir(nome: String, caminho: String, por_passos: bool) -> void:
	var tela: Control = load(caminho).instantiate()
	root.add_child(tela)
	if tela.has_method(&"abrir") and nome == "pausa":
		tela.call(&"abrir")
	await process_frame
	await process_frame
	var painel := tela.find_children("Painel", "PanelContainer", true, false)
	var coluna := tela.find_child("Coluna", true, false)
	var passos: Array[Node] = []
	if por_passos and coluna:
		for filho in coluna.get_children():
			if filho.name.begins_with("Passo"):
				passos.append(filho)
	if passos.is_empty():
		_medir(nome, painel)
	else:
		for passo in passos:
			for outro in passos:
				outro.visible = outro == passo
			await process_frame
			await process_frame
			_medir("%s (%s)" % [nome, passo.name], painel)
	tela.queue_free()
	await process_frame


func _medir(nome: String, paineis: Array[Node]) -> void:
	if paineis.is_empty():
		print("  ok   - %s: sem painel para medir" % nome)
		return
	var painel := paineis[0] as Control
	var tamanho := painel.get_combined_minimum_size()
	_checar(tamanho.x <= LARGURA and tamanho.y <= ALTURA, "%s cabe (%dx%d)" % [nome, tamanho.x, tamanho.y])
