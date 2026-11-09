class_name Ficha
extends RefCounted
## Ficha de personagem de D&D: identidade, progressão e contas de combate. Regra pura.

## Dano mínimo de um acerto (com modificador negativo o total poderia dar 0).
const DANO_MINIMO := Combate.DANO_MINIMO
## Bônus de proficiência nos níveis 1 a 3.
const BONUS_PROFICIENCIA := 2
## Nível que libera as habilidades de segundo nível do Guerreiro.
const NIVEL_HABILIDADES_GUERREIRO := 2
## Limite de nível desta campanha.
const NIVEL_MAXIMO := 4
## XP total necessário para cada nível desta fatia (tabela do livro).
const XP_POR_NIVEL := {1: 0, 2: 300, 3: 900, 4: 2700}
## No nível 4 o Guerreiro escolhe um talento geral (ou o Aumento de Valor de Habilidade).
const NIVEL_TALENTO_GERAL := 4
## Teto de um atributo.
const ATRIBUTO_MAXIMO := 20
## Base da CD das maestrias (8 + modificador + proficiência).
const CD_BASE_MAESTRIA := 8
## CA de quem não usa armadura (antes do modificador de Destreza).
const CA_BASE := 10
## Deslocamento por rodada (pés). Ainda não há raças: todo mundo é "humano" (30 pés).
const DESLOCAMENTO_PADRAO_PES := 30.0
## Armadura com Força mínima que o personagem não alcança: perde isto de deslocamento.
const PERDA_DESLOCAMENTO_SEM_FORCA := 10.0
## Arma Pesada com Força abaixo disto: desvantagem no ataque.
const FORCA_MINIMA_ARMA_PESADA := 13
## Vida mínima no nível 1, mesmo com Constituição muito baixa.
const VIDA_MINIMA := 1
## Nome usado quando nenhum foi escolhido.
const NOME_PADRAO := "Aventureiro"
## Tamanho máximo do nome do personagem (letras).
const TAMANHO_MAXIMO_NOME := 16

var nome: String
var classe: ClasseRPG
var nivel: int = 1
var experiencia: int = 0
var atributos: Dictionary[StringName, int] = {}
## Maestria em Armas: nomes dos tipos de arma que o personagem domina (Guerreiro: 3,
## escolhidos na criação). Só com elas a maestria da arma vale.
var armas_dominadas: Array[String] = []
## Ids dos talentos (origem e geral; `TalentoRPG.id`). O nome de tela vem do `TalentoRPG`, assim trocar um nome não quebra o save.
var talentos: Array[StringName] = []
## Quantas escolhas de talento por nível o jogador já fez (a do nível 4 é a primeira).
var escolhas_de_talento_feitas: int = 0
## Id do antecedente escolhido na criação (vazio = nenhum).
var antecedente: StringName = &""
## Salvaguardas em que o herói ficou proficiente por talento (Resiliente), além das da classe.
var salvaguardas_extras: Array[StringName] = []
## Perícias treinadas (ids de Pericia), escolhidas na criação. Sem treino, o teste usa só o modificador.
var pericias: Array[StringName] = []
## Perícias com Especialização (Observador, Especialista em Perícia): a proficiência conta em dobro.
var pericias_especializadas: Array[StringName] = []

## Destreza da ficha sugerida: o teto da carga e o tempo de voo do disparo são os dela.
const DESTREZA_REFERENCIA := 14
## Segundos para essa Destreza encher a carga até o teto dela.
const TEMPO_CARGA_DISPARO := 0.6
## Força da carga (0 = mínima, 1 = cheia) com modificador de Destreza −1.
const FORCA_MINIMA_DA_CARGA := 0.2
## Modificador a partir do qual segurar o K chega na força cheia.
const MOD_CARGA_CHEIA := 2
## Tiro longo sem a desvantagem de distância.
const TALENTO_ATIRADOR_DE_ELITE := &"atirador_de_elite"
## Besta: sem a desvantagem de atirar colado no inimigo; a Besta de Mão dispara de novo
## na ação bônus.
const TALENTO_ESPECIALISTA_EM_BESTA := &"especialista_em_besta"
## Talentos de origem (vêm do antecedente).
const TALENTO_ALERTA := &"alerta"
const TALENTO_RESISTENTE := &"resistente"
const TALENTO_ATACANTE_SELVAGEM := &"atacante_selvagem"
const TALENTO_BRIGAO := &"brigao_de_taverna"
const TALENTO_SORTUDO := &"sortudo"
const TALENTO_ARTESAO := &"artesao"
const TALENTO_PERITO := &"perito"

