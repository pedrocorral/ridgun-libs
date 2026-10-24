# Capítol 15: La lib `fmt` — Formatador Tabular Canònic 2D i Ressaltador de Sintaxi en 9 Formats

## 1. Per què existeix la lib `fmt`?

Siguem sincers: la bellesa del codi Ridgun rau en les seves columnes tabulars perfectament alineades (`::`, `=`, `|`, `->`, `--`), però alinear espais a mà o exportar codi acolorit per a terminal, HTML i LaTeX sense una eina dedicada és tediós.

La lib **`fmt`** és el motor oficial de formatat tabular 2D i ressaltat lèxic de Ridgun: alinea signatures `fn ::`, equacions, guardes `|` i comentaris `--`, i exporta a **9 formats de sortida** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`fmt`** és una **lib** de primera classe situada a `src/main/ridgun/lib/fmt.rg` (domini `FMT`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/fmt.rglib` | Distribució i importació directa amb `import fmt` |
| **Fitxer compilat** | `target/fmt.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libfmt.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import fmt` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `fmt`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `fmt source / fmt source with` | Formata codi font Ridgun fent servir l'alineació tabular 2D canònica |
| `fmt check` | Retorna `True` si el codi ja compleix el format tabular canònic de `fmt source` |
| `fmt render / fmt render with` | Formata i acoloreix el codi cap a qualsevol dels 9 formats `FmtTarget` |
| `fmt tokenize line` | Tokenitza una línia en `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `fmt`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `fmt` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Idempotència estricta (`fmt source (fmt source s) == fmt source s`) i preservació del 100 % dels tokens semàntics.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_fmt.rg`.
