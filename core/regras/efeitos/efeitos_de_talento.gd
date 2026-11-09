class_name EfeitosDeTalento
extends RefCounted
## Os efeitos que os talentos põem no golpe (um por classe interna, cada um pequeno). `Ficha.golpe_com`, o herói e
## o item Veneno Básico escolhem quais entram. Ver `EfeitoDeGolpe` para o que cada ponto do combate pergunta.


## Atacante Selvagem: uma vez por rodada, rola o dano duas vezes e fica o maior.
class AtacanteSelvagem extends EfeitoDeGolpe:
	func _init() -> void:
		id = Proficiencias.EFEITO_SELVAGEM

	func rola_duas_vezes() -> bool:
		return true

	func ao_causar_dano(golpe: Golpe) -> void:
		golpe.efeito_usado.emit(id)


## Brigão de Taverna, o dado: o soco rerrola os dados que tirarem 1 (sem recarga).
class BrigaoRerrola extends EfeitoDeGolpe:
	func _init() -> void:
		id = &"brigao_rerrola"
		por_rodada = false

	func rerrola_um() -> bool:
		return true


## Brigão de Taverna, o empurrão: o soco acertado empurra 5 pés, uma vez por rodada.
class BrigaoEmpurra extends EfeitoDeGolpe:
	const EMPURRAO_PES := 5.0

	func _init() -> void:
		id = Proficiencias.EFEITO_BRIGAO

	func ao_acertar(golpe: Golpe, _resultado: Combate.Resultado, alvo: CondicoesComponent, lado: float) -> void:
		alvo.empurrar(EMPURRAO_PES, lado)
		golpe.efeito_usado.emit(id)


## Mestre em Armas Grandes: só a marca; crítico ou abate dá um golpe extra, e quem trata isso é o herói.
class MestreArmasGrandes extends EfeitoDeGolpe:
	func _init() -> void:
		id = Proficiencias.EFEITO_ARMA_GRANDE


## Retalhador: o acerto cortante deixa o alvo Lento; o crítico dá desvantagem ao próximo ataque dele.
class Retalhador extends EfeitoDeGolpe:
	func _init() -> void:
		id = Proficiencias.EFEITO_CORTADOR

	func ao_acertar(golpe: Golpe, resultado: Combate.Resultado, alvo: CondicoesComponent, _lado: float) -> void:
		if resultado.dano <= 0:
			return
		alvo.impor(CondicoesComponent.LENTO, CondicoesComponent.DURACAO_RODADA)
		if resultado.critico:
			alvo.impor(CondicoesComponent.ENFRAQUECIDO, CondicoesComponent.DURACAO_RODADA)
		golpe.efeito_usado.emit(id)


## Perfurador: rerrola o menor dado de dano e, no crítico, rola um dado a mais.
class Perfurador extends EfeitoDeGolpe:
	func _init() -> void:
		id = Proficiencias.EFEITO_PERFURADOR

	func rerrola_menor() -> bool:
		return true

	func ao_causar_dano(golpe: Golpe) -> void:
		golpe.efeito_usado.emit(id)


## Esmagador, o empurrão: o acerto contundente empurra 5 pés, uma vez por rodada.
class EsmagadorEmpurra extends EfeitoDeGolpe:
	const EMPURRAO_PES := 5.0

	func _init() -> void:
		id = Proficiencias.EFEITO_ESMAGADOR

	func ao_acertar(golpe: Golpe, _resultado: Combate.Resultado, alvo: CondicoesComponent, lado: float) -> void:
		alvo.empurrar(EMPURRAO_PES, lado)
		golpe.efeito_usado.emit(id)


## Esmagador, o crítico: o próximo ataque contra o alvo tem vantagem (sem recarga).
class EsmagadorCritico extends EfeitoDeGolpe:
	func _init() -> void:
		id = &"esmagador_critico"
		por_rodada = false

	func ao_acertar(golpe: Golpe, resultado: Combate.Resultado, alvo: CondicoesComponent, _lado: float) -> void:
		if resultado.critico:
			alvo.atormentar(golpe.autor_id)


