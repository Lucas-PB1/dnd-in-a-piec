class_name CriaturaRPG
extends Resource
## Bloco de estatísticas de uma criatura de D&D 5e (ex.: data/gray_ooze.tres).
## Distâncias em pés, como no livro (EscalaDnd converte para o jogo).

@export var nome: String = "Criatura"
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

@export_group("Arremesso")
## Quantas armas de arremesso carrega (Goblin Minion: 3 adagas). 0 = não arremessa.
@export var arremessos: int = 0
## Alcance do arremesso (pés): além do normal, desvantagem; o longo é o limite.
@export var arremesso_normal_pes: float = 0.0
@export var arremesso_longo_pes: float = 0.0
## Arma que voa (só a arte; o golpe é o do ataque da ficha). Ex.: data/armas/adaga.tres.
@export var arma_arremesso: Arma

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

@export_group("Furtividade")
## Tem a perícia e começa escondido (rola contra a Percepção passiva do herói).
@export var tem_furtividade: bool = false
## Bônus de Furtividade já com o modificador (Goblin: +6).
@export var bonus_furtividade: int = 0
## Dado extra quando o ataque tem vantagem (Goblin Warrior: "1d4"). Vazio = não tem.
@export var dano_extra_com_vantagem: String = ""

@export_group("Ações bônus")
## Fuga Ágil (Goblin): Desengajar depois de atacar (salta para longe do alvo).
@export var fuga_agil: bool = false


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
	return ataque


## O tiro (arco). O bônus para acertar é o do ataque corpo a corpo.
func golpe_disparo() -> Golpe:
	var nome_tiro := disparo_nome if not disparo_nome.is_empty() else ataque_nome
	var notacao := disparo_dano if not disparo_dano.is_empty() else ataque_dano
	var tiro := Golpe.new(nome_tiro, ataque_bonus, _dado_ou_padrao(notacao), disparo_tipo_dano)
	_anexar_dano_extra(tiro)
	return tiro


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