## Talentos gerais do nível 4.
const TALENTO_RESILIENTE := &"resiliente"
const TALENTO_VELOZ := &"veloz"
const TALENTO_MESTRE_ARMADURA_MEDIA := &"mestre_armadura_media"
const TALENTO_MESTRE_ARMA_GRANDE := &"mestre_arma_grande"
const TALENTO_MESTRE_ARMADURA_PESADA := &"mestre_armadura_pesada"
const TALENTO_CORTADOR := &"cortador"
const TALENTO_PERFURADOR := &"perfurador"
const TALENTO_ESMAGADOR := &"esmagador"
const TALENTO_EMPUNHADURA_DUPLA := &"empunhadura_dupla"
const TALENTO_MESTRE_ESCUDOS := &"mestre_escudo"
const TALENTO_OBSERVADOR := &"observador"
const TALENTO_SENTINELA := &"sentinela"
const TALENTO_MESTRE_ARMAS_DE_HASTE := &"mestre_arma_haste"
const TALENTO_DUELISTA_DEFENSIVO := &"duelista_defensivo"
const TALENTO_INVESTIDA := &"investida"
const TALENTO_ATLETA := &"atleta"
const TALENTO_AGARRADOR := &"agarrador"
const TALENTO_DURAVEL := &"duravel"
const TALENTO_ENVENENADOR := &"envenenador"
## Envenenador: dose potente (2d8) e as doses por fase (a proficiência). Veneno Básico: +1d4.
const FACES_VENENO_POTENTE := 8
const DADOS_VENENO_POTENTE := 2
const FACES_VENENO_BASICO := 4
## Atleta: deslocamento extra (pés).
const ATLETA_PES := 5.0
## Armas que o Mestre em Armas de Haste usa para o golpe com a outra ponta (além das Pesadas com Alcance).
const ARMAS_DE_HASTE: Array[String] = ["Bordão", "Lança"]
const TALENTO_ESPECIALISTA_EM_PERICIA := &"especialista_em_pericia"
## As perícias que o Observador deixa escolher.
const PERICIAS_DO_OBSERVADOR: Array[StringName] = [Pericia.INTUICAO, Pericia.INVESTIGACAO, Pericia.PERCEPCAO]
## Veloz: deslocamento extra (pés).
const VELOZ_PES := 10.0
## Mestre em Armadura Média: o teto de Destreza da armadura média passa a isto.
const TETO_DESTREZA_MESTRE_MEDIA := 3
## Resistente: vida máxima extra por nível.
const VIDA_POR_NIVEL_RESISTENTE := 2
## Brigão de Taverna: o soco passa a ser 1d4 e empurra isto (pés).
const FACES_SOCO_BRIGAO := 4
const EMPURRAO_BRIGAO_PES := 5.0
## Esmagador: o acerto contundente empurra isto (pés).
const EMPURRAO_ESMAGADOR_PES := 5.0


func _init(classe_rpg: ClasseRPG, valores: Dictionary, nome_personagem: String = NOME_PADRAO) -> void:
	classe = classe_rpg
	nome = limpar_nome(nome_personagem)
	if nome.is_empty():
		nome = NOME_PADRAO
	for atributo in Atributos.TODOS:
		atributos[atributo] = valores.get(atributo, Atributos.VALOR_MEDIO)


## Tira espaços das pontas e corta no tamanho máximo.
static func limpar_nome(texto: String) -> String:
	return texto.strip_edges().left(TAMANHO_MAXIMO_NOME)


