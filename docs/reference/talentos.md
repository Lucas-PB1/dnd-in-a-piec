# Talentos e antecedentes (decisões vivas)

O que entra no jogo, o que espera e os efeitos confirmados.
Catálogo com texto/ícone: `tools/gerar_compendio.gd` e `data/talentos/`.
Pendências de magia/espécies: `docs/backlog/`.

## Origem — ligados
Alerta, Robusto (Resistente), Atacante Selvagem, Brigão de Taverna, Sortudo, Artesão, Habilidoso (Perito).

## Origem — em espera
- **Iniciado em Magia** → Acólito, Guia e Sábio esperam junto.
- **Músico** → Artista espera (precisa de aliados/inspiração).
- **Curandeiro** → Eremita espera (cura de aliado).

## Gerais — ligados (escolha nos níveis 4, 6 e 8)
Veloz, Resiliente, Aumento no Valor de Atributo, Mestre em Armaduras Médias, Mestre em Armas Grandes, Mestre em Armaduras Pesadas, Retalhador (Cortador), Perfurador, Esmagador, Combatente com Duas Armas, Mestre em Escudos, Investida, Duelista Defensivo, Sentinela, Mestre em Armas de Haste, Atleta, Agarrador, Atirador de Elite, Especialista em Bestas, Especialista em Perícia, Observador, Durável, Envenenador.

Nível máximo: **8** (`Ficha.NIVEL_MAXIMO`). Três talentos gerais (níveis 4, 6 e 8).

## Gerais — em espera
- Treinamentos que o Guerreiro já tem: Levemente/Moderadamente/Fortemente Armado, Treinamento com Armas Marciais.
- Sem sistema ainda: Ator, Mente Afiada, Furtivo, Chef, Líder Inspirador, Combatente Montado.
- **Os 9 de magia** (Adepto Elemental, Tocado pelas Fadas/Sombras, Telecinético, Telepático, Conjurador Ritualista, Atirador Arcano, Conjurador de Guerra, Matador de Magos): abrir na fatia de magia.

## Antecedentes
- **No jogo (11):** Artesão, Charlatão, Criminoso, Fazendeiro, Guarda, Mercador, Nobre, Marinheiro, Escriba, Soldado, Viajante.
- **Em espera (5):** Acólito, Guia, Sábio, Artista, Eremita (talentos de origem acima).
- Compêndio mostra só o que tem `no_jogo`.

## Efeitos de origem (confirmados)
- **Alerta:** +proficiência na iniciativa (ataque mais rápido).
- **Robusto:** +2 PV por nível.
- **Atacante Selvagem:** 1×/rodada, dano da arma rolado duas vezes (fica o maior).
- **Brigão de Taverna:** soco 1d4+FOR, rerrola 1, empurra 5 pés 1×/rodada (sem arma).
- **Sortudo:** 2 pontos/fase; botão arma vantagem na próxima rolagem.
- **Artesão:** item aleatório do arsenal a cada fase; **20% de desconto na loja**.
- **Habilidoso:** 3 perícias extras na criação.

## Nomes do livro (PHB 2024 em português)
Robusto, Habilidoso, Retalhador, Combatente com Duas Armas, Mestre em Armas Grandes / Armaduras Médias / Armaduras Pesadas / Escudos / Armas de Haste, Especialista em Bestas, Mente Afiada, Chef, Aumento no Valor de Atributo, Tocado pelas Fadas/Sombras, Conjurador Ritualista, Atirador Arcano, Telepático.
Saves antigos migram em `Salvamento.NOMES_ANTIGOS_DE_TALENTOS`.
