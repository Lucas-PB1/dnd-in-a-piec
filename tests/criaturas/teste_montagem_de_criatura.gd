extends TesteBase
## Kit básico (`MontagemDeCriatura`): ficha completa nos componentes, Lentidão no deslocamento e empurrão.
## godot --headless --debug --path . --script res://tests/teste_montagem_de_criatura.gd

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 42
	_testar_aplicar_ficha()
	_testar_deslocamento_com_lentidao()
	_testar_empurrao()
	print("PASSOU: todos os testes da montagem de criatura" if _falhas == 0 else "FALHOU: %d teste(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _testar_aplicar_ficha() -> void:
	var criatura := CriaturaRPG.new()
	criatura.dados_vida = "2d8+4"
	criatura.classe_armadura = 14
	criatura.resistencias = [&"necrotico"] as Array[StringName]
	criatura.imunidades_dano = [&"veneno"] as Array[StringName]
	criatura.vulnerabilidades = [&"contundente"] as Array[StringName]
	criatura.fortitude_morto_vivo = true
	criatura.imunidades_condicoes = [&"envenenado"] as Array[StringName]
	criatura.tamanho = CriaturaRPG.Tamanho.MEDIO
	var vida := HealthComponent.new()
	var defesa := DefesaComponent.new()
	var condicoes := CondicoesComponent.new()
	MontagemDeCriatura.aplicar_ficha(criatura, vida, defesa, condicoes, _rng)
	_checar(vida.vida_maxima == 13, "vida média de 2d8+4 é 13")
	_checar(defesa.classe_armadura == 14, "CA da ficha")
	_checar(defesa.resistencias == criatura.resistencias, "resistências da ficha")
	_checar(defesa.imunidades == criatura.imunidades_dano, "imunidades de dano da ficha")
	_checar(defesa.vulnerabilidades == criatura.vulnerabilidades, "vulnerabilidades da ficha")
	_checar(defesa.fortitude_morto_vivo, "fortitude da ficha")
	_checar(condicoes.imunidades == criatura.imunidades_condicoes, "imunidades de condição da ficha")
	_checar(condicoes.tamanho == CriaturaRPG.Tamanho.MEDIO, "tamanho da ficha")
	vida.free()
	defesa.free()
	condicoes.free()


func _testar_deslocamento_com_lentidao() -> void:
	var criatura := CriaturaRPG.new()
	criatura.deslocamento_pes = 30.0
	var condicoes := CondicoesComponent.new()
	_checar(is_equal_approx(MontagemDeCriatura.deslocamento_efetivo_pes(criatura, condicoes), 30.0),
		"sem Lentidão: deslocamento cheio")
	condicoes.impor(CondicoesComponent.LENTO, 10.0)
	_checar(is_equal_approx(MontagemDeCriatura.deslocamento_efetivo_pes(criatura, condicoes), 20.0),
		"com Lentidão: −10 pés")
	_checar(
		is_equal_approx(
			MontagemDeCriatura.velocidade_andar(criatura, condicoes),
			EscalaDnd.deslocamento_para_velocidade(20.0)
		),
		"velocidade de andar usa o deslocamento efetivo"
	)
	condicoes.free()


func _testar_empurrao() -> void:
	var corpo := CharacterBody2D.new()
	var restante := MontagemDeCriatura.aplicar_empurrao(corpo, 64.0, 320.0, 0.1)
	_checar(is_equal_approx(corpo.velocity.x, 320.0), "empurrão preenche velocity.x na velocidade dada")
	_checar(is_equal_approx(restante, 32.0), "sobra o que não coube no passo")
	restante = MontagemDeCriatura.aplicar_empurrao(corpo, 0.0, 320.0, 0.1)
	_checar(is_equal_approx(restante, 0.0), "sem empurrão restante não muda")
	corpo.free()