## Um nome serve se, depois de limpo, sobrar pelo menos uma letra.
static func nome_valido(texto: String) -> bool:
	return not limpar_nome(texto).is_empty()


func modificador(atributo: StringName) -> int:
	return Atributos.modificador(atributos[atributo])


## Define o nível inicial escolhido na criação e o XP correspondente ao marco oficial.
func definir_nivel_inicial(novo_nivel: int) -> void:
	nivel = clampi(novo_nivel, 1, NIVEL_MAXIMO)
	experiencia = XP_POR_NIVEL[nivel]


## Soma XP e devolve quantos níveis ganhou, até o limite da campanha.
func adicionar_experiencia(quantidade: int) -> int:
	if quantidade <= 0:
		return 0
	var nivel_anterior := nivel
	experiencia += quantidade
	while nivel < NIVEL_MAXIMO and experiencia >= XP_POR_NIVEL[nivel + 1]:
		nivel += 1
	return nivel - nivel_anterior


## XP necessário para o próximo nível; 0 quando chegou ao limite.
func xp_proximo_nivel() -> int:
	if nivel >= NIVEL_MAXIMO:
		return 0
	return XP_POR_NIVEL[nivel + 1]


## PV no nível 1 usa o máximo do dado. Cada nível seguinte usa o valor fixo médio do livro.
func vida_maxima() -> int:
	var constituicao := modificador(Atributos.CONSTITUICAO)
	var vida_inicial := maxi(classe.dado_vida + constituicao, VIDA_MINIMA)
	var media_dado := floori(float(classe.dado_vida) / 2.0) + 1
	var vida_por_nivel := maxi(media_dado + constituicao, VIDA_MINIMA)
	return vida_inicial + (nivel - 1) * vida_por_nivel + _vida_do_resistente()


func _vida_do_resistente() -> int:
	return VIDA_POR_NIVEL_RESISTENTE * nivel if tem_talento(TALENTO_RESISTENTE) else 0


## Atributo do ataque e do dano. À distância usa Destreza. Acuidade usa o maior entre
## Força e Destreza. As outras usam Força.
func atributo_do_ataque(arma: Arma) -> StringName:
	if arma.disparavel():
		return Atributos.DESTREZA
	if arma.acuidade and modificador(Atributos.DESTREZA) > modificador(Atributos.FORCA):
		return Atributos.DESTREZA
	return Atributos.FORCA


## Modificador somado ao ataque e ao dano.
func bonus_dano(arma: Arma) -> int:
	return modificador(atributo_do_ataque(arma))


func tem_talento(talento: StringName) -> bool:
	return talento in talentos


## Escolhas de talento geral que o nível já liberou e o jogador ainda não fez.
func escolhas_de_talento_pendentes() -> int:
	var liberadas := 1 if nivel >= NIVEL_TALENTO_GERAL else 0
	return maxi(liberadas - escolhas_de_talento_feitas, 0)


## Este atributo pode receber o +1 do talento? Está na lista dele, abaixo do teto e, no Robusto de salvaguarda
## (Resiliente), sem proficiência na salvaguarda. Só a tela usa, para apagar os botões que não servem.
func atributo_serve_ao_talento(talento: TalentoRPG, atributo: StringName) -> bool:
	if atributo not in talento.atributos or atributos[atributo] >= ATRIBUTO_MAXIMO:
		return false
	return not (talento.id == TALENTO_RESILIENTE and proficiente_em_salvaguarda(atributo))

