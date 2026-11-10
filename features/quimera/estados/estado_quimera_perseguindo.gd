extends EstadoQuimera
## Decide a próxima ação: ruge se acabou de se enfurecer; senão o padrão que `escolher_padrao` sorteia (combo de perto, Sopro,
## bote, investida ou voo) quando o ritmo de ataque permite; senão anda até o herói.


func processar_fisica(_delta: float) -> void:
	if not quimera.alvo_percebido():
		trocar_para.emit(&"Parado")
	elif quimera.deve_rugir():
		trocar_para.emit(&"Rugindo")
	elif quimera.pode_atacar():
		_agir()
	else:
		_correr_ou_esperar()


## Pode atacar: tenta um padrão; se nenhum serve agora, segue andando.
func _agir() -> void:
	var padrao := quimera.escolher_padrao()
	if padrao == &"":
		_correr_ou_esperar()
		return
	quimera.parar()
	trocar_para.emit(padrao)


## Perto o bastante para golpear, só espera a vez (freando); longe, anda até o herói e, diante de obstáculo, salta.
func _correr_ou_esperar() -> void:
	if quimera.alvo_ao_alcance():
		quimera.parar()
		quimera.virar_para_alvo()
	else:
		var plano := quimera.planejar_salto()
		if plano.tipo != SaltoDnd.Tipo.NENHUM:
			quimera.iniciar_salto(plano)
			trocar_para.emit(&"Pulando")
			return
		quimera.andar_para_alvo()
	quimera.tocar(&"andar" if quimera.em_movimento() else &"parado")  # na beira de um vão grande ela só espera
