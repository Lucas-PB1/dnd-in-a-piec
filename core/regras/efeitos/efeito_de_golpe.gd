class_name EfeitoDeGolpe
extends RefCounted
## Um efeito de talento (ou de item) que um `Golpe` carrega. O golpe leva uma lista deles e cada ponto do combate
## pergunta a todos: ao rolar o dano, ao causar dano, ao acertar o alvo e no alvo (salvaguardas). Talento novo =
## uma classe nova que sobrescreve só o que usa; ninguém mais precisa mudar.

## Quem é (a recarga de "uma vez por rodada" e a procura no golpe usam este id).
var id: StringName = &""
## Vale uma vez por rodada: depois de gasto, o herói tira o efeito dos próximos golpes até a recarga acabar.
var por_rodada: bool = true


## Os dados de dano rolam de novo quando tiram 1 (Brigão de Taverna).
func rerrola_um() -> bool:
	return false


## Armas Grandes: faces 1–2 nos dados de dano viram 3.
func trata_um_e_dois_como_tres() -> bool:
	return false


## Rola o menor dado de novo e, no crítico, um dado a mais (Perfurador).
func rerrola_menor() -> bool:
	return false


## O dano é rolado duas vezes e fica o maior (Atacante Selvagem).
func rola_duas_vezes() -> bool:
	return false


## Dano a mais somado ao do acerto (Investida, Veneno Básico).
func dano_extra(_golpe: Golpe, _rng: RandomNumberGenerator, _critico: bool) -> int:
	return 0


## O dano do acerto está calculado: avisa que o efeito foi gasto, se for o caso.
func ao_causar_dano(_golpe: Golpe) -> void:
	pass


## O golpe acertou o `alvo`: aplica condições, empurrão e afins. `lado` = para onde empurrar (1 ou -1).
func ao_acertar(_golpe: Golpe, _resultado: Combate.Resultado, _alvo: CondicoesComponent, _lado: float) -> void:
	pass


## Dano que só o alvo sabe calcular, por causa da salvaguarda dele (Envenenador). Soma ao do acerto.
func dano_no_alvo(_golpe: Golpe, _resultado: Combate.Resultado, _alvo: CondicoesComponent) -> int:
	return 0