## Esse talento pode ser escolhido agora com estes aumentos de atributo? Precisa haver escolha
## pendente, o talento ser geral e liberado, não repetido (salvo os repetíveis), e os aumentos
## serem os pontos do talento, em atributos que ele permite e sem passar do teto.
func pode_escolher_talento(talento: TalentoRPG, aumentos: Array[StringName], escolhas_de_pericia: Array[StringName] = []) -> bool:
	if escolhas_de_talento_pendentes() <= 0 or not talento.escolhivel():
		return false
	if tem_talento(talento.id) and not talento.repetivel:
		return false
	if aumentos.size() != talento.pontos_de_atributo:
		return false
	if talento.id == TALENTO_RESILIENTE and proficiente_em_salvaguarda(aumentos[0]):
		return false  # Resiliente só vale num atributo sem proficiência na salvaguarda
	if not _pericias_servem(talento, escolhas_de_pericia):
		return false
	var somados: Dictionary[StringName, int] = {}
	for atributo in aumentos:
		if atributo not in talento.atributos:
			return false
		somados[atributo] = somados.get(atributo, 0) + 1
	for atributo in somados:
		if atributos[atributo] + somados[atributo] > ATRIBUTO_MAXIMO:
			return false
	return true


## As escolhas de perícia servem a este talento? Observador: 1 entre Intuição, Investigação e Percepção.
## Especialista em Perícia: [uma perícia nova, uma perícia (já treinada ou a nova) para a Especialização].
## Os outros talentos não escolhem perícia.
func _pericias_servem(talento: TalentoRPG, escolhas: Array[StringName]) -> bool:
	match talento.id:
		TALENTO_OBSERVADOR:
			return escolhas.size() == 1 and escolhas[0] in PERICIAS_DO_OBSERVADOR
		TALENTO_ESPECIALISTA_EM_PERICIA:
			if escolhas.size() != 2 or not Pericia.ATRIBUTO.has(escolhas[0]) or proficiente_na_pericia(escolhas[0]):
				return false
			var treinada := proficiente_na_pericia(escolhas[1]) or escolhas[1] == escolhas[0]
			return treinada and escolhas[1] not in pericias_especializadas
	return escolhas.is_empty()


func _aplicar_pericias_do_talento(talento: TalentoRPG, escolhas: Array[StringName]) -> void:
	match talento.id:
		TALENTO_OBSERVADOR:
			if proficiente_na_pericia(escolhas[0]):
				pericias_especializadas.append(escolhas[0])  # já treinada: ganha Especialização
			else:
				pericias.append(escolhas[0])
		TALENTO_ESPECIALISTA_EM_PERICIA:
			pericias.append(escolhas[0])
			pericias_especializadas.append(escolhas[1])

## Escolhe o talento do nível: guarda o nome e soma os aumentos de atributo. false se não pode.
func escolher_talento(talento: TalentoRPG, aumentos: Array[StringName], escolhas_de_pericia: Array[StringName] = []) -> bool:
	if not pode_escolher_talento(talento, aumentos, escolhas_de_pericia):
		return false
	talentos.append(talento.id)
	if talento.id == TALENTO_RESILIENTE:
		salvaguardas_extras.append(aumentos[0])
	_aplicar_pericias_do_talento(talento, escolhas_de_pericia)
	for atributo in aumentos:
		atributos[atributo] += 1
	escolhas_de_talento_feitas += 1
	return true


## Dados de dano da arma já com o modificador (ex.: espada curta + 2 = "1d6+2").
## `duas_maos` = empunhando com as duas mãos (arma Versátil usa o dado maior).
## `ataque_extra` = 2º golpe de arma leve: não soma modificador positivo.
func dado_dano(arma: Arma, duas_maos: bool = false, ataque_extra: bool = false) -> Dado:
	if _e_soco_do_brigao(arma):
		return Dado.new(1, FACES_SOCO_BRIGAO).com_bonus(_bonus_no_dano(arma, ataque_extra))
	return arma.dado(duas_maos).com_bonus(_bonus_no_dano(arma, ataque_extra))


## O ataque desarmado (sem categoria) de quem tem o Brigão de Taverna.
func _e_soco_do_brigao(arma: Arma) -> bool:
	return arma.categoria == &"" and tem_talento(TALENTO_BRIGAO)


## Rola o dano de um acerto com a arma (mínimo DANO_MINIMO). Crítico rola os dados em dobro.
func rolar_dano(arma: Arma, rng: RandomNumberGenerator, critico: bool = false, duas_maos: bool = false) -> int:
	return maxi(dado_dano(arma, duas_maos).rolar(rng, critico), DANO_MINIMO)


