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
| — | (vazio: escolher em `depois/` ou `divida/`) |

### Regras do livro
Magia, raças e desvantagem de Furtividade na armadura ficam em `depois/`.

### Arte / polish
| Pri | Arquivo |
|---|---|

### Dívidas técnicas
| Pri | Arquivo |
|---|---|
| 90+ | `divida/dry-*`, `split-jogador-gd`, `renomear-features-goblin` … |

### Depois
| Pri | Arquivo |
|---|---|
| 95–100 | `depois/gamepad`, `ios`, `renomear-jogo`, `porta-aparencia-cota`, `municao-comum-inventario`, `atirador-elite-obstaculos`, `minions-recolor`, `magia`, `racas-especies`, `desvantagem-furtividade-armadura` |

Novo item: copie `_modelo.md` para a pasta da `area`.
