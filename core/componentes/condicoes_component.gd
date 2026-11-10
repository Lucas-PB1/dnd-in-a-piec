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
## Sentinela: não tem ícone na arte (fica fora de ORDEM); o aviso na tela basta.
const IMOBILIZADO := &"imobilizado"
## Envenenador e Agarrador: também sem ícone na arte.
const ENVENENADO := &"envenenado"
const AGARRADO := &"agarrado"
## Ordem dos ícones na arte (assets/efeitos/condicoes.png) e na tela.
const ORDEM: Array[StringName] = [CAIDO, LENTO, ENFRAQUECIDO, ATORMENTADO]
const NOMES := {CAIDO: "Caído", LENTO: "Lento", ENFRAQUECIDO: "Enfraquecido", ATORMENTADO: "Atormentado", IMOBILIZADO: "Preso", ENVENENADO: "Envenenado", AGARRADO: "Agarrado"}

## Caído: fica deitado meia rodada (levantar gasta metade do deslocamento).
const DURACAO_CAIDO := EscalaDnd.RODADA_SEGUNDOS / 2.0
## As outras duram até o próximo turno de quem aplicou: 1 rodada.
const DURACAO_RODADA := EscalaDnd.RODADA_SEGUNDOS
## Lentidão: -10 pés de deslocamento (não acumula).
const REDUCAO_LENTIDAO_PES := 10.0
## Imobilizado: o deslocamento zera (a redução é maior que qualquer deslocamento).
const REDUCAO_IMOBILIZADO_PES := 1000.0
## Sentinela: quanto tempo o alvo acertado em movimento fica preso (s).
const DURACAO_IMOBILIZADO := 1.0
## Envenenado: dura até o fim do próximo turno de quem envenenou (1 rodada).
const DURACAO_ENVENENADO := EscalaDnd.RODADA_SEGUNDOS
## Agarrado: dura até escapar (ou o herói se afastar); o limite evita ficar preso para sempre.
const DURACAO_AGARRADO := 30.0
## O agarrado tenta escapar a cada rodada.
const INTERVALO_ESCAPE := EscalaDnd.RODADA_SEGUNDOS
## Quem agarra solta o alvo se ficar mais longe que isto (pés): o dobro do alcance do soco, de folga para o recuo.
const ALCANCE_DO_AGARRAO_PES := 10.0
## Quanto o corpo precisa andar por quadro (px) para contar como "se movendo".
const MOVIMENTO_MINIMO_PX := 0.2
## Empurrar: até 10 pés para longe de quem bateu.
const EMPURRAO_PES := 10.0
## Empurrar/Derrubar no alvo Enorme ou maior (PHB 2024).
const AVISO_GRANDE_DEMAIS := "Grande demais!"
## Tamanho de cada ícone na arte e espaço entre eles (px).
const TAMANHO_ICONE := 8
const ESPACO_ICONE := 1

## Bônus de salvaguarda da criatura por atributo (ex.: CON do Gray Ooze = +3).
@export var bonus_salvaguardas: Dictionary[StringName, int] = {}
## Ícones das condições, lado a lado na ordem de ORDEM.
@export var icones: Texture2D

## Gerador dos dados das salvaguardas (os testes podem fixar a semente).
var rng := RandomNumberGenerator.new()
## Condições a que o dono é imune (ex.: o Gray Ooze: Caído, Agarrado, Preso). Impor uma delas só avisa "Imune!".
var imunidades: Array[StringName] = []
## Tamanho D&D do dono (`CriaturaRPG.Tamanho`). Empurrar/Derrubar só até Grande.
var tamanho: int = CriaturaRPG.Tamanho.MEDIO

var _restante: Dictionary[StringName, float] = {}
## Quem atormentou (instance_id): só ele tem vantagem no próximo ataque.
var _atormentado_por: int = 0
## Onde o dono estava no quadro anterior e se ele andou: o Sentinela só prende quem está se movendo.
## Agarrado: quem agarrou (instance_id), a CD do teste de escape e quanto falta para a próxima tentativa.
var _agarrado_por: int = 0
var _cd_escape: int = 0
var _tempo_escape: float = 0.0
var _x_anterior: float = 0.0
var _se_move: bool = false


func _physics_process(delta: float) -> void:
	_se_move = absf(global_position.x - _x_anterior) > MOVIMENTO_MINIMO_PX
	_x_anterior = global_position.x
	_tentar_escapar(delta)
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


## O dono andou no último quadro?
func esta_se_movendo() -> bool:
	return _se_move


## Quanto o deslocamento cai agora (pés).
func reducao_deslocamento_pes() -> float:
	if tem(IMOBILIZADO) or tem(AGARRADO):
		return REDUCAO_IMOBILIZADO_PES
	return REDUCAO_LENTIDAO_PES if tem(LENTO) else 0.0


