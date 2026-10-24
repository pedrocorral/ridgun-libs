# Kapitel 15: Lib:en `fmt` — Kanonisk 2D-tabellformaterare och Syntaxmarkering för 9 Målformat

## 1. Varför finns lib:en `fmt`?

Låt oss vara ärliga: skönheten i Ridgun-kod ligger i dess perfekt justerade tabellkolumner (`::`, `=`, `|`, `->`, `--`), men att justera mellanslag för hand eller exportera färgkodad syntax till terminal, HTML och LaTeX är tidsödande.

Lib:en **`fmt`** är Ridguns officiella 2D-tabellformaterare och syntaxmarkerare: den justerar `fn ::`-signaturer, ekvationer, `|`-vakter och `--`-kommentarer samt exporterar till **9 målformat** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`fmt`** en förstklassig **lib** placerad i `src/main/ridgun/lib/fmt.rg` (domän `FMT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/fmt.rglib` | Portabel distribution och direkt import med `import fmt` |
| **Kompilerat arkiv** | `target/fmt.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libfmt.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import fmt` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `fmt`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `fmt source / fmt source with` | Formaterar Ridgun-källkod med kanonisk 2D-tabelljustering |
| `fmt check` | Returnerar `True` om källkoden redan följer kanonisk `fmt source`-layout |
| `fmt render / fmt render with` | Formaterar och syntaxmarkerar källkod till valfritt av de 9 `FmtTarget`-målen |
| `fmt tokenize line` | Tokeniserar en rad till `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `fmt`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `fmt` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Strikt idempotens (`fmt source (fmt source s) == fmt source s`) och 100 % bevarande av semantiska tokens.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_fmt.rg`.
