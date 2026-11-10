class_name MontagemDeCriatura
extends RefCounted
## Kit básico das criaturas: aplica a ficha nos componentes, prepara condições/empurrão e
## calcula o deslocamento com Lentidão. Cada feature chama isto no `_ready` / ao andar;
## capacidades da ficha (arremesso, disparo, sol…) e a encenação específica ficam fora.

## Texto flutuante quando a Fortitude dos Mortos-Vivos salva.
const TEXTO_FORTITUDE := "Fortitude!"


## Vida, CA, resistências, imunidades, vulnerabilidades, fortitude e tamanho a partir da ficha.
## Se `texto` vier e a ficha tiver fortitude, liga o aviso "Fortitude!".
static func aplicar_ficha(
	criatura: CriaturaRPG,
	vida: HealthComponent,
	defesa: DefesaComponent,
	condicoes: CondicoesComponent,
	rng: RandomNumberGenerator,
	texto: TextoFlutuanteComponent = null,
) -> void:
	vida.configurar(criatura.vida_maxima(rng))
	defesa.classe_armadura = criatura.classe_armadura
	defesa.resistencias = criatura.resistencias
	defesa.imunidades = criatura.imunidades_dano
	defesa.vulnerabilidades = criatura.vulnerabilidades
	defesa.fortitude_morto_vivo = criatura.fortitude_morto_vivo
	condicoes.imunidades = criatura.imunidades_condicoes
	condicoes.tamanho = criatura.tamanho
	if texto != null and criatura.fortitude_morto_vivo:
		defesa.fortitude_usada.connect(
			func() -> void: texto.mostrar(TEXTO_FORTITUDE, TextoFlutuanteComponent.COR_CONDICAO)
		)


## Salvaguardas da ficha + avisos flutuantes + empurrão (`ao_empurrar` recebe o Vector2 do sinal).
static func preparar_condicoes(
	criatura: CriaturaRPG,
	condicoes: CondicoesComponent,
	texto: TextoFlutuanteComponent,
	ao_empurrar: Callable,
) -> void:
	for atributo in Atributos.TODOS:
		condicoes.bonus_salvaguardas[atributo] = criatura.bonus_salvaguarda(atributo)
	condicoes.aviso.connect(
		func(mensagem: String) -> void: texto.mostrar(mensagem, TextoFlutuanteComponent.COR_CONDICAO)
	)
	condicoes.empurrado.connect(ao_empurrar)


## Sinais padrão do kit: golpe resolvido, morte e fim do dissolver.
static func ligar_sinais_padrao(
	defesa: DefesaComponent,
	vida: HealthComponent,
	dissolver: DissolverComponent,
	ao_golpe: Callable,
	ao_morrer: Callable,
	ao_dissolver: Callable,
) -> void:
	defesa.golpe_resolvido.connect(ao_golpe)
	vida.morreu.connect(ao_morrer)
	dissolver.terminou.connect(ao_dissolver)


## Saltador com a Força da ficha.
static func criar_saltador(
	corpo: CharacterBody2D,
	criatura: CriaturaRPG,
	gravidade: float,
) -> SaltadorDeMonstro:
	var forca := criatura.atributos.get(Atributos.FORCA, Atributos.VALOR_MEDIO) as int
	return SaltadorDeMonstro.new(corpo, forca, gravidade)


## Deslocamento em pés por rodada já com Lentidão / Agarrado / Imobilizado.
static func deslocamento_efetivo_pes(criatura: CriaturaRPG, condicoes: CondicoesComponent) -> float:
	return maxf(criatura.deslocamento_pes - condicoes.reducao_deslocamento_pes(), 0.0)


## Velocidade de andar (px/s) com o deslocamento efetivo.
static func velocidade_andar(criatura: CriaturaRPG, condicoes: CondicoesComponent) -> float:
	return EscalaDnd.deslocamento_para_velocidade(deslocamento_efetivo_pes(criatura, condicoes))


## Desliza o empurrão no corpo e devolve quanto ainda falta (px, com sinal).
static func aplicar_empurrao(
	corpo: CharacterBody2D,
	restante: float,
	velocidade_px_s: float,
	delta: float,
) -> float:
	if is_zero_approx(restante):
		return restante
	var passo := signf(restante) * minf(absf(restante), velocidade_px_s * delta)
	corpo.velocity.x = passo / delta
	return restante - passo
