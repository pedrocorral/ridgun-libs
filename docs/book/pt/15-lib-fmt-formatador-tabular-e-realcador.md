# Capítulo 15: A lib `fmt` — Formatador Tabular Canónico 2D e Realçador de Sintaxe em 9 Formatos

## 15.1. Por que existe a lib `fmt`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `fmt` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `fmt`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: a beleza do código Ridgun reside nas suas colunas tabulares perfeitamente alinhadas (`::`, `=`, `|`, `->`, `--`), mas alinhar espaços à mão ou exportar código colorido para terminal, HTML e LaTeX é trabalhoso.

A lib **`fmt`** é o motor oficial de formatação tabular 2D e realce léxico do Ridgun: alinha assinaturas `fn ::`, equações, guardas `|` e comentários `--`, e exporta para **9 formatos de saída** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

Num ecossistema tradicional, resolver as tarefas do domínio **`FMT`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`fmt`** (`src/main/ridgun/lib/fmt.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import fmt` (ou `import fmt as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: fmt` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `fmt` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 15.2. Artefactos nativos, importação e catálogo completo da API de `fmt`

No `ridgun-libs`, **`fmt`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/fmt.rg` (domínio `FMT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/fmt.rglib` | Distribuição e importação direta com `import fmt` |
| **Ficheiro compilado** | `target/fmt.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libfmt.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Cada lib declara o seu próprio espaço de nomes com `module :: fmt`: basta escrever `import fmt` (ou `import fmt as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 15.2.1. Resumo das famílias funcionais da `fmt`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `fmt source / fmt source with` | Formata código-fonte Ridgun usando o alinhamento tabular 2D canónico |
| `fmt check` | Devolve `True` se o código já cumprir o formato tabular canónico de `fmt source` |
| `fmt render / fmt render with` | Formata e realça o código para qualquer um dos 9 formatos `FmtTarget` |
| `fmt tokenize line` | Tokeniza uma linha em `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

### 15.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/fmt.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/fmt.rg` (`7` tipos, `0` operadores e `166` funções):

**Tipos algébricos e registos (`type`) da `fmt`:**

```ridgun
type FmtTarget = FmtPlain | FmtTty | FmtTrueColor | FmtHtmlInline | FmtHtmlCss | FmtMarkdown | FmtPango | FmtLatex | FmtRtf
type FmtTheme = FmtThemeNone | FmtThemeDark | FmtThemeLight
type FmtConfig = indent_width: Int, max_align_params: Int, max_line_width: Int, is_aligned: Bool, target_format: FmtTarget, color_theme: FmtTheme
type FmtToken = FmtTok String Int
type FmtSig = NoSig | SigInfo String [String] String String [Int] Int Int
type FmtClause = NoClause | ClauseInfo [String] Bool String
type FmtWhereBind = NoWhereBind | WhereBindInfo String String
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 15.3. Explorando a `fmt` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `fmt` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test fmt.rg`.

### 15.3.1. Exemplo 1: Fluxo principal em estilo tabular com `fmt`

Repare como em Ridgun os sinais `=` e os passos de transformação com `fmt` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import fmt

fn :: formatear y verificar String => String Bool
      formatear y verificar codigo =
        codigo fmt ridgun -> limpio
        limpio fmt check ridgun -> es_ok
        (limpio, es_ok)
```

### 15.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `fmt` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html String => String
      exportar bloque html codigo =
        fmt highlight ridgun codigo FmtHtmlCss
```

### 15.3.3. Exemplo 3: Alinhamento tabular canónico (`fmt ridgun`, `fmt ridgun with`) de assinaturas `=>`, cláusulas `=`, ligações `->` e comentários `--`

Neste exemplo prático exploramos de forma exaustiva como a `fmt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 15.3.4. Exemplo 4: Realce léxico ANSI de 16 cores e TrueColor de 24 bits com deteção automática de TTY e `NO_COLOR`

Neste exemplo prático exploramos de forma exaustiva como a `fmt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 15.3.5. Exemplo 5: Exportação de documentos realçados para HTML5 (`<pre><code>`), Pango Markup, LaTeX, RTF e SVG vetorial

Neste exemplo prático exploramos de forma exaustiva como a `fmt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

## 15.4. Debaixo do capô: como a `fmt` é construída em Ridgun puro (`src/main/ridgun/lib/fmt.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/fmt.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 15.4.1. Implementação interna: Configuration Constructors

Observe como `fmt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: fmt

fn :: default fmt config => FmtConfig
      default fmt config = FmtConfig 2 4 80 True FmtPlain FmtThemeNone

fn :: fmt config Int Int Int Bool FmtTarget FmtTheme => FmtConfig
      fmt config indent_w max_params max_w aligned target theme =
        FmtConfig (fmt max 1 indent_w) (fmt max 0 max_params) (fmt max 20 max_w) aligned target theme
```

### 15.4.2. Implementação interna: Signature Parsing (`fn ::` / `op ::`)

Observe como `fmt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 15.4.3. Implementação interna: Lexical Token Classification & Syntax Highlighting

Observe como `fmt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 15.4.4. Implementação interna: Public Entry Points

Observe como `fmt.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

## 15.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `fmt`

- **Garantia algorítmica e de segurança**: Idempotência estrita (`fmt source (fmt source s) == fmt source s`) e preservação de 100 % dos tokens semânticos.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/fmt.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test fmt.rg`.

### As 5 Regras de Ouro ao programar com a `fmt`

1. **Declare `import fmt` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `fmt` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `fmt` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `fmt` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 16** passaremos a explorar em profundidade a lib **`cli`** (A lib `cli` — Flags, Opções, Barreira `--`, Subcomandos e Variáveis de Ambiente).
