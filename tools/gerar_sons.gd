extends SceneTree
## Gera por código os efeitos sonoros que os pacotes CC0 não têm (impactos, dano, morte, magia,
## cura, subir de nível, tiro de arco). Tudo original: ruído filtrado, ondas simples e envelopes.
##   godot --headless --path . --script res://tools/gerar_sons.gd
##   godot --headless --path . --import
## Saem em assets/audio/sintetizados/*.wav (16 bits, 44,1 kHz, mono).

const PASTA := "res://assets/audio/sintetizados/"
const TAXA := 44100
const PICO := 0.9


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	_salvar("whoosh_1", _whoosh(0.16, 900.0, 3200.0, rng))
	_salvar("whoosh_2", _whoosh(0.2, 600.0, 2400.0, rng))
	_salvar("whoosh_pesado", _whoosh(0.28, 300.0, 1500.0, rng))
	_salvar("acerto_1", _impacto(0.14, 160.0, 0.55, rng))
	_salvar("acerto_2", _impacto(0.16, 130.0, 0.6, rng))
	_salvar("acerto_critico", _somar([_impacto(0.3, 90.0, 0.9, rng), _brilho(0.25, 1320.0, 0.35)]))
	_salvar("apanhar", _impacto(0.22, 110.0, 0.85, rng))
	_salvar("morte_heroi", _queda(0.9, 220.0, 50.0, rng))
	_salvar("estouro", _estouro(0.45, rng))
	_salvar("surto_ativar", _subida(0.5, 330.0, 1320.0, 0.55))
	_salvar("surto_golpe", _somar([_subida(0.25, 660.0, 1760.0, 0.5), _impacto(0.18, 140.0, 0.6, rng)]))
	_salvar("folego", _acorde(0.8, [523.25, 659.25, 783.99, 1046.5], 0.16))
	_salvar("nivel", _arpejo([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.11, 0.22))
	_salvar("tiro_arco", _corda(0.22, 220.0, rng))
	_salvar("pouso", _impacto(0.1, 90.0, 0.4, rng))
	_salvar("aviso_monstro", _subida(0.3, 200.0, 420.0, 0.3))
	_salvar("golpe_monstro", _whoosh(0.24, 250.0, 1200.0, rng))
	_salvar("rugido", _rugido(1.0, 150.0, rng))
	_salvar("rugido_morte", _rugido(1.6, 95.0, rng))
	_salvar("tremor", _tremor(1.1, rng))
	print("Sons gerados em ", PASTA)
	quit()


## Vento cortante: ruído com um filtro que sobe de `de` a `ate` Hz e some.
func _whoosh(duracao: float, de: float, ate: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var filtro := 0.0
	for i in n:
		var t := float(i) / n
		var corte := lerpf(de, ate, t) / TAXA * TAU
		var alfa := clampf(corte, 0.01, 0.9)
		filtro += alfa * (rng.randf_range(-1.0, 1.0) - filtro)
		saida[i] = filtro * sin(PI * t) * 1.8
	return saida


## Pancada: ruído curto mais um "tum" grave que desce.
func _impacto(duracao: float, grave: float, forca: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var fase := 0.0
	var filtro := 0.0
	for i in n:
		var t := float(i) / n
		var envelope := pow(1.0 - t, 3.0)
		fase += TAU * lerpf(grave * 1.6, grave * 0.5, t) / TAXA
		filtro += 0.35 * (rng.randf_range(-1.0, 1.0) - filtro)
		saida[i] = (sin(fase) * 0.8 + filtro * forca) * envelope
	return saida


## Brilho metálico curto (um tom com harmônico) para destacar o crítico.
func _brilho(duracao: float, frequencia: float, forca: float) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	for i in n:
		var t := float(i) / n
		var s := sin(TAU * frequencia * i / TAXA) + 0.5 * sin(TAU * frequencia * 2.01 * i / TAXA)
		saida[i] = s * forca * pow(1.0 - t, 2.0)
	return saida


## Queda longa: tom grave que desce e ruído que some (o herói tomba).
func _queda(duracao: float, de: float, ate: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var fase := 0.0
	var filtro := 0.0
	for i in n:
		var t := float(i) / n
		fase += TAU * lerpf(de, ate, t) / TAXA
		filtro += 0.2 * (rng.randf_range(-1.0, 1.0) - filtro)
		saida[i] = (sin(fase) * 0.7 + filtro * 0.5 * (1.0 - t)) * pow(1.0 - t, 1.5)
	return saida


## Estouro do monstro: ruído em explosão que escurece rápido.
func _estouro(duracao: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var filtro := 0.0
	for i in n:
		var t := float(i) / n
		filtro += lerpf(0.7, 0.04, t) * (rng.randf_range(-1.0, 1.0) - filtro)
		saida[i] = filtro * pow(1.0 - t, 2.0) * 1.6
	return saida


## Magia subindo: um tom que sobe de `de` a `ate` com um segundo tom em quinta, e some no fim.
func _subida(duracao: float, de: float, ate: float, forca: float) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var fase := 0.0
	for i in n:
		var t := float(i) / n
		fase += TAU * lerpf(de, ate, t * t) / TAXA
		saida[i] = (sin(fase) + 0.4 * sin(fase * 1.5)) * forca * sin(PI * minf(t * 1.2, 1.0)) * (1.0 - t * 0.4)
	return saida


## Vários tons ao mesmo tempo, com ataque suave (cura).
func _acorde(duracao: float, notas: Array, forca: float) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	for i in n:
		var t := float(i) / n
		var soma := 0.0
		for f: float in notas:
			soma += sin(TAU * f * i / TAXA)
		saida[i] = soma * forca * sin(PI * pow(t, 0.6)) * pow(1.0 - t, 0.8)
	return saida


## Notas uma depois da outra (subir de nível).
func _arpejo(notas: Array, intervalo: float, duracao_nota: float) -> PackedFloat32Array:
	var total := int((intervalo * (notas.size() - 1) + duracao_nota) * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(total)
	for k in notas.size():
		var inicio := int(k * intervalo * TAXA)
		var n := int(duracao_nota * TAXA)
		for i in n:
			var t := float(i) / n
			var indice := inicio + i
			if indice < total:
				saida[indice] += (sin(TAU * notas[k] * i / TAXA) + 0.3 * sin(TAU * notas[k] * 2.0 * i / TAXA)) * 0.28 * pow(1.0 - t, 1.6)
	return saida


## Corda de arco: tom curto que cai de leve e vibra.
func _corda(duracao: float, frequencia: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var fase := 0.0
	for i in n:
		var t := float(i) / n
		fase += TAU * (frequencia * (1.0 - 0.3 * t)) / TAXA
		saida[i] = (sin(fase) + 0.5 * sin(fase * 2.0) + rng.randf_range(-0.12, 0.12) * (1.0 - t)) * pow(1.0 - t, 2.2) * 0.7
	return saida


## Rugido de chefe: tom grave de dente de serra com vibrato que desce, mais ruído rouco; sobe rápido e some devagar.
func _rugido(duracao: float, grave: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var fase := 0.0
	var filtro := 0.0
	for i in n:
		var t := float(i) / n
		var vibrato := 1.0 + 0.06 * sin(TAU * 28.0 * t * duracao)
		fase += TAU * lerpf(grave * 1.5, grave * 0.7, t) * vibrato / TAXA
		filtro += 0.25 * (rng.randf_range(-1.0, 1.0) - filtro)
		var dente := fmod(fase / TAU, 1.0) * 2.0 - 1.0
		var envelope := minf(t * 12.0, 1.0) * pow(1.0 - t, 1.4)
		saida[i] = (dente * 0.6 + sin(fase) * 0.4 + filtro * 0.5) * envelope
	return saida


## Tremor do chão: seno muito grave que desce e ruído abafado, com cauda longa.
func _tremor(duracao: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var saida := PackedFloat32Array()
	saida.resize(n)
	var fase := 0.0
	var filtro := 0.0
	for i in n:
		var t := float(i) / n
		fase += TAU * lerpf(70.0, 32.0, t) / TAXA
		filtro += 0.06 * (rng.randf_range(-1.0, 1.0) - filtro)
		saida[i] = (sin(fase) * 0.85 + filtro * 1.4) * pow(1.0 - t, 2.2)
	return saida


func _somar(trilhas: Array) -> PackedFloat32Array:
	var maior := 0
	for t: PackedFloat32Array in trilhas:
		maior = maxi(maior, t.size())
	var saida := PackedFloat32Array()
	saida.resize(maior)
	for t: PackedFloat32Array in trilhas:
		for i in t.size():
			saida[i] += t[i]
	return saida


## Normaliza para o pico e grava como WAV 16 bits mono.
func _salvar(nome: String, amostras: PackedFloat32Array) -> void:
	var maximo := 0.001
	for a in amostras:
		maximo = maxf(maximo, absf(a))
	var fator := PICO / maximo
	var dados := PackedByteArray()
	dados.resize(amostras.size() * 2)
	for i in amostras.size():
		dados.encode_s16(i * 2, int(clampf(amostras[i] * fator, -1.0, 1.0) * 32767.0))
	var onda := AudioStreamWAV.new()
	onda.format = AudioStreamWAV.FORMAT_16_BITS
	onda.mix_rate = TAXA
	onda.stereo = false
	onda.data = dados
	onda.save_to_wav(ProjectSettings.globalize_path(PASTA + nome + ".wav"))
