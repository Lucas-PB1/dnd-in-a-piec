class_name GestoDeArma
extends RefCounted
## Qual gesto a arma da mão pede (disparo, arremesso ou nenhum) e os números da carga.
## Sem Input e sem nó: o herói lê o botão e aplica o resultado.


## A arma dispara (fica na mão e gasta munição).
static func e_disparo(arma: Arma) -> bool:
	return arma != null and arma.disparavel()


## A arma sai da mão (K). Disparo não conta: o tiro ficou no botão de atacar.
static func e_arremesso(arma: Arma) -> bool:
	return arma != null and arma.arremessavel() and not arma.disparavel()


## Dá para carregar e soltar (disparo ou arremesso).
static func sai_no_gesto(arma: Arma) -> bool:
	return e_disparo(arma) or e_arremesso(arma)


## Teto da força (0 a 1). No disparo, a Destreza limita; no arremesso, chega em 1.
static func teto(disparo: bool, ficha: Ficha) -> float:
	if not disparo or ficha == null:
		return 1.0
	return ficha.teto_da_carga()


## Segundos até o teto. Sem disparo, o tempo cheio do livro; com disparo, a Destreza encolhe.
static func tempo_ate_o_teto(disparo: bool, ficha: Ficha) -> float:
	if not disparo or ficha == null:
		return Ficha.TEMPO_CARGA_DISPARO
	return ficha.tempo_ate_teto_da_carga()


static func tem_municao(inventario: Inventario, arma: Arma) -> bool:
	if inventario == null or arma == null:
		return false
	var pilha := inventario.item_chamado(arma.municao)
	return pilha != null and inventario.quantidade_de(pilha) > 0


## O tiro perto de um inimigo não leva desvantagem (Artilheiro, Atirador de Elite ou besta do Especialista).
static func ignora_inimigo_perto(ficha: Ficha, arma: Arma) -> bool:
	if ficha == null or arma == null:
		return false
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.ARTILHEIRO):
		return true
	if ficha.tem_talento(Ficha.TALENTO_ATIRADOR_DE_ELITE):
		return true
	return arma.besta and ficha.tem_talento(Ficha.TALENTO_ESPECIALISTA_EM_BESTA)
