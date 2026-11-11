class_name Loja
extends RefCounted
## A loja do início da fase: o que ela vende, quanto custa e a compra e a venda em si. Regra pura.
## Preço = o do livro (GP/SP/CP) em peças de ouro; a venda paga metade.
## Desconto: Artesão 20% + 2% por ponto de Persuasão (teto 50%).

enum Resultado { OK, SEM_OURO, MOCHILA_CHEIA, ITEM_INVALIDO }

## Preço de quem não tem preço no livro (munição, itens do jogo).
const PRECO_PADRAO := 5
## A venda paga esta fração do preço de compra.
const FRACAO_DA_VENDA := 0.5
## Desconto do talento Artesão na compra.
const DESCONTO_ARTESAO := 0.2
## Cada ponto do bônus de Persuasão (só positivo) tira esta fração do preço.
const DESCONTO_POR_PONTO_PERSUASAO := 0.02
## Teto do desconto total (Artesão + Persuasão).
const DESCONTO_MAXIMO := 0.5
## Quanto o bônus mágico soma ao preço da arma (+1, +2, +3).
const EXTRA_POR_BONUS_MAGICO := {1: 60, 2: 240, 3: 960}
## Na fase 1 só aparece o que custa até isto; o teto dobra a cada fase (as caras ficam para o fim).
const TETO_DE_PRECO_NA_FASE_1 := 25
## Quantos itens a loja põe à venda por visita, e a chance de uma arma dela vir mágica.
const TAMANHO_DO_ESTOQUE := 7
const CHANCE_ARMA_MAGICA := 0.25
const PASTAS_DO_ESTOQUE: Array[String] = ["res://data/armas", "res://data/armaduras", "res://data/municoes", "res://data/itens"]
## Valor em peças de cada moeda do livro (GP = 1).
const VALOR_DA_MOEDA := {"GP": 1.0, "SP": 0.1, "CP": 0.01}


## Preço cheio do item, em peças de ouro (mínimo 1).
static func preco(item: Item) -> int:
	var base := _preco_do_livro(item)
	if item is Arma:
		base += EXTRA_POR_BONUS_MAGICO.get((item as Arma).bonus_magico, 0)
	return maxi(base, 1)


## Fração de desconto na compra (0 a DESCONTO_MAXIMO): Artesão + Persuasão.
static func desconto_de_compra(ficha: Ficha) -> float:
	if ficha == null:
		return 0.0
	var desconto := DESCONTO_ARTESAO if ficha.tem_talento(Ficha.TALENTO_ARTESAO) else 0.0
	desconto += DESCONTO_POR_PONTO_PERSUASAO * maxi(ficha.bonus_pericia(Pericia.PERSUASAO), 0)
	return minf(desconto, DESCONTO_MAXIMO)


## Quanto o herói paga: preço cheio menos Artesão e Persuasão.
static func preco_de_compra(item: Item, ficha: Ficha) -> int:
	return maxi(roundi(preco(item) * (1.0 - desconto_de_compra(ficha))), 1)


## Quanto a loja paga pelo item (uma pilha inteira de munição paga por todas as unidades).
static func preco_de_venda(item: Item, inventario: Inventario = null) -> int:
	var unidade := maxi(roundi(preco(item) * FRACAO_DA_VENDA), 1)
	return unidade * (inventario.quantidade_de(item) if inventario != null else 1)


## O estoque da fase: itens sorteados do arsenal que custam até o teto da fase; algumas armas vêm mágicas.
static func sortear_estoque(indice_fase: int, rng: RandomNumberGenerator) -> Array[Item]:
	var teto := TETO_DE_PRECO_NA_FASE_1 * (1 << clampi(indice_fase - 1, 0, 10))
	var candidatos: Array[Item] = []
	for pasta in PASTAS_DO_ESTOQUE:
		for recurso in Recursos.da_pasta(pasta):
			if recurso is Item and preco(recurso) <= teto:
				candidatos.append(recurso)
	var estoque: Array[Item] = []
	while estoque.size() < TAMANHO_DO_ESTOQUE and not candidatos.is_empty():
		var sorteado := candidatos.pop_at(rng.randi_range(0, candidatos.size() - 1)) as Item
		estoque.append(_copia_para_a_venda(sorteado, rng, indice_fase))
	return estoque


## Compra o item: tira o ouro e põe uma cópia na mochila. A tela tira do estoque (menos a munição, que não acaba).
static func comprar(item: Item, ficha: Ficha, inventario: Inventario) -> Resultado:
	if item == null or ficha == null or inventario == null:
		return Resultado.ITEM_INVALIDO
	var custo := preco_de_compra(item, ficha)
	if ficha.ouro < custo:
		return Resultado.SEM_OURO
	if not inventario.adicionar(item.duplicate() as Item):
		return Resultado.MOCHILA_CHEIA
	ficha.ouro -= custo
	return Resultado.OK


## Vende o item da mochila (equipado também: sai da mão ou do corpo) e recebe o ouro.
static func vender(item: Item, ficha: Ficha, inventario: Inventario) -> Resultado:
	if item == null or ficha == null or inventario == null or item not in inventario.itens:
		return Resultado.ITEM_INVALIDO
	var ganho := preco_de_venda(item, inventario)
	inventario.descartar(item)
	ficha.ouro += ganho
	return Resultado.OK


## O item fica na loja depois de comprado? Só a munição e o que empilha (dá para comprar de novo).
static func fica_no_estoque(item: Item) -> bool:
	return item != null and item.empilhavel


static func _preco_do_livro(item: Item) -> int:
	var texto := str(item.get("preco")) if item.get("preco") != null else ""
	var achou := _regex_do_preco().search(texto.replace(",", ""))
	if achou == null:
		return PRECO_PADRAO
	return ceili(achou.get_string(1).to_float() * VALOR_DA_MOEDA[achou.get_string(2).to_upper()])


static func _regex_do_preco() -> RegEx:
	var regex := RegEx.new()
	regex.compile("([\\d.]+)\\s*(GP|SP|CP)")
	return regex


## O bônus mágico máximo da loja sobe com a fase (+1 até a 3, +2 até a 6, +3 depois).
static func _copia_para_a_venda(item: Item, rng: RandomNumberGenerator, indice_fase: int) -> Item:
	if item is Arma and not item.empilhavel and rng.randf() < CHANCE_ARMA_MAGICA:
		var maximo := clampi(ceili(indice_fase / 3.0), 1, Arma.BONUS_MAGICO_MAXIMO)
		return (item as Arma).com_bonus_magico(rng.randi_range(1, maximo))
	return item.duplicate() as Item
