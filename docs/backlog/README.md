# Backlog

Um arquivo = uma pendência. **Não invente fatia fora daqui.**

Legenda `size`: **P** (uma tarde), **M** (uma fatia), **G** (várias fatias).  
`priority`: menor número = mais cedo. Ao fechar: **apague** o arquivo (ou mova para o `CHANGELOG`) e atualize esta lista se precisar.

## Como a IA escolhe (`/proxima-fatia`)

1. Liste `docs/backlog/*.md` (ignore `_modelo.md` e este README).
2. Leia o YAML (`title`, `size`, `priority`, `area`).
3. Ofereça **3 opções** (menor `priority` primeiro como recomendada).
4. Leia o fim de `docs/CHANGELOG.md` para não repetir o que acabou de sair.

## Índice (por prioridade)

### Próximas
| Pri | Arquivo | Tam. |
|---|---|---|
| 1 | `validar-apk.md` | P |
| 2 | `subclasse-guerreiro.md` | M |
| 3 | `testes-pericia-fases.md` | M |
| 4 | `ia-salto-terreno.md` | M |
| 5 | `lava-covil.md` | M |
| 6 | `refino-minion.md` | P |
| 7 | `arte-pantano-ruina.md` | M |
| 8 | `som-faltante.md` | M |
| 9 | `minions-recolor.md` | M |
| 10 | `ataques-novos-monstros.md` | M |

### Regras do livro
| Pri | Arquivo | Tam. |
|---|---|---|
| 50 | `racas-especies.md` | G |
| 51 | `magia.md` | G |
| 52 | `descanso-curto.md` | P |
| 54 | `amorfo-ooze.md` | P |
| 55 | `desvantagem-furtividade-armadura.md` | P |
| 56 | `pericias-em-jogo.md` | M |

### Arte / polish
| Pri | Arquivo | Tam. |
|---|---|---|
| 70–76 | `efeitos-golpe-arte`, `tileset-cenario`, `armaduras-visuais`, `goblin-arte-adaga`, `estocada-heroi`, `bau-abrindo`, `enfeites-mapa` | P–M |

### Dívidas técnicas
| Pri | Arquivo |
|---|---|
| 82–89 | `capacidades-*` (arremesso, tática, investida, furtividade, fuga-ágil, matilha, voo, linha-área) |
| 90+ | `dry-*` … `validar-chefes` |

### Depois
| Pri | Arquivo |
|---|---|
| 95–100 | `gamepad`, `ios`, `renomear-jogo`, `porta-aparencia-cota`, `municao-comum-inventario`, `atirador-elite-obstaculos` |

Novo item: copie `_modelo.md`.
