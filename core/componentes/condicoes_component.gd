class_name CondicoesComponent
extends Node2D
## Condições de D&D que as maestrias de arma aplicam numa criatura, com duração em segundos
## ("até o seu próximo turno" = 1 rodada = EscalaDnd.RODADA_SEGUNDOS). Desenha um ícone por
## condição acima do dono. O DefesaComponent chama preparar_golpe_recebido() antes de
## resolver um golpe e aplicar_maestria() depois; o dono lê o estado (esta_caido,
## reducao_deslocamento_pes, consumir_desvantagem) e escuta `aviso` e `empurrado`.

## Texto para o dono mostrar (ex.: "Caído!", "Salvou! (CON 14)").
signal aviso(texto: String)
## Empurrar (maestria): o dono se desloca isto (px; x positivo = para a direita).
signal empurrado(deslocamento: Vector2)

const CAIDO := &"caido"
const LENTO := &"lento"
const ENFRAQUECIDO := &"enfraquecido"
const ATORMENTADO := &"atormentado"
## Ordem dos ícones na arte (assets/efeitos/condicoes.png) e na tela.
const ORDEM: Array[StringName] = [CAIDO, LENTO, ENFRAQUECIDO, ATORMENTADO]
const NOMES := {CAIDO: "Caído", LENTO: "Lento", ENFRAQUECIDO: "Enfraquecido", ATORMENTADO: "Atormentado"}

## Caído: fica deitado meia rodada (levantar gasta metade do deslocamento).
const DURACAO_CAIDO := EscalaDnd.RODADA_SEGUNDOS / 2.0
## As outras duram até o próximo turno de quem aplicou: 1 rodada.
const DURACAO_RODADA := EscalaDnd.RODADA_SEGUNDOS
## Lentidão: -10 pés de deslocamento (não acumula).
const REDUCAO_LENTIDAO_PES := 10.0
## Empurrar: até 10 pés para longe de quem bateu.
const EMPURRAO_PES := 10.0
## Tamanho de cada ícone na arte e espaço entre eles (px).
const TAMANHO_ICONE := 8
const ESPACO_ICONE := 1

## Bônus de salvaguarda da criatura por atributo (ex.: CON do Gray Ooze = +3).
@export var bonus_salvaguardas: Dictionary[StringName, int] = {}
## Ícones das condições, lado a lado na ordem de ORDEM.
@export var icones: Texture2D

## Gerador dos dados das salvaguardas (os testes podem fixar a semente).
var rng := RandomNumberGenerator.new()

var _restante: Dictionary[StringName, float] = {}
## Quem atormentou (instance_id): só ele tem vantagem no próximo ataque.
var _atormentado_por: int = 0


func _physics_process(delta: float) -> void:
	if _restante.is_empty():
		return
	for condicao in _restante.keys():
		_restante[condicao] -= delta
		if _restante[condicao] <= 0.0:
			_remover(condicao)


# --- Consultas do dono ------------------------------------------------------------

func tem(condicao: StringName) -> bool:
	return _restante.has(condicao)


func esta_caido() -> bool:
	return tem(CAIDO)


## Quanto o deslocamento cai agora (pés).
func reducao_deslocamento_pes() -> float:
	return REDUCAO_LENTIDAO_PES if tem(LENTO) else 0.0


## Enfraquecer: o próximo ataque desta criatura tem desvantagem. Gasta a condição.
func consumir_desvantagem() -> bool:
	if not tem(ENFRAQUECIDO):
		return false
	_remover(ENFRAQUECIDO)
	return true


# --- Chamado pelo DefesaComponent ----------------------------------------------

## Antes de resolver: ataque contra criatura Caída tem vantagem; Atormentar dá vantagem no
## próximo ataque de quem marcou (e se gasta).
func preparar_golpe_recebido(golpe: Golpe) -> void:
	if esta_caido():
		golpe.vantagem = true
	if tem(ATORMENTADO) and golpe.autor_id != 0 and golpe.autor_id == _atormentado_por:
		golpe.vantagem = true
		_remover(ATORMENTADO)


## Depois de resolver: aplica a maestria do golpe. `lado` = para onde empurrar (1 ou -1).
func aplicar_maestria(resultado: Combate.Resultado, lado: float) -> void:
	var golpe := resultado.golpe
	if not resultado.acertou:
		return
	match golpe.maestria:
		Proficiencias.DERRUBAR:
			_testar_derrubar(golpe.cd_maestria)
		Proficiencias.EMPURRAR:
			empurrado.emit(Vector2(lado * EscalaDnd.pes_para_pixels(EMPURRAO_PES), 0.0))
			aviso.emit("Empurrado!")
		Proficiencias.ENFRAQUECER:
			_impor(ENFRAQUECIDO, DURACAO_RODADA)
		Proficiencias.LENTIDAO:
			if resultado.dano > 0:
				_impor(LENTO, DURACAO_RODADA)
		Proficiencias.ATORMENTAR:
			if resultado.dano > 0:
				_atormentado_por = golpe.autor_id
				_impor(ATORMENTADO, DURACAO_RODADA)


# --- Interno --------------------------------------------------------------------

## Derrubar: a criatura SEMPRE rola salvaguarda de Constituição contra a CD; falhou = Caída.
func _testar_derrubar(cd: int) -> void:
	var bonus: int = bonus_salvaguardas.get(Atributos.CONSTITUICAO, 0)
	if Combate.passou_salvaguarda(bonus, cd, rng):
		aviso.emit("Salvou! (CD %d)" % cd)
	else:
		_impor(CAIDO, DURACAO_CAIDO)


func _impor(condicao: StringName, duracao: float) -> void:
	var nova := not tem(condicao)
	_restante[condicao] = maxf(_restante.get(condicao, 0.0), duracao)  # não acumula: renova
	if nova:
		aviso.emit("%s!" % NOMES[condicao])
		queue_redraw()


func _remover(condicao: StringName) -> void:
	_restante.erase(condicao)
	queue_redraw()


## Um ícone por condição ativa, centralizados acima do dono.
func _draw() -> void:
	if icones == null:
		return
	var ativas := ORDEM.filter(func(c: StringName) -> bool: return tem(c))
	var largura := ativas.size() * (TAMANHO_ICONE + ESPACO_ICONE) - ESPACO_ICONE
	for i in ativas.size():
		var origem := Rect2(ORDEM.find(ativas[i]) * TAMANHO_ICONE, 0, TAMANHO_ICONE, TAMANHO_ICONE)
		var destino := Rect2(-largura / 2.0 + i * (TAMANHO_ICONE + ESPACO_ICONE), 0, TAMANHO_ICONE, TAMANHO_ICONE)
		draw_texture_rect_region(icones, destino, origem)