## Texto do dano para a ficha, ex.: "1d6+2". Dano fixo (dado de 1 face, como o soco) vira o total: "3".
func texto_dano(arma: Arma, duas_maos: bool = false, ataque_extra: bool = false) -> String:
	var dado := dado_dano(arma, duas_maos, ataque_extra)
	if dado.faces == 1:
		return str(maxi(dado.minimo(), DANO_MINIMO))
	return dado.texto()


## Proficiente com a arma? Ataque desarmado (sem categoria) sempre é.
func proficiente_com(arma: Arma) -> bool:
	return arma.categoria == &"" or arma.categoria in classe.proficiencias_armas


## Bônus para acertar: o mesmo modificador do dano + proficiência, se for proficiente com
## a arma (sem proficiência a arma ainda funciona, só não soma o +2).
func bonus_ataque(arma: Arma) -> int:
	var proficiencia := BONUS_PROFICIENCIA if proficiente_com(arma) else 0
	return proficiencia + bonus_dano(arma)


## O ataque com a arma, pronto para ser resolvido contra a CA do alvo.
## `penalidade` = desgaste da arma (ex.: Corrosão), subtraído do bônus de ataque.
## `armadura` vestida: sem treinamento nela, o ataque (teste de FOR/DES) tem desvantagem.
## Arma Pesada com FOR < 13 também dá desvantagem. `duas_maos`: Versátil com as duas mãos.
## `ataque_extra`: 2º golpe de arma leve (o d20 soma o modificador; o dano, não).
func golpe_com(arma: Arma, penalidade: int = 0, armadura: Armadura = null, duas_maos: bool = false,
		ataque_extra: bool = false) -> Golpe:
	var dado := dado_dano(arma, duas_maos, ataque_extra)
	var golpe := Golpe.new(arma.nome, bonus_ataque(arma) - penalidade, dado, arma.tipo_dano, arma.corroivel)
	golpe.desvantagem = desvantagem_por_armadura(armadura) or fraco_para(arma)
	golpe.maestria = maestria_de(arma)
	golpe.cd_maestria = cd_maestria(arma)
	golpe.selvagem = tem_talento(TALENTO_ATACANTE_SELVAGEM)
	golpe.sentinela = tem_talento(TALENTO_SENTINELA)
	if arma.categoria == &"" and tem_talento(TALENTO_AGARRADOR):  # o soco desarmado também agarra
		golpe.agarra = true
		golpe.agarra_cd = cd_agarrar()
	if _e_soco_do_brigao(arma):
		golpe.rerrolar_um = true
		golpe.empurrao_pes = EMPURRAO_BRIGAO_PES
		golpe.empurrao_efeito = Proficiencias.EFEITO_BRIGAO
	golpe.grande = tem_talento(TALENTO_MESTRE_ARMA_GRANDE) and not arma.disparavel()  # o golpe extra vale com qualquer arma corpo a corpo
	golpe.cortador = tem_talento(TALENTO_CORTADOR) and arma.tipo_dano == TiposDano.CORTANTE
	golpe.perfurador = tem_talento(TALENTO_PERFURADOR) and arma.tipo_dano == TiposDano.PERFURANTE
	if tem_talento(TALENTO_ESMAGADOR) and arma.tipo_dano == TiposDano.CONTUNDENTE:
		golpe.esmagador = true
		if golpe.empurrao_pes == 0.0:
			golpe.empurrao_pes = EMPURRAO_ESMAGADOR_PES
			golpe.empurrao_efeito = Proficiencias.EFEITO_ESMAGADOR
	if golpe.maestria == Proficiencias.RASPAO:
		golpe.dano_raspao = maxi(bonus_dano(arma), 0)
	if golpe.maestria == Proficiencias.TRESPASSAR and not ataque_extra:
		# 2º alvo: mesmo ataque, mas o dano não soma o modificador positivo (como o ataque extra).
		golpe.trespassar = golpe_com(arma, penalidade, armadura, duas_maos, true)
	return golpe


