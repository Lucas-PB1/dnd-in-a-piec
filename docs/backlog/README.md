# Backlog

Um arquivo = uma pendência, na subpasta da `area` (YAML). **Não invente fatia fora daqui.**

Legenda `size`: **P** (uma tarde), **M** (uma fatia), **G** (várias fatias).  
`priority`: menor número = mais cedo. Ao fechar: **apague** o arquivo (ou mova para o `CHANGELOG`) e atualize esta lista se precisar.

Pastas = `area`: `arte/`, `audio/`, `criaturas/`, `depois/`, `divida/`, `fases/`, `heroi/`, `mobile/`, `regras/`.  
Na raiz só `README.md` e `_modelo.md`.

## O que não entra no backlog

Sensação, balance fino e “testar no aparelho” vivem do **feedback do usuário com o tempo**.  
Não crie item só para “validar / jogar / anotar / aprovar sensação”. Quando vier um problema concreto, aí sim abre fatia (ou ajusta na hora).

## Como a IA escolhe (`/proxima-fatia`)

1. Liste `docs/backlog/**/*.md` (ignore `_modelo.md` e este README).
2. Leia o YAML (`title`, `size`, `priority`, `area`).
3. Ofereça **3 opções** (menor `priority` primeiro como recomendada).
4. Leia o fim de `docs/CHANGELOG.md` para não repetir o que acabou de sair.

## Índice (por prioridade)

### Próximas
| Pri | Arquivo |
|---|---|
| 5 | `divida/desafio-pericia-nos-duplicados` |
| 10 | `regras/loja-renovar-estoque` |
| 11 | `regras/loja-sempre-municao` |
| 12 | `regras/pocoes-cura` |
| 13 | `mobile/defaults-primeira-execucao` |
| 14 | `heroi/corrosao-mais-clara` |
| 15 | `heroi/veneno-uso-claro` |

### Regras do livro
Nenhuma aberta nesta fila. Magia, raças e desvantagem de Furtividade na armadura foram para `depois/`. Poções de cura e loja estão em **Próximas** (`regras/`).

### Arte / polish
Nenhuma aberta nesta fila.

### Dívidas técnicas
| Pri | Arquivo |
|---|---|
| 5 | `divida/desafio-pericia-nos-duplicados` (também em Próximas) |
| 90+ | `divida/dry-*`, `split-jogador-gd`, `sinais-heroi-orfaos`, `projetil-altura-nascimento`, `quimera-anim-dano`, `renomear-features-goblin` … |

### Depois
| Pri | Arquivo |
|---|---|
| 95–100 | `depois/gamepad`, `ios`, `renomear-jogo`, `porta-aparencia-cota`, `municao-comum-inventario`, `atirador-elite-obstaculos`, `minions-recolor`, `magia`, `racas-especies`, `desvantagem-furtividade-armadura` |

Novo item: copie `_modelo.md` para a pasta da `area`.
