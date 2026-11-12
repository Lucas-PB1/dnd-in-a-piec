class_name MontagemDeGolpe
extends RefCounted
## Bônus do golpe do herói: estilos, Rajada, Investida e a marca de autor.
## Sem nó e sem sinal: o herói liga `resolvido` e a corrosão depois.


## Soma os estilos situacionais no golpe. Devolve true se a Selvageria acabou de ligar
## (a CA muda e o herói precisa redesenhar o equipamento).
static func aplicar_estilos(golpe: Golpe, arma: Arma, extra: bool, ficha: Ficha, estilos: EstilosDoHeroi, inimigo_perto: bool, inimigo_maior: bool) -> bool:
	if ficha == null:
		return false
	var bonus := 0
	var selvageria_ligou := false
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.SELVAGERIA) and not extra and not arma.disparavel() and not estilos.selvageria_ativa:
		bonus += ficha.bonus_proficiencia()
		estilos.ativar_selvageria()
		selvageria_ligou = true
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.ESCARAMUCADOR) and estilos.moveu_neste_turno:
		bonus += ficha.bonus_proficiencia()
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.OPORTUNISTA) and estilos.consumir_oportunista():
		golpe.bonus_ataque += Ficha.BONUS_OPORTUNISTA
		bonus += Ficha.BONUS_OPORTUNISTA
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.ARTILHEIRO) and arma.disparavel() and inimigo_perto:
		bonus += Ficha.BONUS_ARTILHEIRO_PERTO
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.COMBATENTE_MOVEL):
		estilos.ativar_movimento_extra()
	if ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.PELOS_PES) and inimigo_maior:
		golpe.vantagem = true
	if bonus != 0:
		golpe.dano = golpe.dano.com_bonus(bonus)
	return selvageria_ligou


## Rajada ligada troca a vantagem por um segundo alvo. Extra e disparo ficam de fora.
static func cabe_rajada(arma: Arma, extra: bool, ficha: Ficha, ligada: bool) -> bool:
	if extra or arma == null or arma.disparavel() or ficha == null or not ligada:
		return false
	return ficha.tem_efeito_estilo(EstiloDeLutaRPG.Efeito.RAJADA)


## Investida só no corpo a corpo, com a corrida pronta e a recarga livre.
static func cabe_investida(arma: Arma, ficha: Ficha, carregada: bool, em_recarga: bool) -> bool:
	if arma == null or arma.disparavel() or ficha == null or not carregada or em_recarga:
		return false
	return ficha.tem_talento(Ficha.TALENTO_INVESTIDA)


## Autor, crítico e a vantagem da Sorte. O 2º ataque do Trespassar herda os mesmos números.
static func assinar(golpe: Golpe, autor_id: int, ficha: Ficha, com_sorte: bool) -> void:
	golpe.autor_id = autor_id
	golpe.limiar_critico = ficha.limiar_critico() if ficha != null else Combate.ACERTO_CRITICO
	if com_sorte:
		golpe.vantagem = true
		if golpe.trespassar:
			golpe.trespassar.vantagem = true
	if golpe.trespassar == null:
		return
	golpe.trespassar.autor_id = golpe.autor_id
	golpe.trespassar.limiar_critico = golpe.limiar_critico


## Tira os efeitos de "uma vez por rodada" que ainda estão em recarga.
static func sem_os_em_recarga(efeitos: Array, recargas: RecargasPorRodada) -> Array[EfeitoDeGolpe]:
	var prontos: Array[EfeitoDeGolpe] = []
	for efeito in efeitos:
		var de_golpe := efeito as EfeitoDeGolpe
		if de_golpe != null and not (de_golpe.por_rodada and recargas.em_recarga(de_golpe.id)):
			prontos.append(de_golpe)
	return prontos