## CD do teste de escape do agarrado (Agarrador): 8 + Força + proficiência.
func cd_agarrar() -> int:
	return CD_BASE_MAESTRIA + modificador(Atributos.FORCA) + BONUS_PROFICIENCIA


## CD da salvaguarda de Constituição do Envenenador: 8 + o melhor entre Destreza e Inteligência + proficiência.
func cd_veneno() -> int:
	return CD_BASE_MAESTRIA + maxi(modificador(Atributos.DESTREZA), modificador(Atributos.INTELIGENCIA)) + BONUS_PROFICIENCIA


## Doses de veneno potente por fase: a proficiência. Zero sem o Envenenador.
func doses_de_veneno() -> int:
	return BONUS_PROFICIENCIA if tem_talento(TALENTO_ENVENENADOR) else 0


## Dados de vida: um por nível (o Durável deixa gastá-los para curar).
func dados_de_vida() -> int:
	return nivel if tem_talento(TALENTO_DURAVEL) else 0

## A arma serve ao Golpe com a Haste (Mestre em Armas de Haste): Bordão, Lança ou arma Pesada com Alcance.
func e_arma_de_haste(arma: Arma) -> bool:
	if arma == null or arma.disparavel():
		return false
	return arma.nome in ARMAS_DE_HASTE or (arma.pesada and arma.alcance_estendido)

## CD do teste de Força do alvo no golpe de escudo (Mestre em Escudos): 8 + Força + proficiência.
func cd_golpe_de_escudo() -> int:
	return CD_BASE_MAESTRIA + modificador(Atributos.FORCA) + BONUS_PROFICIENCIA

## Domina este tipo de arma (Maestria em Armas)? Só vale se a arma tem maestria.
func domina(arma: Arma) -> bool:
	return arma.maestria != &"" and arma.nome in armas_dominadas


## A maestria que vale com esta arma (vazio = não domina).
func maestria_de(arma: Arma) -> StringName:
	return arma.maestria if domina(arma) else &""


## CD da salvaguarda das maestrias (Derrubar): 8 + modificador do ataque + proficiência.
func cd_maestria(arma: Arma) -> int:
	return CD_BASE_MAESTRIA + bonus_dano(arma) + BONUS_PROFICIENCIA


## Arma Pesada pede FOR 13: abaixo disso, o ataque tem desvantagem.
func fraco_para(arma: Arma) -> bool:
	return arma.pesada and atributos[Atributos.FORCA] < FORCA_MINIMA_ARMA_PESADA


## Iniciativa = modificador de Destreza (+ a proficiência com o Alerta). Define o ritmo dos ataques (EscalaDnd).
func iniciativa() -> int:
	var bonus := BONUS_PROFICIENCIA if tem_talento(TALENTO_ALERTA) else 0
	return modificador(Atributos.DESTREZA) + bonus


## Até onde o disparo enche (0 = toque, velocidade mínima; 1 = velocidade cheia da arma).
## Destreza 14 ou mais chega em 1.
func teto_da_carga() -> float:
	var fracao := clampf(float(modificador(Atributos.DESTREZA) + 1) / float(MOD_CARGA_CHEIA + 1), 0.0, 1.0)
	return lerpf(FORCA_MINIMA_DA_CARGA, 1.0, fracao)


## Segundos para chegar nesse teto. Destreza alta enche a dela mais rápido.
func tempo_ate_teto_da_carga() -> float:
	var des := maxi(atributos[Atributos.DESTREZA], 1)
	return TEMPO_CARGA_DISPARO * float(DESTREZA_REFERENCIA) / float(des)


## Deslocamento (pés). Armadura com Força mínima que o personagem não tem: -10 pés.
func deslocamento_pes(armadura: Armadura = null) -> float:
	var base := DESLOCAMENTO_PADRAO_PES + (VELOZ_PES if tem_talento(TALENTO_VELOZ) else 0.0)
	base += ATLETA_PES if tem_talento(TALENTO_ATLETA) else 0.0
	if falta_forca_para(armadura):
		return base - PERDA_DESLOCAMENTO_SEM_FORCA
	return base


