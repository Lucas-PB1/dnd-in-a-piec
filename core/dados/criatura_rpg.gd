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
## Deslocamento por rodada (pés).
@export var deslocamento_pes: float = 30.0
## Até onde percebe o alvo (pés). Gray Ooze: Visão às Cegas 60 pés.
@export var percepcao_pes: float = 60.0

@export_group("Ataque")
@export var ataque_nome: String = "Ataque"
## Bônus para acertar (o "+3" de "Melee Attack Roll: +3").
@export var ataque_bonus: int = 0
## Dano do acerto (ex.: "2d8+1").
@export var ataque_dano: String = "1d4"
## Tipo de dano, só para mostrar por enquanto (ex.: "ácido").
@export var ataque_tipo_dano: String = ""
## Alcance (pés). "Reach 5 ft" = 1 ladrilho.
@export var ataque_alcance_pes: float = 5.0


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
	return Golpe.new(ataque_nome, ataque_bonus, _dado_ou_padrao(ataque_dano))


func _dado_ou_padrao(notacao: String) -> Dado:
	var dado := Dado.de_texto(notacao)
	if dado == null:
		push_warning("Criatura '%s': dado '%s' inválido, usando 1d4." % [nome, notacao])
		return Dado.new(1, 4)
	return dado
