class_name ArremessoDeCriatura
extends RefCounted
## Capacidade de arremesso da ficha (`arremessos`, alcances, `arma_arremesso`).
## O dono monta o `Golpe` e chama `arremessar`; a IA de quando arremessar fica na feature.

const CENA_PROJETIL := preload("res://core/projeteis/projetil_arremesso.tscn")

var _criatura: CriaturaRPG
## Quantas armas de arremesso ainda carrega.
var _restantes: int = 0


func _init(criatura: CriaturaRPG) -> void:
	_criatura = criatura
	_restantes = criatura.arremessos


## A ficha tem ataque de arremesso?
static func tem_arremesso(criatura: CriaturaRPG) -> bool:
	return criatura.arremessos > 0


func tem_arma() -> bool:
	return _restantes > 0


func restantes() -> int:
	return _restantes


## Dentro do alcance longo do arremesso da ficha.
func no_alcance_longo(distancia_px: float) -> bool:
	return distancia_px <= EscalaDnd.pes_para_pixels(_criatura.arremesso_longo_pes)


## True se tinha arma e gastou uma.
func consumir() -> bool:
	if _restantes <= 0:
		return false
	_restantes -= 1
	return true


## Gasta uma arma e solta o projétil. False se não tinha ou a ficha não tem `arma_arremesso`.
func arremessar(
	pai: Node,
	golpe: Golpe,
	origem: Vector2,
	destino: Vector2,
	gravidade: float,
) -> bool:
	if _criatura.arma_arremesso == null:
		push_warning("Criatura '%s': arremesso sem arma_arremesso na ficha." % _criatura.nome)
		return false
	if not consumir():
		return false
	var projetil: ProjetilArremesso = CENA_PROJETIL.instantiate()
	pai.add_child(projetil)
	projetil.lancar(
		golpe,
		_criatura.arma_arremesso,
		origem,
		destino,
		EscalaDnd.pes_para_pixels(_criatura.arremesso_normal_pes),
		EscalaDnd.pes_para_pixels(_criatura.arremesso_longo_pes),
		gravidade,
	)
	return true
