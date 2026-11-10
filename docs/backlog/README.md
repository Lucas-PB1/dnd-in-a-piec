# Backlog

Um arquivo = uma pendência, na subpasta da `area` (YAML). **Não invente fatia fora daqui.**

Legenda `size`: **P** (uma tarde), **M** (uma fatia), **G** (várias fatias).  
`priority`: menor número = mais cedo. Ao fechar: **apague** o arquivo (ou mova para o `CHANGELOG`) e atualize esta lista se precisar.

Pastas = `area`: `arte/`, `audio/`, `criaturas/`, `depois/`, `divida/`, `fases/`, `heroi/`, `mobile/`, `regras/`.  
Na raiz só `README.md` e `_modelo.md`.

## Como a IA escolhe (`/proxima-fatia`)

1. Liste `docs/backlog/**/*.md` (ignore `_modelo.md` e este README).
2. Leia o YAML (`title`, `size`, `priority`, `area`).
3. Ofereça **3 opções** (menor `priority` primeiro como recomendada).
4. Leia o fim de `docs/CHANGELOG.md` para não repetir o que acabou de sair.

## Índice (por prioridade)

### Próximas
| Pri | Arquivo | Tam. |
|---|---|---|
| 1 | `mobile/validar-apk.md` | P |
| 2 | `heroi/subclasse-guerreiro.md` | M |
| 3 | `fases/testes-pericia-fases.md` | M |
| 4 | `criaturas/ia-salto-terreno.md` | M |
| 5 | `fases/lava-covil.md` | M |
| 6 | `arte/refino-minion.md` | P |
| 7 | `arte/arte-pantano-ruina.md` | M |
| 8 | `audio/som-faltante.md` | M |
| 9 | `criaturas/minions-recolor.md` | M |
| 10 | `criaturas/ataques-novos-monstros.md` | M |

### Regras do livro
| Pri | Arquivo | Tam. |
|---|---|---|
| 50 | `regras/racas-especies.md` | G |
| 51 | `regras/magia.md` | G |
| 52 | `regras/descanso-curto.md` | P |
| 54 | `criaturas/amorfo-ooze.md` | P |
| 55 | `regras/desvantagem-furtividade-armadura.md` | P |
| 56 | `regras/pericias-em-jogo.md` | M |

### Arte / polish
| Pri | Arquivo | Tam. |
|---|---|---|
| 70–76 | `arte/efeitos-golpe-arte`, `tileset-cenario`, `armaduras-visuais`, `goblin-arte-adaga`, `estocada-heroi`, `bau-abrindo`, `enfeites-mapa` | P–M |

### Dívidas técnicas
| Pri | Arquivo |
|---|---|
| 87–89 | `divida/capacidades-*` (matilha, voo, linha-área) |
| 90+ | `divida/dry-*` … `validar-chefes` |

### Depois
| Pri | Arquivo |
|---|---|
| 95–100 | `depois/gamepad`, `ios`, `renomear-jogo`, `porta-aparencia-cota`, `municao-comum-inventario`, `atirador-elite-obstaculos` |

Novo item: copie `_modelo.md` para a pasta da `area`.