# --- Armadura ------------------------------------------------------------------------

## Classe de Armadura com a `armadura` e o `escudo` vestidos (null = sem eles).
## Sem armadura: 10 + DES. Leve: base + DES. Média: base + DES até o máximo. Pesada: base.
## `desgaste_armadura` (ex.: corrosão) é subtraído do que a armadura oferece.
## Escudo só soma se tiver treinamento com escudos.
func classe_armadura(armadura: Armadura = null, escudo: Armadura = null, desgaste_armadura: int = 0) -> int:
	var ca := CA_BASE + modificador(Atributos.DESTREZA)
	if armadura:
		ca = armadura.ca_base - desgaste_armadura + _destreza_na_armadura(armadura)
	if escudo and treinado_com(escudo):
		ca += escudo.ca_base
	return ca


## Treinado na categoria da armadura ou escudo? (Guerreiro: em todas.)
func treinado_com(armadura: Armadura) -> bool:
	return armadura.categoria in classe.treinamento_armaduras


## Vestir armadura (não escudo) sem treinamento dá desvantagem nos testes de FOR e DES.
func desvantagem_por_armadura(armadura: Armadura) -> bool:
	return armadura != null and not armadura.e_escudo() and not treinado_com(armadura)


## A armadura pede mais Força do que o personagem tem?
func falta_forca_para(armadura: Armadura) -> bool:
	return armadura != null and atributos[Atributos.FORCA] < armadura.forca_minima


## Ataque extra de arma leve: modificador positivo não entra no dano.
func _bonus_no_dano(arma: Arma, ataque_extra: bool) -> int:
	var bonus := bonus_dano(arma)
	if arma.pesada and tem_talento(TALENTO_MESTRE_ARMA_GRANDE):
		bonus += BONUS_PROFICIENCIA  # Mestre em Arma Grande: a proficiência soma ao dano
	return mini(bonus, 0) if ataque_extra else bonus


func _destreza_na_armadura(armadura: Armadura) -> int:
	if not armadura.soma_destreza:
		return 0
	var mod := modificador(Atributos.DESTREZA)
	return mini(mod, _teto_de_destreza(armadura)) if armadura.max_destreza >= 0 else mod


## O teto de Destreza da armadura; o Mestre em Armadura Média sobe o da média para +3.
func _teto_de_destreza(armadura: Armadura) -> int:
	var mestre := tem_talento(TALENTO_MESTRE_ARMADURA_MEDIA) and armadura.categoria == Proficiencias.ARMADURA_MEDIA
	return maxi(armadura.max_destreza, TETO_DESTREZA_MESTRE_MEDIA) if mestre else armadura.max_destreza


func proficiente_em_salvaguarda(atributo: StringName) -> bool:
	return atributo in classe.salvaguardas_proficientes or atributo in salvaguardas_extras


## Bônus da salvaguarda: modificador + proficiência (se a classe for proficiente nela).
func bonus_salvaguarda(atributo: StringName) -> int:
	var extra := BONUS_PROFICIENCIA if proficiente_em_salvaguarda(atributo) else 0
	return modificador(atributo) + extra


## Treinou esta perícia na criação?
func proficiente_na_pericia(pericia: StringName) -> bool:
	return pericia in pericias


## Bônus do teste: modificador do atributo da perícia, + proficiência se foi escolhida.
func bonus_pericia(pericia: StringName) -> int:
	var atributo := Pericia.atributo_de(pericia)
	if atributo == &"":
		return 0
	var extra := BONUS_PROFICIENCIA if proficiente_na_pericia(pericia) else 0
	if pericia in pericias_especializadas:
		extra += BONUS_PROFICIENCIA
	return modificador(atributo) + extra


## Percepção passiva: 10 + Sabedoria, + proficiência se Percepção foi escolhida.
func percepcao_passiva() -> int:
	return Pericia.passiva(bonus_pericia(Pericia.PERCEPCAO))
