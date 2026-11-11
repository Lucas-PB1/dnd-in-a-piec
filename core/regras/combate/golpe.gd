class_name Golpe
extends RefCounted
## Um ataque de D&D pronto para ser resolvido: nome, bônus para acertar, dados de dano
## (já com o modificador) e tipo de dano. Quem ataca monta; quem é atingido resolve contra
## a própria CA e resistências.

## Emitido por um alvo com Forma Corrosiva quando esta arma o atinge e causa dano.
## Quem montou o golpe (o dono da arma) decide o que acontece com ela.
## Quem emite é o alvo, de fora desta classe; por isso o aviso de "sinal não usado" é desligado.
@warning_ignore("unused_signal")
signal arma_corroida(penalidade: int, limite: int)

## Emitido por quem resolve o golpe quando um efeito de talento foi gasto (os que valem uma vez por
## rodada). O dono do golpe começa a contar a recarga.
@warning_ignore("unused_signal")
signal efeito_usado(efeito: StringName)

## Emitido pelo alvo depois de resolver o golpe: o resultado e se o acerto derrubou o alvo (a 0 PV).
@warning_ignore("unused_signal")
signal resolvido(resultado: Combate.Resultado, abateu: bool)

var nome: String
## Somado ao d20 (proficiência + modificador, ou o "+3" da ficha da criatura).
var bonus_ataque: int
var dano: Dado
## Dado somado ao dano só quando o ataque tem vantagem (ex.: 1d4 do Goblin Warrior). Null = não tem.
var dano_extra: Dado
var tipo_dano: StringName
## True se é uma arma não mágica (sofre Corrosão). Soco e ataques naturais = false.
var arma_corroivel: bool
## Desvantagem: rola 2d20 e fica com o menor (ex.: armadura sem treinamento).
var desvantagem: bool = false
## Vantagem: rola 2d20 e fica com o maior. Com vantagem E desvantagem, as duas se anulam.
var vantagem: bool = false
## Menor d20 que conta como crítico se o ataque acertar (padrão 20; Campeão = 19).
var limiar_critico: int = 20
## O acerto corrói a armadura não mágica do alvo (Pseudópode do Gray Ooze).
var corroi_armadura: bool = false

## Quem atacou (instance_id), para condições como Atormentar (vantagem só contra quem marcou).
var autor_id: int = 0

## Maestria da arma (Proficiencias), se o atacante a domina; vazio = nenhuma.
var maestria: StringName = &""
## CD da salvaguarda da maestria (Derrubar): 8 + modificador do ataque + proficiência.
var cd_maestria: int = 0
## Raspão: dano quando ERRA (o modificador do ataque; 0 = não tem).
var dano_raspao: int = 0
## Trespassar: o 2º ataque, contra outra criatura perto da primeira (null = não tem).
var trespassar: Golpe
## Algum alvo foi acertado por este golpe (o Trespassar só vale depois de acertar o 1º).
var acertou_algum: bool = false

## Falso nos golpes que vêm de longe (flecha, adaga arremessada): o Duelista Defensivo só vale no corpo a corpo.
var corpo_a_corpo: bool = true
## Efeitos de talento e de item que o golpe leva (ver `EfeitoDeGolpe`). O dono do golpe monta a lista; o combate pergunta a ela.
var efeitos: Array[EfeitoDeGolpe] = []

## Salvaguarda no lugar de ataque (Borrifo Ácido): CD maior que 0 faz o alvo rolar a salvaguarda do atributo; passou, leva
## metade. Sem rolagem de acerto.
var cd_salvaguarda: int = 0
var atributo_salvaguarda: StringName = Atributos.DESTREZA


## O golpe leva o efeito com este id?
func tem(id_do_efeito: StringName) -> bool:
	return efeito(id_do_efeito) != null


## O efeito com este id, ou null.
func efeito(id_do_efeito: StringName) -> EfeitoDeGolpe:
	for candidato in efeitos:
		if candidato.id == id_do_efeito:
			return candidato
	return null


func rerrola_um() -> bool:
	return efeitos.any(func(e: EfeitoDeGolpe) -> bool: return e.rerrola_um())


func rerrola_menor() -> bool:
	return efeitos.any(func(e: EfeitoDeGolpe) -> bool: return e.rerrola_menor())


func trata_um_e_dois_como_tres() -> bool:
	return efeitos.any(func(e: EfeitoDeGolpe) -> bool: return e.trata_um_e_dois_como_tres())


func rola_duas_vezes() -> bool:
	return efeitos.any(func(e: EfeitoDeGolpe) -> bool: return e.rola_duas_vezes())

func _init(nome_golpe: String, bonus: int, dado_dano: Dado, tipo: StringName = TiposDano.CONTUNDENTE,
		corroivel: bool = false) -> void:
	nome = nome_golpe
	bonus_ataque = bonus
	dano = dado_dano
	tipo_dano = tipo
	arma_corroivel = corroivel
