# Capítulo 15: A lib `fmt` — Formatador Tabular Canónico 2D e Resaltador de Sintaxe en 9 Formatos

## 1. Por que existe a lib `fmt`?

Sexamos sinceros: a beleza do código Ridgun reside nas súas columnas tabulares perfectamente aliñadas (`::`, `=`, `|`, `->`, `--`), pero aliñar espazos á man ou exportar código coloreado para terminal, HTML e LaTeX sen unha ferramenta dedicada é tedioso.

A lib **`fmt`** é o motor oficial de formatado tabular 2D e resaltado léxico de Ridgun: aliña sinaturas `fn ::`, ecuacións, gardas `|` e comentarios `--`, e exporta a **9 formatos de saída** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`fmt`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/fmt.rg` (dominio `FMT`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/fmt.rglib` | Distribución e importación directa con `import fmt` |
| **Ficheiro compilado** | `target/fmt.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libfmt.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import fmt` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `fmt`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `fmt source / fmt source with` | Formatea código fonte Ridgun usando o aliñamento tabular 2D canónico |
| `fmt check` | Devolve `True` se o código xa cumpre o formato tabular canónico de `fmt source` |
| `fmt render / fmt render with` | Formatea e colorea o código cara a calquera dos 9 formatos `FmtTarget` |
| `fmt tokenize line` | Tokeniza unha liña en `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `fmt`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `fmt` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Idempotencia estrita (`fmt source (fmt source s) == fmt source s`) e preservación do 100 % dos tokens semánticos.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_fmt.rg`.
