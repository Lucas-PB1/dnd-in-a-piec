class_name CriaturaRPG
extends Resource
## Bloco de estatísticas de uma criatura de D&D 5e (ex.: data/gray_ooze.tres).
## Distâncias em pés, como no livro (EscalaDnd converte para o jogo).

@export var nome: String = "Criatura"
## XP concedido ao derrotar esta criatura da cota da fase.
@export var experiencia: int = 0
## Ouro (em peças) que ela costuma soltar; o saque sorteia em volta disto e o Carisma do herói ajusta (Saque).
@export var ouro: int = 0
## Tamanho e tipo, só para mostrar (ex.: "Medium Ooze, Unaligned").
@export var tipo: String = ""
@export var classe_armadura: int = 10
## Dados de vida (ex.: "3d8+9"). A vida usada é a média, como no livro, se não rolar.
@export var dados_vida: String = "1d8"
## Rola os dados de vida em vez de usar a média.
@export var rolar_vida: bool = false
@export var atributos: Dictionary[StringName, int] = {}
## Salvaguardas em que a criatura soma a proficiência (o Gray Ooze não tem nenhuma).
@export var salvaguardas_proficientes: Array[StringName] = []
@export var bonus_proficiencia: int = 2
## Iniciativa da ficha (ex.: "Initiative -2"). Define o ritmo dos ataques (EscalaDnd).
@export var iniciativa: int = 0
## Deslocamento por rodada (pés).
@export var deslocamento_pes: float = 30.0
## Até onde percebe o alvo (pés). Gray Ooze: Visão às Cegas 60 pés.
@export var percepcao_pes: float = 60.0
## Tipos de dano a que resiste (metade do dano). Gray Ooze: ácido, frio e fogo.
@export var resistencias: Array[StringName] = []

@export_group("Forma Corrosiva")
## Penalidade no ataque que uma arma não mágica leva cada vez que causa dano nesta criatura.
## 0 = não tem Forma Corrosiva.
@export var corrosao_por_toque: int = 0
## A arma é destruída quando a penalidade chega a este valor.
@export var corrosao_limite: int = 5

@export_group("Ataque")
@export var ataque_nome: String = "Ataque"
## Bônus para acertar (o "+3" de "Melee Attack Roll: +3").
@export var ataque_bonus: int = 0
## Dano do acerto (ex.: "2d8+1").
@export var ataque_dano: String = "1d4"
## Tipo de dano do ataque (TiposDano, ex.: &"acido").
@export var ataque_tipo_dano: StringName = TiposDano.CONTUNDENTE
## Alcance (pés). "Reach 5 ft" = 1 ladrilho.
@export var ataque_alcance_pes: float = 5.0
## O acerto corrói a armadura não mágica do alvo (-1 na CA dela; Pseudópode do Gray Ooze).
@export var ataque_corroi_armadura: bool = false
## Dano a mais do acerto, de outro tipo (ex.: "3d4"). Vazio = não tem.
@export var ataque_dano_adicional: String = ""
## O acerto agarra o alvo; CD do escape. 0 = não agarra (Bugbear: 12).
@export var ataque_agarra_cd: int = 0

@export_group("Arremesso")
## Quantas armas de arremesso carrega (Goblin Minion: 3 adagas). 0 = não arremessa.
@export var arremessos: int = 0
## Alcance do arremesso (pés): além do normal, desvantagem; o longo é o limite.
@export var arremesso_normal_pes: float = 0.0
@export var arremesso_longo_pes: float = 0.0
## Arma que voa (só a arte; o golpe é o do ataque da ficha). Ex.: data/armas/adaga.tres.
@export var arma_arremesso: Arma
## Nome e dano do arremesso quando diferem do ataque corpo a corpo (Bugbear: Martelo Leve 3d4+2). Vazio = usa o ataque.
@export var arremesso_nome: String = ""
@export var arremesso_dano: String = ""
@export var arremesso_tipo_dano: StringName = TiposDano.CONTUNDENTE

@export_group("Disparo")
## Quantas flechas carrega. 0 = não dispara. Menor que 0 = não acaba (Goblin Warrior).
@export var disparos: int = 0
## Nome do tiro (ex.: "Arco Curto"). Vazio usa o nome do ataque corpo a corpo.
@export var disparo_nome: String = ""
## Alcance do tiro (pés): além do normal, desvantagem; o longo é o limite.
@export var disparo_normal_pes: float = 0.0
@export var disparo_longo_pes: float = 0.0
## Dano do tiro (ex.: "1d6+2"). Vazio usa o dano do ataque corpo a corpo.
@export var disparo_dano: String = ""
## Tipo de dano do tiro (TiposDano).
@export var disparo_tipo_dano: StringName = TiposDano.PERFURANTE
## Dano a mais do tiro, de outro tipo (Hobgoblin: "3d4" de veneno). Vazio = não tem.
@export var disparo_dano_adicional: String = ""

@export_group("Furtividade")
## Tem a perícia e começa escondido (rola contra a Percepção passiva do herói).
@export var tem_furtividade: bool = false
## Bônus de Furtividade já com o modificador (Goblin: +6).
@export var bonus_furtividade: int = 0
## Dado extra quando o ataque tem vantagem (Goblin Warrior: "1d4"). Vazio = não tem.
@export var dano_extra_com_vantagem: String = ""

