extends TesteBase
## Sensação dos golpes: acerto dá pausa curta, tremor de câmera e faíscas; erro não faz nada;
## crítico é mais forte; golpe sofrido pelo herói também; pouso e corrida soltam poeira; e o tempo
## do jogo sempre volta ao normal. godot --headless --debug --path . --script res://tests/combate/teste_impacto.gd

const ESPERA_PAUSA := 0.4
const ESPERA_CURTA := 0.05
## Faíscas vivem 0,3 s e somem 0,2 s depois.
const ESPERA_FAISCAS := 0.7

var _cena: Main
var _jogador: Jogador
var _impacto: Impacto


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	_cena = load("res://levels/main.tscn").instantiate()
	_cena.mostrar_inicio = false
	root.add_child(_cena)
	_jogador = _cena.get_node("Jogador")
	_impacto = _cena.get_node("Impacto")
	_cena.tirar_criaturas()
	await _esperar(0.1)
	await _testar_acerto()
	await _testar_erro()
	await _testar_critico()
	await _testar_golpe_sofrido()
	await _testar_poeira()
	_cena.queue_free()
	if _falhas == 0:
		print("PASSOU: todos os testes do impacto")
	else:
		print("FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_acerto() -> void:
	var defesa := _defesa_do_boneco()
	var camera := _camera()
	var antes := _impacto.get_child_count()
	defesa.golpe_resolvido.emit(_resultado(true, false), Vector2.ZERO)
	_checar(Engine.time_scale < 1.0, "acerto: o tempo quase para por um instante")
	_checar(camera.esta_tremendo(), "acerto: a câmera treme")
	_checar(_impacto.get_child_count() > antes, "acerto: saem faíscas")
	await _esperar(ESPERA_PAUSA)
	_checar(is_equal_approx(Engine.time_scale, 1.0), "o tempo volta ao normal depois da pausa")
	camera._process(1.0)  # no teste o quadro de câmera quase não roda: avança o tempo dela na mão
	_checar(not camera.esta_tremendo(), "e o tremor acalma sozinho")


func _testar_erro() -> void:
	await _esperar(ESPERA_FAISCAS)  # as faíscas do teste anterior somem sozinhas
	_camera()._process(1.0)
	var defesa := _defesa_do_boneco()
	var antes := _impacto.get_child_count()
	defesa.golpe_resolvido.emit(_resultado(false, false), Vector2.ZERO)
	_checar(is_equal_approx(Engine.time_scale, 1.0) and not _camera().esta_tremendo() and _impacto.get_child_count() == antes,
		"erro: nada de pausa, tremor ou faísca")


func _testar_critico() -> void:
	var defesa := _defesa_do_boneco()
	defesa.golpe_resolvido.emit(_resultado(true, false), Vector2.ZERO)
	var comum := _camera()._forca_tremor
	await _esperar(ESPERA_PAUSA)
	defesa.golpe_resolvido.emit(_resultado(true, true), Vector2.ZERO)
	_checar(_camera()._forca_tremor > comum, "crítico: tremor mais forte que o acerto comum")
	await _esperar(ESPERA_PAUSA)


func _testar_golpe_sofrido() -> void:
	var defesa := _jogador.get_node("Defesa") as DefesaComponent
	var antes := _impacto.get_child_count()
	defesa.golpe_resolvido.emit(_resultado(true, false), Vector2.ZERO)
	_checar(_camera().esta_tremendo() and _impacto.get_child_count() > antes, "herói apanhando: tremor e faíscas também")
	await _esperar(ESPERA_PAUSA)


func _testar_poeira() -> void:
	var antes := _impacto.get_child_count()
	_jogador.aterrissou.emit()
	_checar(_impacto.get_child_count() > antes, "pouso: levanta poeira")
	await _esperar(ESPERA_PAUSA * 2.0)
	_checar(is_equal_approx(Engine.time_scale, 1.0), "no fim, o tempo do jogo está normal")


func _defesa_do_boneco() -> DefesaComponent:
	return _cena.get_node("BonecoTreino/Defesa") as DefesaComponent


func _camera() -> CameraJogador:
	return _jogador.get_node("Camera") as CameraJogador


func _resultado(acertou: bool, critico: bool) -> Combate.Resultado:
	var r := Combate.Resultado.new()
	r.golpe = Golpe.new("teste", 0, Dado.new(1, 4))
	r.acertou = acertou
	r.critico = critico
	r.dano = 3 if acertou else 0
	return r


## Espera tempo REAL (o teste não pode depender do tempo do jogo, que a pausa desacelera).
func _esperar(segundos: float) -> void:
	await create_timer(segundos, true, false, true).timeout