## Enfraquecer: o próximo ataque desta criatura tem desvantagem. Gasta a condição.
func consumir_desvantagem() -> bool:
	if tem(ENVENENADO):  # Envenenado: desvantagem em todos os ataques enquanto durar
		return true
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
	if tem(AGARRADO) and golpe.autor_id != 0 and golpe.autor_id == _agarrado_por:
		golpe.vantagem = true  # Agarrador: vantagem contra quem agarrou
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
			if _aceita_empurrar_ou_derrubar():
				_testar_derrubar(golpe.cd_maestria)
			else:
				aviso.emit(AVISO_GRANDE_DEMAIS)
		Proficiencias.EMPURRAR:
			if _aceita_empurrar_ou_derrubar():
				empurrado.emit(Vector2(lado * EscalaDnd.pes_para_pixels(EMPURRAO_PES), 0.0))
				aviso.emit("Empurrado!")
			else:
				aviso.emit(AVISO_GRANDE_DEMAIS)
		Proficiencias.ENFRAQUECER:
			_impor(ENFRAQUECIDO, DURACAO_RODADA)
		Proficiencias.LENTIDAO:
			if resultado.dano > 0:
				_impor(LENTO, DURACAO_RODADA)
		Proficiencias.ATORMENTAR:
			if resultado.dano > 0:
				_atormentado_por = golpe.autor_id
				_impor(ATORMENTADO, DURACAO_RODADA)
	for efeito in golpe.efeitos:  # talentos: empurrão, Lento, Preso, Agarrado...
		efeito.ao_acertar(golpe, resultado, self, lado)


## Empurra o dono `pes` pés para o `lado` (maestria Empurrar, talentos).
func empurrar(pes: float, lado: float) -> void:
	empurrado.emit(Vector2(lado * EscalaDnd.pes_para_pixels(pes), 0.0))
	aviso.emit("Empurrado!")


## Põe uma condição (renova se já tiver). Os efeitos de talento usam.
func impor(condicao: StringName, duracao: float) -> void:
	_impor(condicao, duracao)


## O dono passa na salvaguarda do `atributo` contra a `cd`?
func salvou(atributo: StringName, cd: int) -> bool:
	return Combate.passou_salvaguarda(bonus_salvaguardas.get(atributo, 0), cd, rng)


## Esmagador: o próximo ataque de quem acertou contra o dono tem vantagem.
func atormentar(autor_id: int) -> void:
	_atormentado_por = autor_id
	_impor(ATORMENTADO, DURACAO_RODADA)


## Envenenador: salvaguarda de Constituição contra a CD. Falhou: fica Envenenado e devolve o dano de veneno. Passou: 0.
func rolar_veneno(dano: Dado, cd: int) -> int:
	if ENVENENADO in imunidades:
		aviso.emit("Imune!")
		return 0
	if salvou(Atributos.CONSTITUICAO, cd):
		aviso.emit("Resistiu ao veneno!")
		return 0
	_impor(ENVENENADO, DURACAO_ENVENENADO)
	return dano.rolar(rng)


## Agarrador: o dono fica agarrado por `autor_id`; não anda e tenta escapar a cada rodada contra a `cd`.
func agarrar(autor_id: int, cd: int) -> void:
	if AGARRADO in imunidades:
		aviso.emit("Imune!")
		return
	_agarrado_por = autor_id
	_cd_escape = cd
	_tempo_escape = INTERVALO_ESCAPE
	_impor(AGARRADO, DURACAO_AGARRADO)




## Agarrado: a cada rodada rola Força ou Destreza (o melhor) contra a CD. Solta se passar ou se quem agarrou
## se afastou.
func _tentar_escapar(delta: float) -> void:
	if not tem(AGARRADO):
		return
	if _agarrador_longe():
		_remover(AGARRADO)
		return
	_tempo_escape -= delta
	if _tempo_escape > 0.0:
		return
	_tempo_escape = INTERVALO_ESCAPE
	var bonus: int = maxi(bonus_salvaguardas.get(Atributos.FORCA, 0), bonus_salvaguardas.get(Atributos.DESTREZA, 0))
	if Combate.passou_salvaguarda(bonus, _cd_escape, rng):
		_remover(AGARRADO)
		aviso.emit("Soltou-se!")


func _agarrador_longe() -> bool:
	var quem := instance_from_id(_agarrado_por) as Node2D
	if quem == null:
		return true
	return global_position.distance_to(quem.global_position) > EscalaDnd.pes_para_pixels(ALCANCE_DO_AGARRAO_PES)

# --- Interno --------------------------------------------------------------------

## Empurrar e Derrubar: o livro limita a Grande ou menor.
func _aceita_empurrar_ou_derrubar() -> bool:
	return tamanho <= CriaturaRPG.Tamanho.GRANDE


## Derrubar: a criatura SEMPRE rola salvaguarda de Constituição contra a CD; falhou = Caída.
func _testar_derrubar(cd: int) -> void:
	var bonus: int = bonus_salvaguardas.get(Atributos.CONSTITUICAO, 0)
	if Combate.passou_salvaguarda(bonus, cd, rng):
		aviso.emit("Salvou! (CD %d)" % cd)
	else:
		_impor(CAIDO, DURACAO_CAIDO)


func _impor(condicao: StringName, duracao: float) -> void:
	if condicao in imunidades:
		aviso.emit("Imune!")
		return
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