@export_group("Comportamento")
## Tempo parado e brilhando antes do golpe ou do tiro (s): dá tempo de esquivar. Não vale
## para o primeiro golpe de uma emboscada (o herói não viu o monstro).
@export var aviso_ataque: float = 0.35
## Até onde patrulha a partir de onde começou (pés). 0 = espera parado.
@export var patrulha_pes: float = 0.0

@export_group("Ações bônus")
## Fuga Ágil (Goblin): Desengajar depois de atacar (salta para longe do alvo).
@export var fuga_agil: bool = false
## Depois do recuo, esconde de novo e rola Furtividade outra vez (Goblin Warrior).
@export var esconde_de_novo: bool = false

@export_group("Traços")
## Táticas de Matilha: vantagem no ataque se um aliado em pé está a 5 pés do alvo (Hobgoblin, Kobold).
@export var taticas_de_matilha: bool = false
## Sensibilidade à Luz Solar: ao sol, desvantagem nos ataques (Kobold). Só vale em fase de dia.
@export var sensivel_ao_sol: bool = false


func dado_vida() -> Dado:
	return _dado_ou_padrao(dados_vida)


func vida_maxima(rng: RandomNumberGenerator) -> int:
	var dado := dado_vida()
	return maxi(dado.rolar(rng) if rolar_vida else dado.media(), 1)


func modificador(atributo: StringName) -> int:
	return Atributos.modificador(atributos.get(atributo, Atributos.VALOR_MEDIO))


func bonus_salvaguarda(atributo: StringName) -> int:
	var extra := bonus_proficiencia if atributo in salvaguardas_proficientes else 0
	return modificador(atributo) + extra


## O ataque da criatura, pronto para ser resolvido contra a CA do alvo.
func golpe() -> Golpe:
	var ataque := Golpe.new(ataque_nome, ataque_bonus, _dado_ou_padrao(ataque_dano), ataque_tipo_dano)
	ataque.corroi_armadura = ataque_corroi_armadura
	_anexar_dano_extra(ataque)
	_anexar_dano_adicional(ataque, ataque_dano_adicional)
	if ataque_agarra_cd > 0:
		ataque.efeitos.append(EfeitosDeTalento.Agarrar.new(ataque_agarra_cd))
	return ataque


## O tiro (arco). O bônus para acertar é o do ataque corpo a corpo.
func golpe_disparo() -> Golpe:
	var nome_tiro := disparo_nome if not disparo_nome.is_empty() else ataque_nome
	var notacao := disparo_dano if not disparo_dano.is_empty() else ataque_dano
	var tiro := Golpe.new(nome_tiro, ataque_bonus, _dado_ou_padrao(notacao), disparo_tipo_dano)
	_anexar_dano_extra(tiro)
	_anexar_dano_adicional(tiro, disparo_dano_adicional)
	return tiro


## A arma arremessada. Sem dano próprio na ficha, vale o ataque corpo a corpo (a adaga do Minion e do Kobold).
func golpe_arremesso() -> Golpe:
	if arremesso_dano.is_empty():
		return golpe()
	var nome_arremesso := arremesso_nome if not arremesso_nome.is_empty() else ataque_nome
	var arremesso := Golpe.new(nome_arremesso, ataque_bonus, _dado_ou_padrao(arremesso_dano), arremesso_tipo_dano)
	_anexar_dano_extra(arremesso)
	return arremesso


func _anexar_dano_adicional(ataque: Golpe, notacao: String) -> void:
	if notacao.is_empty():
		return
	var dado := Dado.de_texto(notacao)
	if dado == null:
		push_warning("Criatura '%s': dano adicional '%s' inválido." % [nome, notacao])
		return
	ataque.efeitos.append(EfeitoDanoAdicional.new(dado))


func _anexar_dano_extra(ataque: Golpe) -> void:
	if dano_extra_com_vantagem.is_empty():
		return
	var extra := Dado.de_texto(dano_extra_com_vantagem)
	if extra == null:
		push_warning("Criatura '%s': dado extra '%s' inválido." % [nome, dano_extra_com_vantagem])
		return
	ataque.dano_extra = extra


func _dado_ou_padrao(notacao: String) -> Dado:
	var dado := Dado.de_texto(notacao)
	if dado == null:
		push_warning("Criatura '%s': dado '%s' inválido, usando 1d4." % [nome, notacao])
		return Dado.new(1, 4)
	return dado


## Dano médio de um golpe da ficha, somando o dano adicional (ex.: os 3d4 de veneno do arco do Hobgoblin).
func dano_medio(ataque: Golpe) -> float:
	var total := float(ataque.dano.media())
	var adicional := ataque.efeito(&"dano_adicional") as EfeitoDanoAdicional
	if adicional != null:
		total += adicional.dado.media()
	return total


## Dano médio do melhor ataque à distância (arco ou arremesso), 0 se a ficha não tem nenhum.
func dano_medio_a_distancia() -> float:
	var melhor := 0.0
	if disparos != 0:
		melhor = maxf(melhor, dano_medio(golpe_disparo()))
	if arremessos > 0:
		melhor = maxf(melhor, dano_medio(golpe_arremesso()))
	return melhor
