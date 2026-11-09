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

## Talentos que mexem no golpe. O dono liga (e desliga enquanto o efeito recarrega).
## Atacante Selvagem: rola o dano duas vezes e fica o maior.
var selvagem: bool = false
## Brigão de Taverna: rerrola os dados de dano que tirarem 1.
var rerrolar_um: bool = false
## Brigão de Taverna: o acerto empurra o alvo isto (pés); 0 = não empurra.
var empurrao_pes: float = 0.0
## Qual talento deu o empurrão (para a recarga de uma vez por rodada).
var empurrao_efeito: StringName = &""
## Mestre em Arma Grande: arma Pesada; crítico ou abate dá um golpe extra.
var grande: bool = false
## Cortador: o acerto cortante aplica Lentidão; o crítico dá desvantagem ao próximo ataque do alvo.
var cortador: bool = false
## Perfurador: rerrola o menor dado de dano; o crítico rola um dado a mais.
var perfurador: bool = false
## Esmagador: o crítico dá vantagem ao próximo ataque contra o alvo (o empurrão usa `empurrao_pes`).
var esmagador: bool = false
## Mestre em Escudos: CD do teste de Força do alvo depois do acerto (0 = sem golpe de escudo) e se falhar derruba em vez de empurrar.
var escudo_cd: int = 0
var escudo_derruba: bool = false
## Sentinela: o acerto num alvo que está se movendo o deixa imóvel por um instante.
var sentinela: bool = false
## Investida: dado extra de dano do ataque em investida (null = não é uma investida de dano).
var investida_dano: Dado
## Falso nos golpes que vêm de longe (flecha, adaga arremessada): o Duelista Defensivo só vale no corpo a corpo.
var corpo_a_corpo: bool = true
## Veneno Básico: dado de dano de veneno extra (1d4) enquanto a arma está envenenada. Null = sem veneno.
var veneno_extra: Dado
## Envenenador: dano de veneno (2d8) e a CD da salvaguarda de Constituição do alvo; falhou, leva o dano e fica Envenenado.
var veneno_potente: Dado
var veneno_cd: int = 0
## Agarrador: o soco acertado também agarra o alvo (CD do teste de escape dele).
var agarra: bool = false
var agarra_cd: int = 0


func _init(nome_golpe: String, bonus: int, dado_dano: Dado, tipo: StringName = TiposDano.CONTUNDENTE,
		corroivel: bool = false) -> void:
	nome = nome_golpe
	bonus_ataque = bonus
	dano = dado_dano
	tipo_dano = tipo
	arma_corroivel = corroivel
