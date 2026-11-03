# Capitolo 15: La lib `fmt` — Formattatore Tabulare Canonico 2D ed Evidenziatore di Sintassi in 9 Formati

## 15.1. Perché esiste la lib `fmt`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `fmt` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `fmt`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: la bellezza del codice Ridgun risiede nelle sue colonne tabulari perfettamente allineate (`::`, `=`, `|`, `->`, `--`), ma allineare gli spazi a mano o esportare codice colorato per terminale, HTML e LaTeX senza uno strumento dedicato è tedioso.

La lib **`fmt`** è il motore ufficiale di formattazione tabulare 2D ed evidenziazione lessicale di Ridgun: allinea firme `fn ::`, equazioni, guardie `|` e commenti `--`, ed esporta in **9 formati di output** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

In un ecosistema tradizionale, risolvere i compiti del dominio **`FMT`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`fmt`** (`src/main/ridgun/lib/fmt.rg`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import fmt` (o `import fmt as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: fmt` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `fmt` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 15.2. Artefatti nativi, importazione e catalogo completo dell'API di `fmt`

In `ridgun-libs`, **`fmt`** è una **lib** di prima classe situata in `src/main/ridgun/lib/fmt.rg` (dominio `FMT`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/fmt.rglib` | Distribuzione e importazione diretta con `import fmt` |
| **File compilato** | `target/fmt.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libfmt.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: fmt`: basta scrivere `import fmt` (o `import fmt as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 15.2.1. Riepilogo delle famiglie funzionali di `fmt`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `fmt source / fmt source with` | Formatta codice sorgente Ridgun usando l'allineamento tabulare 2D canonico |
| `fmt check` | Restituisce `True` se il codice rispetta già il formato tabulare canonico di `fmt source` |
| `fmt render / fmt render with` | Formatta e colora il codice verso uno qualsiasi dei 9 formati `FmtTarget` |
| `fmt tokenize line` | Tokenizza una riga in `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

### 15.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/fmt.rg`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/fmt.rg` (`7` tipi, `0` operatori e `166` funzioni):

**Tipi algebrici e record (`type`) di `fmt`:**

```ridgun
type FmtTarget = FmtPlain | FmtTty | FmtTrueColor | FmtHtmlInline | FmtHtmlCss | FmtMarkdown | FmtPango | FmtLatex | FmtRtf
type FmtTheme = FmtThemeNone | FmtThemeDark | FmtThemeLight
type FmtConfig = indent_width: Int, max_align_params: Int, max_line_width: Int, is_aligned: Bool, target_format: FmtTarget, color_theme: FmtTheme
type FmtToken = FmtTok String Int
type FmtSig = NoSig | SigInfo String [String] String String [Int] Int Int
type FmtClause = NoClause | ClauseInfo [String] Bool String
type FmtWhereBind = NoWhereBind | WhereBindInfo String String
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: default fmt config` | `FmtConfig` |
| `2` | `fn :: fmt config Int Int Int Bool FmtTarget FmtTheme` | `FmtConfig` |
| `3` | `fn :: fmt max Int Int` | `Int` |
| `4` | `fn :: fmt str list len [String]` | `Int` |
| `5` | `fn :: fmt str head [String]` | `String` |
| `6` | `fn :: fmt int at [Int] Int` | `Int` |
| `7` | `fn :: fmt spaces Int` | `String` |
| `8` | `fn :: fmt is hspace Int` | `Bool` |
| `9` | `fn :: fmt leading indent loop String Int Int` | `Int` |
| `10` | `fn :: fmt leading indent String` | `Int` |
| `11` | `fn :: fmt trim left loop String Int Int` | `String` |
| `12` | `fn :: fmt trim left String` | `String` |
| `13` | `fn :: fmt trim right loop String Int` | `String` |
| `14` | `fn :: fmt trim right String` | `String` |
| `15` | `fn :: fmt trim String` | `String` |
| `16` | `fn :: fmt split raw lines loop String Int Int Int Int [String]` | `[String]` |
| `17` | `fn :: fmt split raw lines String` | `[String]` |
| `18` | `fn :: fmt join lines [String]` | `String` |
| `19` | `fn :: fmt skip quoted String Int Int Int` | `Int` |
| `20` | `fn :: fmt find comment col String Int Int` | `Int` |
| `21` | `fn :: fmt strip comment String` | `String` |
| `22` | `fn :: fmt strip comment at String Int` | `String` |
| `23` | `fn :: fmt extract comment String` | `String` |
| `24` | `fn :: fmt extract comment at String Int` | `String` |
| `25` | `fn :: fmt skip hspace String Int Int` | `Int` |
| `26` | `fn :: fmt scan group end String Int Int Int` | `Int` |
| `27` | `fn :: fmt scan word end String Int Int Int` | `Int` |
| `28` | `fn :: fmt scan token end String Int Int Int` | `Int` |
| `29` | `fn :: fmt scan tokens loop String Int Int [FmtToken]` | `[FmtToken]` |
| `30` | `fn :: fmt scan tokens at String Int Int [FmtToken]` | `[FmtToken]` |
| `31` | `fn :: fmt scan tokens at step String Int Int [FmtToken] Int` | `[FmtToken]` |
| `32` | `fn :: fmt scan tokens String` | `[FmtToken]` |
| `33` | `fn :: fmt split sig arrow [FmtToken] [String]` | `(Bool, [String], String, Int)` |
| `34` | `fn :: fmt is sig type tok String` | `Bool` |
| `35` | `fn :: fmt all type toks [String]` | `Bool` |
| `36` | `fn :: fmt is bare fn lhs [String]` | `Bool` |
| `37` | `fn :: fmt infer bare kind [String]` | `String` |
| `38` | `fn :: fmt parse sig line String` | `FmtSig` |
| `39` | `fn :: fmt parse sig tokens Int String String [FmtToken]` | `FmtSig` |
| `40` | `fn :: fmt finish bare sig parse String String (Bool, [String], String, Int)` | `FmtSig` |
| `41` | `fn :: fmt finish sig parse String String String (Bool, [String], String, Int)` | `FmtSig` |
| `42` | `fn :: fmt append comment String String` | `String` |
| `43` | `fn :: fmt has fat arrow [FmtToken]` | `Bool` |
| `44` | `fn :: fmt is top decl line String` | `Bool` |
| `45` | `fn :: fmt is top decl toks Int String [FmtToken]` | `Bool` |
| `46` | `fn :: fmt op tokens match [String] [String]` | `Bool` |
| `47` | `fn :: fmt is bare kind String` | `Bool` |
| `48` | `fn :: fmt sig base col String` | `Int` |
| `49` | `fn :: fmt sig base col from FmtSig` | `Int` |
| `50` | `fn :: fmt clause matches sig String [String] [String]` | `Bool` |
| `51` | `fn :: fmt split clause eq [FmtToken] [String]` | `([String], Bool, Int)` |
| `52` | `fn :: fmt next nonblank is guard [String]` | `Bool` |
| `53` | `fn :: fmt check guard line String [String]` | `Bool` |
| `54` | `fn :: fmt parse clause line FmtSig String Bool` | `FmtClause` |
| `55` | `fn :: fmt parse clause clean String [String] String String String Bool` | `FmtClause` |
| `56` | `fn :: fmt check clause split String [String] String Bool ([String], Bool, Int)` | `FmtClause` |
| `57` | `fn :: fmt build clause info String [String] Bool Int` | `FmtClause` |
| `58` | `fn :: fmt find where arrow [FmtToken]` | `Int` |
| `59` | `fn :: fmt parse where line String Bool` | `FmtWhereBind` |
| `60` | `fn :: fmt parse where clean String String String` | `FmtWhereBind` |
| `61` | `fn :: fmt build where bind String String Int` | `FmtWhereBind` |
| `62` | `fn :: fmt check where nonempty String String` | `FmtWhereBind` |
| `63` | `fn :: fmt map str lens [String]` | `[Int]` |
| `64` | `fn :: fmt slot width Int Int` | `Int` |
| `65` | `fn :: fmt max widths [Int] [String]` | `[Int]` |
| `66` | `fn :: fmt build col starts [Int] Int` | `[Int]` |
| `67` | `fn :: fmt end col [Int] Int` | `Int` |
| `68` | `fn :: fmt scan group widths FmtSig [String] [Int] Int Bool Int` | `([Int], Int)` |
| `69` | `fn :: fmt scan group step FmtSig String [String] [Int] Int Bool Int FmtClause FmtWhereBind` | `([Int], Int)` |
| `70` | `fn :: fmt compute group geometry FmtSig [String] FmtConfig` | `FmtSig` |
| `71` | `fn :: fmt count op params [String]` | `Int` |
| `72` | `fn :: fmt count sig params String [String]` | `Int` |
| `73` | `fn :: fmt finish group geometry String [String] String String ([Int], Int) FmtConfig` | `FmtSig` |
| `74` | `fn :: fmt select group geometry String [String] String String [Int] Int Int Int Int FmtConfig` | `FmtSig` |
| `75` | `fn :: fmt pad lhs tokens [String] [Int] Int String` | `String` |
| `76` | `fn :: fmt sig prefix String String` | `String` |
| `77` | `fn :: fmt format sig line FmtSig` | `String` |
| `78` | `fn :: fmt format clause line FmtSig [String] Bool String` | `String` |
| `79` | `fn :: fmt finish clause rhs String Bool String Int Int` | `String` |
| `80` | `fn :: fmt format where line FmtSig String String Int` | `String` |
| `81` | `fn :: fmt line opens block String` | `Bool` |
| `82` | `fn :: fmt check block opener String Int` | `Bool` |
| `83` | `fn :: fmt line closes block String` | `Bool` |
| `84` | `fn :: fmt guard indent Int Int Int String Int` | `Int` |
| `85` | `fn :: fmt guard indent clean Int Int Int String String Int` | `Int` |
| `86` | `fn :: fmt format group body FmtSig [String] Int String Bool FmtConfig` | `[String]` |
| `87` | `fn :: fmt format group line FmtSig String String String Int [String] Int String Bool FmtConfig FmtClause FmtWhereBind` | `[String]` |
| `88` | `fn :: fmt format guard line FmtSig String Int [String] Int String FmtConfig Int` | `[String]` |
| `89` | `fn :: fmt next body indent Int String Int` | `Int` |
| `90` | `fn :: fmt next body indent clean Int String String Int` | `Int` |
| `91` | `fn :: fmt indent body line Int String String Int` | `String` |
| `92` | `fn :: fmt take group lines [String] [String]` | `([String], [String])` |
| `93` | `fn :: fmt format top lines [String] Int String FmtConfig` | `[String]` |
| `94` | `fn :: fmt dispatch top line String [String] Int String FmtConfig FmtSig` | `[String]` |
| `95` | `fn :: fmt run sig group FmtSig ([String], [String]) FmtConfig` | `[String]` |
| `96` | `fn :: fmt format non sig top String [String] Int String FmtConfig` | `[String]` |
| `97` | `fn :: fmt is digit Int` | `Bool` |
| `98` | `fn :: fmt is upper Int` | `Bool` |
| `99` | `fn :: fmt is lower Int` | `Bool` |
| `100` | `fn :: fmt is ident char Int` | `Bool` |
| `101` | `fn :: fmt is keyword String` | `Bool` |
| `102` | `fn :: fmt is logic op String` | `Bool` |
| `103` | `fn :: fmt is bool lit String` | `Bool` |
| `104` | `fn :: fmt classify word String Bool` | `String` |
| `105` | `fn :: fmt escape html loop String Int Int String` | `String` |
| `106` | `fn :: fmt escape html String` | `String` |
| `107` | `fn :: fmt escape latex loop String Int Int String` | `String` |
| `108` | `fn :: fmt escape latex String` | `String` |
| `109` | `fn :: fmt escape rtf loop String Int Int String` | `String` |
| `110` | `fn :: fmt escape rtf String` | `String` |
| `111` | `fn :: fmt escape for target String FmtTarget` | `String` |
| `112` | `fn :: fmt cat css class String` | `String` |
| `113` | `fn :: fmt cat ansi16 String` | `String` |
| `114` | `fn :: fmt cat rgb String FmtTheme` | `String` |
| `115` | `fn :: fmt cat hex String FmtTheme` | `String` |
| `116` | `fn :: fmt cat is bold String` | `Bool` |
| `117` | `fn :: fmt cat rtf idx String` | `String` |
| `118` | `fn :: fmt span css String String` | `String` |
| `119` | `fn :: fmt span tty String String` | `String` |
| `120` | `fn :: fmt span truecolor String String Bool` | `String` |
| `121` | `fn :: fmt span html inline String String Bool` | `String` |
| `122` | `fn :: fmt span pango String String Bool` | `String` |
| `123` | `fn :: fmt span latex String String Bool` | `String` |
| `124` | `fn :: fmt span rtf String String Bool` | `String` |
| `125` | `fn :: fmt render span String String FmtTarget FmtTheme` | `String` |
| `126` | `fn :: fmt scan ident end String Int Int` | `Int` |
| `127` | `fn :: fmt scan space end String Int Int` | `Int` |
| `128` | `fn :: fmt find close brace String Int Int` | `Int` |
| `129` | `fn :: fmt render nonempty String String FmtTarget FmtTheme` | `String` |
| `130` | `fn :: fmt highlight dquote brace String Int Int Int Int FmtTarget FmtTheme String` | `String` |
| `131` | `fn :: fmt highlight dquote loop String Int Int Int FmtTarget FmtTheme String` | `String` |
| `132` | `fn :: fmt multi op at String Int Int` | `String` |
| `133` | `fn :: fmt is single op Int` | `Bool` |
| `134` | `fn :: fmt comment cat String` | `String` |
| `135` | `fn :: fmt hl space step String Int Int Bool FmtTarget FmtTheme String Int` | `String` |
| `136` | `fn :: fmt hl dquote step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `137` | `fn :: fmt hl squote step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `138` | `fn :: fmt hl pragma step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `139` | `fn :: fmt hl mop step String Int Int FmtTarget FmtTheme String String` | `String` |
| `140` | `fn :: fmt hl ident step String Int Int Bool FmtTarget FmtTheme String Int` | `String` |
| `141` | `fn :: fmt highlight line loop String Int Int Bool FmtTarget FmtTheme String` | `String` |
| `142` | `fn :: fmt line starts clause String` | `Bool` |
| `143` | `fn :: fmt map tok strs [FmtToken]` | `[String]` |
| `144` | `fn :: fmt highlight line String FmtTarget FmtTheme` | `String` |
| `145` | `fn :: fmt highlight lines [String] FmtTarget FmtTheme` | `[String]` |
| `146` | `fn :: fmt join rtf lines [String]` | `String` |
| `147` | `fn :: fmt html pre open FmtTheme` | `String` |
| `148` | `fn :: fmt rtf colortbl FmtTheme` | `String` |
| `149` | `fn :: fmt wrap target doc [String] FmtTarget FmtTheme` | `String` |
| `150` | `fn :: fmt html stylesheet FmtTheme` | `String` |
| `151` | `fn :: fmt source with config String FmtConfig` | `String` |
| `152` | `fn :: format ridgun source String` | `String` |
| `153` | `fn :: fmt to tty with theme String FmtTheme` | `String` |
| `154` | `fn :: fmt to tty String` | `String` |
| `155` | `fn :: fmt to truecolor with theme String FmtTheme` | `String` |
| `156` | `fn :: fmt to truecolor String` | `String` |
| `157` | `fn :: fmt to html with theme String FmtTheme` | `String` |
| `158` | `fn :: fmt to html String` | `String` |
| `159` | `fn :: fmt to html css String` | `String` |
| `160` | `fn :: fmt to markdown String` | `String` |
| `161` | `fn :: fmt to pango with theme String FmtTheme` | `String` |
| `162` | `fn :: fmt to pango String` | `String` |
| `163` | `fn :: fmt to latex with theme String FmtTheme` | `String` |
| `164` | `fn :: fmt to latex String` | `String` |
| `165` | `fn :: fmt to rtf with theme String FmtTheme` | `String` |
| `166` | `fn :: fmt to rtf String` | `String` |

---

## 15.3. Esplorare `fmt` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `fmt` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test fmt.rg`.

### 15.3.1. Esempio 1: Flusso principale in stile tabulare con `fmt`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `fmt` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import fmt

fn :: formatear y verificar String => String Bool
      formatear y verificar codigo =
        codigo fmt ridgun -> limpio
        limpio fmt check ridgun -> es_ok
        (limpio, es_ok)
```

### 15.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `fmt` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html String => String
      exportar bloque html codigo =
        fmt highlight ridgun codigo FmtHtmlCss
```

### 15.3.3. Esempio 3: Allineamento tabulare canonico (`fmt ridgun`, `fmt ridgun with`) di firme `=>`, clausole `=`, catene `->` e commenti `--`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `fmt` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test fmt canonical alignment and config => ()
      test fmt canonical alignment and config =
        nl = char from code 10
        raw_src = "fn :: add Int Int => Int" + nl + "add x y = x + y" + nl + "add 0 y_long = y_long" + nl
        expected_2d = "fn :: add Int Int    => Int" + nl + "      add x   y      =  x + y" + nl + "      add 0   y_long =  y_long" + nl
        out_2d = format ridgun source raw_src
        assert str eq out_2d expected_2d "AC1: canonical 2D tabular alignment"

        -- Unaligned config (`is_aligned = False`) uses single-space separation
        cfg_unaligned = fmt config 2 4 80 False FmtPlain FmtThemeNone
        out_unaligned = fmt source with config raw_src cfg_unaligned
        expected_unaligned = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "      add 0 y_long = y_long" + nl
        assert str eq out_unaligned expected_unaligned "AC1: unaligned FmtConfig"

        -- Guard and `where` alignment with custom indent_width = 4
        guard_src = "fn :: clamp Int => Int" + nl + "clamp x" + nl + "| x < 0 = 0" + nl + "| otherwise = x" + nl + "where" + nl + "lo -> 0" + nl
        cfg_ind4 = fmt config 4 4 80 True FmtPlain FmtThemeNone
        out_ind4 = fmt source with config guard_src cfg_ind4
        assert true (str contains out_ind4 "          | x < 0 = 0") "AC1: custom indent_width = 4 guard indentation"
        assert true (str contains out_ind4 "              lo -> 0") "AC1: custom indent_width = 4 where binding alignment"
        ()
```

### 15.3.4. Esempio 4: Evidenziazione lessicale ANSI a 16 colori e TrueColor a 24 bit con rilevamento automatico di TTY e `NO_COLOR`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `fmt` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test fmt terminal highlighting tty and truecolor => ()
      test fmt terminal highlighting tty and truecolor =
        nl = char from code 10
        esc = char from code 27
        interp_tok = (char from code 123) + "name" + (char from code 125)
        sample = "-- @implements FR-FMT-001" + nl + "-- comment line" + nl + "fn :: greet String => String" + nl + "greet name = \"Hello " + interp_tok + "\" + (int_to_str 0x2A)" + nl

        tty_dark = fmt to tty sample
        assert true (str contains tty_dark (esc + "[1;32m-- @implements FR-FMT-001" + esc + "[0m")) "AC2: TTY pragma highlight"
        assert true (str contains tty_dark (esc + "[90m-- comment line" + esc + "[0m")) "AC2: TTY comment highlight"
        assert true (str contains tty_dark (esc + "[1;35mfn" + esc + "[0m")) "AC2: TTY keyword highlight"
        assert true (str contains tty_dark (esc + "[1;34mgreet" + esc + "[0m")) "AC2: TTY function name highlight"
        assert true (str contains tty_dark (esc + "[33mString" + esc + "[0m")) "AC2: TTY type highlight"
        assert true (str contains tty_dark (esc + "[36m" + interp_tok + esc + "[0m")) "AC2: TTY string interpolation highlight"
        assert true (str contains tty_dark (esc + "[36m0x2A" + esc + "[0m")) "AC2: TTY hex number highlight"

        tty_none = fmt to tty with theme sample FmtThemeNone
        assert false (str contains tty_none esc) "AC2: FmtThemeNone emits no ANSI escape codes"

        tc_dark = fmt to truecolor sample
        assert true (str contains tc_dark (esc + "[1;38;2;198;120;221mfn" + esc + "[0m")) "AC2: TrueColor dark keyword RGB"
        assert true (str contains tc_dark (esc + "[1;38;2;97;175;239mgreet" + esc + "[0m")) "AC2: TrueColor dark function RGB"

        tc_light = fmt to truecolor with theme sample FmtThemeLight
        assert true (str contains tc_light (esc + "[1;38;2;166;38;164mfn" + esc + "[0m")) "AC2: TrueColor light keyword RGB"
        ()
```

### 15.3.5. Esempio 5: Esportazione di documenti evidenziati in HTML5 (`<pre><code>`), Pango Markup, LaTeX, RTF e SVG vettoriale

In questo esempio pratico esploriamo in modo esaustivo come si comporta `fmt` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test fmt enriched document targets => ()
      test fmt enriched document targets =
        nl = char from code 10
        src = "fn :: cmp Int Int => Bool" + nl + "cmp a b = a < b AND b > 0" + nl

        -- 1. Inline HTML
        html_out = fmt to html src
        assert true (str starts with html_out "<pre class=\"ridgun-code\"") "AC3: HTML inline wrapper"
        assert true (str contains html_out "<span style=\"color:#c678dd;font-weight:bold\">fn</span>") "AC3: HTML inline keyword span"
        assert true (str contains html_out "&lt;") "AC3: HTML escapes < operator"
        assert true (str contains html_out "&gt;") "AC3: HTML escapes > operator"

        -- 2. CSS-class HTML + Stylesheet
        css_html = fmt to html css src
        assert true (str contains css_html "<span class=\"rg-kw\">fn</span>") "AC3: HTML CSS keyword class"
        assert true (str contains css_html "<span class=\"rg-fn\">cmp</span>") "AC3: HTML CSS function class"
        assert true (str contains css_html "<span class=\"rg-type\">Int</span>") "AC3: HTML CSS type class"
        assert true (str contains css_html "<span class=\"rg-logic\">AND</span>") "AC3: HTML CSS logic operator class"
        sheet_dark = fmt html stylesheet FmtThemeDark
        sheet_light = fmt html stylesheet FmtThemeLight
        assert true (str contains sheet_dark ".rg-kw") "AC3: Dark CSS stylesheet"
        assert true (str contains sheet_light "#fafafa") "AC3: Light CSS stylesheet"

        -- 3. Markdown
        md_out = fmt to markdown src
        assert true (str starts with md_out ("
```ridgun" + nl)) "AC3: Markdown fenced code block"

        -- 4. Pango Markup
        pango_out = fmt to pango src
        _ = assert true (str starts with pango_out ("<tt>" + nl)) "AC3: Pango <tt> wrapper"
        _ = assert true (str contains pango_out "<span foreground=\"#c678dd\" weight=\"bold\">fn</span>") "AC3: Pango span markup"

        -- 5. LaTeX Verbatim
        latex_out = fmt to latex src
        _ = assert true (str contains latex_out "Verbatim") "AC3: LaTeX Verbatim environment"
        _ = assert true (str contains latex_out "textcolor[HTML]") "AC3: LaTeX textcolor macro"

        -- 6. RTF
        rtf_out = fmt to rtf src
        _ = assert true (str contains rtf_out "rtf1") "AC3: RTF header"
        _ = assert true (str contains rtf_out "colortbl") "AC3: RTF color table"
        _ = assert true (str contains rtf_out "\\cf1\\b fn") "AC3: RTF bold color span"
        ()
```

---

## 15.4. Sotto il cofano: come è costruita `fmt` in Ridgun puro (`src/main/ridgun/lib/fmt.rg`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/fmt.rg` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 15.4.1. Implementazione interna: Configuration Constructors

Nota come `fmt.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: fmt

fn :: default fmt config => FmtConfig
      default fmt config = FmtConfig 2 4 80 True FmtPlain FmtThemeNone

fn :: fmt config Int Int Int Bool FmtTarget FmtTheme => FmtConfig
      fmt config indent_w max_params max_w aligned target theme =
        FmtConfig (fmt max 1 indent_w) (fmt max 0 max_params) (fmt max 20 max_w) aligned target theme
```

### 15.4.2. Implementazione interna: Signature Parsing (`fn ::` / `op ::`)

Nota come `fmt.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: fmt split sig arrow [FmtToken] [String] => (Bool, [String], String, Int)
      fmt split sig arrow []         _        =  (False, [], "", 0)
      fmt split sig arrow ((FmtTok tok col):rest) lhs_acc
        | tok == "=>" OR tok == "->" = (True, lhs_acc, tok, col)
        | otherwise = fmt split sig arrow rest (lhs_acc :: [tok])

fn :: fmt is sig type tok String => Bool
      fmt is sig type tok ""     =  False
      fmt is sig type tok tok    =
        ch = str char at tok 0
        (ch >= 65 AND ch <= 90) OR ch == 91 OR ch == 40

fn :: fmt all type toks [String] => Bool
      fmt all type toks []       =  True
      fmt all type toks (t:rest)
        | fmt is sig type tok t = fmt all type toks rest
        | otherwise = False

fn :: fmt is bare fn lhs [String]       => Bool
      fmt is bare fn lhs (first_w:rest)
        | NOT (fmt is sig type tok first_w) = fmt all type toks rest
      fmt is bare fn lhs _              =  False

fn :: fmt infer bare kind [String] => String
      fmt infer bare kind lhs_strs
        | fmt is bare fn lhs lhs_strs = "bare_fn"
        | otherwise = "bare_op"

fn :: fmt parse sig line String => FmtSig
      fmt parse sig line line   =
        clean = fmt strip comment line
        cmt = fmt extract comment line
        toks = fmt scan tokens clean
        fmt parse sig tokens (fmt leading indent line) clean cmt toks

fn :: fmt parse sig tokens Int String String [FmtToken] => FmtSig
      fmt parse sig tokens _   clean  cmt    ((FmtTok kind _):(FmtTok "::" _):rest)
        | kind == "fn" OR kind == "op" = fmt finish sig parse clean cmt kind (fmt split sig arrow rest [])
      fmt parse sig tokens 0   clean  cmt    ((FmtTok w col):rest)
        | w == "type" OR w == "expand" OR w == "import" OR w == "global" OR w == "context" OR w == "shared" OR w == "hardware" OR (str starts with w "@") OR (str starts with w "--") OR (str starts with w "|") = NoSig
        | otherwise = fmt finish bare sig parse clean cmt (fmt split sig arrow ([FmtTok w col] :: rest) [])
      fmt parse sig tokens _   _      _      _          =  NoSig

fn :: fmt finish bare sig parse String String (Bool, [String], String, Int) => FmtSig
      fmt finish bare sig parse _ _ (False, _, _, _) = NoSig
      fmt finish bare sig parse _ _ (True, [], _, _) = NoSig
      fmt finish bare sig parse clean cmt (True, lhs_strs, arrow_s, arrow_col)
        | arrow_s == "=>" = fmt finish sig parse clean cmt (fmt infer bare kind lhs_strs) (True, lhs_strs, arrow_s, arrow_col)
        | otherwise = NoSig
```

### 15.4.3. Implementazione interna: Lexical Token Classification & Syntax Highlighting

Nota come `fmt.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: fmt is digit Int => Bool
      fmt is digit c = c >= 48 and c <= 57

fn :: fmt is upper Int => Bool
      fmt is upper c = c >= 65 and c <= 90

fn :: fmt is lower Int => Bool
      fmt is lower c = c >= 97 and c <= 122

fn :: fmt is ident char Int => Bool
      fmt is ident char c = (fmt is upper c) or (fmt is lower c) or (fmt is digit c) or c == 95

fn :: fmt is keyword String => Bool
      fmt is keyword w =
        w == "fn" or w == "op" or w == "type" or w == "expand" or w == "import" or w == "module" or w == "where" or w == "otherwise" or w == "with" or w == "do" or w == "mut" or w == "in" or w == "agent" or w == "send" or w == "to" or w == "receive" or w == "from" or w == "try" or w == "stop" or w == "timeout" or w == "global" or w == "context" or w == "shared" or w == "hardware" or w == "atomic" or w == "region" or w == "limit" or w == "map" or w == "filter" or w == "fold"

fn :: fmt is logic op String => Bool
      fmt is logic op w =
        w == "AND" or w == "OR" or w == "XOR" or w == "NOT" or w == "and" or w == "or" or w == "xor" or w == "not" or w == "shl" or w == "shr" or w == "rotr" or w == "rotl"

fn :: fmt is bool lit String => Bool
      fmt is bool lit w = w == "True" or w == "False"

fn :: fmt classify word String Bool => String
      fmt classify word "" _ = "plain"
      fmt classify word w in_fn =
        | fmt is keyword w = "keyword"
        | fmt is logic op w = "logic"
        | fmt is bool lit w = "bool"
        | fmt is upper (str char at w 0) = "type"
        | fmt is digit (str char at w 0) = "number"
        | in_fn = "function"
        | otherwise = "plain"
```

### 15.4.4. Implementazione interna: Public Entry Points

Nota come `fmt.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: fmt source with config String FmtConfig => String
      fmt source with config src cfg =
        src fmt split raw lines -> raw_lines
        fmt format top lines raw_lines 0 "" cfg -> formatted_lines
        cfg target_format -> target
        cfg color_theme -> theme
        fmt highlight lines formatted_lines target theme -> highlighted
        fmt wrap target doc highlighted target theme

fn :: format ridgun source String => String
      format ridgun source src = fmt source with config src (default fmt config)

fn :: fmt to tty with theme String FmtTheme => String
      fmt to tty with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtTty theme)

fn :: fmt to tty String => String
      fmt to tty src = fmt to tty with theme src FmtThemeDark

fn :: fmt to truecolor with theme String FmtTheme => String
      fmt to truecolor with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtTrueColor theme)

fn :: fmt to truecolor String => String
      fmt to truecolor src = fmt to truecolor with theme src FmtThemeDark

fn :: fmt to html with theme String FmtTheme => String
      fmt to html with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtHtmlInline theme)

fn :: fmt to html String => String
      fmt to html src = fmt to html with theme src FmtThemeDark

fn :: fmt to html css String => String
      fmt to html css src =
        fmt source with config src (FmtConfig 2 4 80 True FmtHtmlCss FmtThemeDark)

fn :: fmt to markdown String => String
      fmt to markdown src =
        fmt source with config src (FmtConfig 2 4 80 True FmtMarkdown FmtThemeNone)

fn :: fmt to pango with theme String FmtTheme => String
      fmt to pango with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtPango theme)

fn :: fmt to pango String => String
      fmt to pango src = fmt to pango with theme src FmtThemeDark

fn :: fmt to latex with theme String FmtTheme => String
      fmt to latex with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtLatex theme)

fn :: fmt to latex String => String
      fmt to latex src = fmt to latex with theme src FmtThemeDark

fn :: fmt to rtf with theme String FmtTheme => String
      fmt to rtf with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtRtf theme)

fn :: fmt to rtf String => String
      fmt to rtf src = fmt to rtf with theme src FmtThemeDark
```

---

## 15.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `fmt`

- **Garanzia algoritmica e di sicurezza**: Idempotenza rigorosa (`fmt source (fmt source s) == fmt source s`) e conservazione del 100% dei token semantici.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/fmt.rg` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test fmt.rg`.

### Le 5 Regole d'Oro quando programmi con `fmt`

1. **Dichiara `import fmt` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `fmt` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `fmt` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `fmt` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 16** passeremo a esplorare in profondità la lib **`cli`** (La lib `cli` — Flag, Opzioni, Barriera `--`, Sottocomandi e Variabili d'Ambiente).
