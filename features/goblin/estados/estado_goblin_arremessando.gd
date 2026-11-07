extends EstadoGoblin
## Ataque à distância: primeiro o aviso (para, olha e brilha), depois o braço estica (a mesma
## animação do golpe) e a adaga ou a flecha sai no meio dele. Não Desengaja: a Fuga Ágil é
## só depois do golpe corpo a corpo.

var _tempo: float = 0.0
var _soltou: bool = false
var _comecou: bool = false


func entrar() -> void:
	_tempo = 0.0
	_soltou = false
	_comecou = false
	iniciar_aviso()


func sair() -> void:
	goblin.encerrar_aviso()


func processar_fisica(delta: float) -> void:
	if not _comecou:
		if avisando(delta):
			return
		_comecou = true
		goblin.iniciar_ataque()
		return
	_tempo += delta
	if _tempo >= goblin.momento_soltura and not _soltou:
		goblin.soltar_distancia()
		_soltou = true
	if goblin.animacao_terminou():
		trocar_para.emit(&"Perseguindo")