## Mestre em Escudos: depois do acerto o alvo faz salvaguarda de Força; falhou, é empurrado ou derrubado.
class GolpeDeEscudo extends EfeitoDeGolpe:
	const EMPURRAO_PES := 5.0

	## CD do teste de Força do alvo.
	var cd: int
	## Falhou: derruba (senão empurra). O herói alterna a cada uso.
	var derruba: bool = false

	func _init(cd_do_teste: int) -> void:
		id = Proficiencias.EFEITO_ESCUDO
		cd = cd_do_teste

	func ao_acertar(golpe: Golpe, _resultado: Combate.Resultado, alvo: CondicoesComponent, lado: float) -> void:
		golpe.efeito_usado.emit(id)
		if alvo.salvou(Atributos.FORCA, cd):
			alvo.aviso.emit("Resistiu ao escudo!")
		elif derruba:
			alvo.impor(CondicoesComponent.CAIDO, CondicoesComponent.DURACAO_CAIDO)
		else:
			alvo.empurrar(EMPURRAO_PES, lado)


## Sentinela: acertar um alvo que está se movendo o deixa preso por um instante (sem recarga).
class Sentinela extends EfeitoDeGolpe:
	func _init() -> void:
		id = &"sentinela"
		por_rodada = false

	func ao_acertar(_golpe: Golpe, resultado: Combate.Resultado, alvo: CondicoesComponent, _lado: float) -> void:
		if resultado.dano > 0 and alvo.esta_se_movendo():
			alvo.impor(CondicoesComponent.IMOBILIZADO, CondicoesComponent.DURACAO_IMOBILIZADO)


## Agarrador: o soco acertado agarra o alvo, que tenta escapar a cada rodada contra a CD.
class Agarrar extends EfeitoDeGolpe:
	var cd: int

	func _init(cd_do_escape: int) -> void:
		id = Proficiencias.EFEITO_AGARRAR
		cd = cd_do_escape

	func ao_acertar(golpe: Golpe, _resultado: Combate.Resultado, alvo: CondicoesComponent, _lado: float) -> void:
		alvo.agarrar(golpe.autor_id, cd)
		golpe.efeito_usado.emit(id)


## Investida: depois de correr 10 pés, o golpe soma 1d8 de dano ou empurra 10 pés, conforme o modo.
class Investida extends EfeitoDeGolpe:
	const EMPURRAO_PES := 10.0
	const FACES_DANO := 8

	var empurra: bool

	func _init(modo_empurrao: bool) -> void:
		id = Proficiencias.EFEITO_INVESTIDA
		empurra = modo_empurrao

	func dano_extra(_golpe: Golpe, rng: RandomNumberGenerator, critico: bool) -> int:
		return 0 if empurra else Dado.new(1, FACES_DANO).rolar(rng, critico)

	func ao_causar_dano(golpe: Golpe) -> void:
		if not empurra:
			golpe.efeito_usado.emit(id)

	func ao_acertar(golpe: Golpe, _resultado: Combate.Resultado, alvo: CondicoesComponent, lado: float) -> void:
		if empurra:
			alvo.empurrar(EMPURRAO_PES, lado)
			golpe.efeito_usado.emit(id)


## Veneno Básico: +1d4 de dano de veneno enquanto a arma está envenenada; o acerto gasta o veneno (sem recarga).
class VenenoBasico extends EfeitoDeGolpe:
	func _init() -> void:
		id = Proficiencias.EFEITO_VENENO
		por_rodada = false

	func dano_extra(_golpe: Golpe, rng: RandomNumberGenerator, critico: bool) -> int:
		return Dado.new(1, Ficha.FACES_VENENO_BASICO).rolar(rng, critico)

	func ao_causar_dano(golpe: Golpe) -> void:
		golpe.efeito_usado.emit(id)


## Envenenador: o alvo faz salvaguarda de Constituição; falhou, leva 2d8 de veneno e fica Envenenado.
class VenenoPotente extends EfeitoDeGolpe:
	var cd: int

	func _init(cd_da_salvaguarda: int) -> void:
		id = Proficiencias.EFEITO_VENENO
		por_rodada = false
		cd = cd_da_salvaguarda

	func ao_causar_dano(golpe: Golpe) -> void:
		golpe.efeito_usado.emit(id)  # o acerto gasta a dose da arma

	func dano_no_alvo(_golpe: Golpe, _resultado: Combate.Resultado, alvo: CondicoesComponent) -> int:
		return alvo.rolar_veneno(Dado.new(Ficha.DADOS_VENENO_POTENTE, Ficha.FACES_VENENO_POTENTE), cd)
