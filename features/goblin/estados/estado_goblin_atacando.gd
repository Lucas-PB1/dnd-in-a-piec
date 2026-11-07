extends EstadoGoblin
## Golpe corpo a corpo: primeiro o aviso (para, olha e brilha), depois só acerta na janela
## da ficha da cena (o Minion, 0,1–0,3 s, é o braço esticado). Com Fuga Ágil, Desengaja
## logo depois.

var _tempo: float = 0.0
var _ligado: bool = false
var _comecou: bool = false


func entrar() -> void:
	_tempo = 0.0
	_ligado = false
	_comecou = false
	iniciar_aviso()


func sair() -> void:
	goblin.encerrar_aviso()
	goblin.desligar_golpe()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		goblin.iniciar_ataque()
		return
	_tempo += delta
	var na_janela := _tempo >= goblin.inicio_acerto and _tempo < goblin.fim_acerto
	if na_janela and not _ligado:
		goblin.ligar_golpe()
		_ligado = true
	elif not na_janela and _ligado:
		goblin.desligar_golpe()
		_ligado = false
	if goblin.animacao_terminou():
		trocar_para.emit(&"Desengajando" if goblin.tem_fuga_agil() else &"Perseguindo")
