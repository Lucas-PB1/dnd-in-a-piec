class_name OpcoesSom
extends RefCounted
## Volumes do jogo (música, efeitos e interface), gravados em user://som.cfg. Cada um é uma
## fração de 0 a 1 e vira o volume de um barramento de áudio. A main chama carregar() e
## preparar_barramentos() no começo; quem muda chama salvar() e aplicar(). Não é autoload.

const SECAO := "som"
const MUSICA := &"Musica"
const EFEITOS := &"Efeitos"
const INTERFACE := &"Interface"
## Os três barramentos que o jogo usa, além do Master.
const BARRAMENTOS: Array[StringName] = [MUSICA, EFEITOS, INTERFACE]
const VOLUME_MUSICA_PADRAO := 0.55
const VOLUME_EFEITOS_PADRAO := 0.9
const VOLUME_INTERFACE_PADRAO := 0.8
## Abaixo disto o barramento fica mudo (evita o -infinito do dB).
const VOLUME_MINIMO := 0.001

## Onde as opções ficam gravadas. Os testes trocam por outro arquivo, para não mexer na configuração de verdade.
static var caminho: String = "user://som.cfg"
static var volume_musica: float = VOLUME_MUSICA_PADRAO
static var volume_efeitos: float = VOLUME_EFEITOS_PADRAO
static var volume_interface: float = VOLUME_INTERFACE_PADRAO


static func carregar() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(caminho) != OK:
		return
	volume_musica = clampf(float(arquivo.get_value(SECAO, "musica", volume_musica)), 0.0, 1.0)
	volume_efeitos = clampf(float(arquivo.get_value(SECAO, "efeitos", volume_efeitos)), 0.0, 1.0)
	volume_interface = clampf(float(arquivo.get_value(SECAO, "interface", volume_interface)), 0.0, 1.0)


static func salvar() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value(SECAO, "musica", volume_musica)
	arquivo.set_value(SECAO, "efeitos", volume_efeitos)
	arquivo.set_value(SECAO, "interface", volume_interface)
	arquivo.save(caminho)


## Cria os barramentos que faltam (todos saem no Master) e põe cada volume nele.
static func preparar_barramentos() -> void:
	for nome in BARRAMENTOS:
		if AudioServer.get_bus_index(nome) < 0:
			AudioServer.add_bus()
			var indice := AudioServer.bus_count - 1
			AudioServer.set_bus_name(indice, nome)
			AudioServer.set_bus_send(indice, &"Master")
	aplicar()


static func aplicar() -> void:
	_aplicar_em(MUSICA, volume_musica)
	_aplicar_em(EFEITOS, volume_efeitos)
	_aplicar_em(INTERFACE, volume_interface)


## Volume (0 a 1) de um barramento pelo nome.
static func volume_de(barramento: StringName) -> float:
	match barramento:
		MUSICA:
			return volume_musica
		EFEITOS:
			return volume_efeitos
	return volume_interface


static func definir(barramento: StringName, volume: float) -> void:
	volume = clampf(volume, 0.0, 1.0)
	match barramento:
		MUSICA:
			volume_musica = volume
		EFEITOS:
			volume_efeitos = volume
		_:
			volume_interface = volume
	aplicar()


static func _aplicar_em(barramento: StringName, volume: float) -> void:
	var indice := AudioServer.get_bus_index(barramento)
	if indice < 0:
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(volume, VOLUME_MINIMO)))
	AudioServer.set_bus_mute(indice, volume <= VOLUME_MINIMO)
