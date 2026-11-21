# Capítulo 15: A lib `fmt` — Formatador Tabular Canónico 2D e Realçador de Sintaxe em 9 Formatos

## 15.1. Por que existe a lib `fmt`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `fmt` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `fmt`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: a beleza do código Ridgun reside nas suas colunas tabulares perfeitamente alinhadas (`::`, `=`, `|`, `->`, `--`), mas alinhar espaços à mão ou exportar código colorido para terminal, HTML e LaTeX é trabalhoso.

A lib **`fmt`** é o motor oficial de formatação tabular 2D e realce léxico do Ridgun: alinha assinaturas `fn ::`, equações, guardas `|` e comentários `--`, e exporta para **9 formatos de saída** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

Num ecossistema tradicional, resolver as tarefas do domínio **`FMT`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`fmt`** (`src/main/ridgun/lib/fmt.ridgun`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import fmt` (ou `import fmt as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: fmt` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `fmt` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 15.2. Artefactos nativos, importação e catálogo completo da API de `fmt`

No `ridgun-libs`, **`fmt`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/fmt.ridgun` (domínio `FMT`). Ao compilar com `stable bundle`, é empacotada num formato nativo:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/fmt.ridgunlib` | Distribuição e importação direta com `import fmt` |

> Cada lib declara o seu próprio espaço de nomes com `module :: fmt`: basta escrever `import fmt` (ou `import fmt as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 15.2.1. Resumo das famílias funcionais da `fmt`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `format ridgun source / fmt source with config` | Formata código-fonte Ridgun com o alinhamento tabular canónico de colunas, com a configuração por omissão ou com uma `FmtConfig` dada |
| `default fmt config / fmt config` | Constrói uma `FmtConfig`: largura da indentação, limites de alinhamento, largura de linha, destino e tema |
| `fmt to tty / fmt to truecolor / fmt to html / fmt to html css / fmt to markdown / fmt to pango / fmt to latex / fmt to rtf` | Formata e realça código-fonte para um terminal, HTML, Markdown, Pango, LaTeX ou RTF |
| `fmt highlight line / fmt highlight lines` | Realça uma linha ou uma lista de linhas para um `FmtTarget` e um `FmtTheme` |

### 15.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/fmt.ridgun`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/fmt.ridgun` (`7` tipos, `0` operadores e `200` funções):

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
| `33` | `fn :: fmt split sig arrow [FmtToken] [String]` | `Bool [String] String Int` |
| `34` | `fn :: fmt is sig type tok String` | `Bool` |
| `35` | `fn :: fmt all type toks [String]` | `Bool` |
| `36` | `fn :: fmt is bare fn lhs [String]` | `Bool` |
| `37` | `fn :: fmt infer bare kind [String]` | `String` |
| `38` | `fn :: fmt is valid sig name tok String` | `Bool` |
| `39` | `fn :: fmt is valid sig lhs [String]` | `Bool` |
| `40` | `fn :: fmt is valid bare sig lhs [String]` | `Bool` |
| `41` | `fn :: fmt is non sig head word String` | `Bool` |
| `42` | `fn :: fmt parse sig line String` | `FmtSig` |
| `43` | `fn :: fmt parse sig tokens Int String String [FmtToken]` | `FmtSig` |
| `44` | `fn :: fmt finish bare sig parse String String (Bool [String] String Int)` | `FmtSig` |
| `45` | `fn :: fmt finish sig parse String String String (Bool [String] String Int)` | `FmtSig` |
| `46` | `fn :: fmt append comment String String` | `String` |
| `47` | `fn :: fmt is top decl line String` | `Bool` |
| `48` | `fn :: fmt first tok is dcolon [FmtToken]` | `Bool` |
| `49` | `fn :: fmt first tok is upper [FmtToken]` | `Bool` |
| `50` | `fn :: fmt check bare sig split (Bool [String] String Int)` | `Bool` |
| `51` | `fn :: fmt has valid bare sig [FmtToken]` | `Bool` |
| `52` | `fn :: fmt is top decl toks Int String [FmtToken]` | `Bool` |
| `53` | `fn :: fmt op tokens match [String] [String]` | `Bool` |
| `54` | `fn :: fmt is bare kind String` | `Bool` |
| `55` | `fn :: fmt sig base col String` | `Int` |
| `56` | `fn :: fmt sig base col of FmtSig` | `Int` |
| `57` | `fn :: fmt clause matches sig String [String] [String]` | `Bool` |
| `58` | `fn :: fmt split clause eq [FmtToken] [String]` | `[String] Bool Int` |
| `59` | `fn :: fmt next nonblank is guard [String]` | `Bool` |
| `60` | `fn :: fmt check guard line String [String]` | `Bool` |
| `61` | `fn :: fmt parse clause line FmtSig String Bool` | `FmtClause` |
| `62` | `fn :: fmt parse clause clean String [String] String String String Bool` | `FmtClause` |
| `63` | `fn :: fmt check clause split String [String] String Bool ([String] Bool Int)` | `FmtClause` |
| `64` | `fn :: fmt build clause info String [String] Bool Int` | `FmtClause` |
| `65` | `fn :: fmt find whr arrow [FmtToken]` | `Int` |
| `66` | `fn :: fmt parse whr line String Bool` | `FmtWhereBind` |
| `67` | `fn :: fmt parse whr clean String String String` | `FmtWhereBind` |
| `68` | `fn :: fmt build whr bind String String Int` | `FmtWhereBind` |
| `69` | `fn :: fmt check whr nonempty String String` | `FmtWhereBind` |
| `70` | `fn :: fmt str lens [String]` | `[Int]` |
| `71` | `fn :: fmt slot width Int Int` | `Int` |
| `72` | `fn :: fmt max widths [Int] [String]` | `[Int]` |
| `73` | `fn :: fmt build col starts [Int] Int` | `[Int]` |
| `74` | `fn :: fmt end col [Int] Int` | `Int` |
| `75` | `fn :: fmt scan group widths FmtSig [String] [Int] Int Bool Int` | `[Int] Int` |
| `76` | `fn :: fmt scan group step FmtSig String [String] [Int] Int Bool Int FmtClause FmtWhereBind` | `[Int] Int` |
| `77` | `fn :: fmt compute group geometry FmtSig [String] FmtConfig` | `FmtSig` |
| `78` | `fn :: fmt count op params [String]` | `Int` |
| `79` | `fn :: fmt count sig params String [String]` | `Int` |
| `80` | `fn :: fmt finish group geometry String [String] String String ([Int] Int) FmtConfig` | `FmtSig` |
| `81` | `fn :: fmt select group geometry String [String] String String [Int] Int Int Int Int FmtConfig` | `FmtSig` |
| `82` | `fn :: fmt pad lhs tokens [String] [Int] Int String` | `String` |
| `83` | `fn :: fmt sig prefix String String` | `String` |
| `84` | `fn :: fmt format sig line FmtSig` | `String` |
| `85` | `fn :: fmt format clause line FmtSig [String] Bool String` | `String` |
| `86` | `fn :: fmt finish clause rhs String Bool String Int Int` | `String` |
| `87` | `fn :: fmt format whr line FmtSig String String Int` | `String` |
| `88` | `fn :: fmt line opens block String` | `Bool` |
| `89` | `fn :: fmt check block opener String Int` | `Bool` |
| `90` | `fn :: fmt line closes block String` | `Bool` |
| `91` | `fn :: fmt guard indent Int Int Int String Int` | `Int` |
| `92` | `fn :: fmt guard indent clean Int Int Int String String Int` | `Int` |
| `93` | `fn :: fmt format group body FmtSig [String] Int String Bool FmtConfig` | `[String]` |
| `94` | `fn :: fmt format group line FmtSig String String String Int [String] Int String Bool FmtConfig FmtClause FmtWhereBind` | `[String]` |
| `95` | `fn :: fmt format guard line FmtSig String Int [String] Int String FmtConfig Int` | `[String]` |
| `96` | `fn :: fmt next body indent Int String Int` | `Int` |
| `97` | `fn :: fmt next body indent clean Int String String Int` | `Int` |
| `98` | `fn :: fmt indent body line Int String String Int` | `String` |
| `99` | `fn :: fmt take group lines [String] [String]` | `[String] [String]` |
| `100` | `fn :: fmt format top lines [String] Int String FmtConfig` | `[String]` |
| `101` | `fn :: fmt dispatch top line String [String] Int String FmtConfig FmtSig` | `[String]` |
| `102` | `fn :: fmt run sig group FmtSig ([String] [String]) FmtConfig` | `[String]` |
| `103` | `fn :: fmt format non sig top String [String] Int String FmtConfig` | `[String]` |
| `104` | `fn :: fmt is digit Int` | `Bool` |
| `105` | `fn :: fmt is upper Int` | `Bool` |
| `106` | `fn :: fmt is lower Int` | `Bool` |
| `107` | `fn :: fmt is ident char Int` | `Bool` |
| `108` | `fn :: fmt is keyword String` | `Bool` |
| `109` | `fn :: fmt is logic op String` | `Bool` |
| `110` | `fn :: fmt is bool lit String` | `Bool` |
| `111` | `fn :: fmt classify word String Bool` | `String` |
| `112` | `fn :: fmt classify param word String` | `String` |
| `113` | `fn :: fmt escape html loop String Int Int String` | `String` |
| `114` | `fn :: fmt escape html String` | `String` |
| `115` | `fn :: fmt escape latex loop String Int Int String` | `String` |
| `116` | `fn :: fmt escape latex String` | `String` |
| `117` | `fn :: fmt escape rtf loop String Int Int String` | `String` |
| `118` | `fn :: fmt escape rtf String` | `String` |
| `119` | `fn :: fmt escape target String FmtTarget` | `String` |
| `120` | `fn :: fmt cat css class String` | `String` |
| `121` | `fn :: fmt cat ansi16 String` | `String` |
| `122` | `fn :: fmt cat rgb String FmtTheme` | `String` |
| `123` | `fn :: fmt cat hex String FmtTheme` | `String` |
| `124` | `fn :: fmt cat is bold String` | `Bool` |
| `125` | `fn :: fmt cat rtf idx String` | `String` |
| `126` | `fn :: fmt span css String String` | `String` |
| `127` | `fn :: fmt span tty String String` | `String` |
| `128` | `fn :: fmt span truecolor String String Bool` | `String` |
| `129` | `fn :: fmt span html inline String String Bool` | `String` |
| `130` | `fn :: fmt span pango String String Bool` | `String` |
| `131` | `fn :: fmt span latex String String Bool` | `String` |
| `132` | `fn :: fmt span rtf String String Bool` | `String` |
| `133` | `fn :: fmt render span String String FmtTarget FmtTheme` | `String` |
| `134` | `fn :: fmt scan ident end String Int Int` | `Int` |
| `135` | `fn :: fmt scan space end String Int Int` | `Int` |
| `136` | `fn :: fmt find close brace String Int Int` | `Int` |
| `137` | `fn :: fmt render nonempty String String FmtTarget FmtTheme` | `String` |
| `138` | `fn :: fmt highlight dquote brace String Int Int Int Int FmtTarget FmtTheme String` | `String` |
| `139` | `fn :: fmt highlight dquote loop String Int Int Int FmtTarget FmtTheme String` | `String` |
| `140` | `fn :: fmt multi op at String Int Int` | `String` |
| `141` | `fn :: fmt is single op Int` | `Bool` |
| `142` | `fn :: fmt comment cat String` | `String` |
| `143` | `fn :: fmt hl space step String Int Int Bool FmtTarget FmtTheme String Int` | `String` |
| `144` | `fn :: fmt hl dquote step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `145` | `fn :: fmt hl squote step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `146` | `fn :: fmt hl pragma step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `147` | `fn :: fmt hl mop step String Int Int FmtTarget FmtTheme String String` | `String` |
| `148` | `fn :: fmt hl ident step String Int Int Bool FmtTarget FmtTheme String Int` | `String` |
| `149` | `fn :: fmt highlight line loop String Int Int Bool FmtTarget FmtTheme String` | `String` |
| `150` | `fn :: fmt hl param ident step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `151` | `fn :: fmt highlight param loop String Int Int FmtTarget FmtTheme String` | `String` |
| `152` | `fn :: fmt highlight sig lhs tok String String FmtTarget FmtTheme` | `String` |
| `153` | `fn :: fmt highlight sig lhs loop String Int [String] [FmtToken] FmtTarget FmtTheme String` | `String` |
| `154` | `fn :: fmt highlight sig tokens String String [String] [FmtToken] FmtTarget FmtTheme` | `String` |
| `155` | `fn :: fmt highlight sig line String FmtSig FmtTarget FmtTheme` | `String` |
| `156` | `fn :: fmt highlight clause lhs tok String String FmtTarget FmtTheme` | `String` |
| `157` | `fn :: fmt highlight clause lhs loop String Int [String] [FmtToken] FmtTarget FmtTheme String` | `String` |
| `158` | `fn :: fmt highlight clause line String FmtSig FmtTarget FmtTheme` | `String` |
| `159` | `fn :: fmt tokens have eq [FmtToken]` | `Bool` |
| `160` | `fn :: fmt tok strs [FmtToken]` | `[String]` |
| `161` | `fn :: fmt is record update lhs [String]` | `Bool` |
| `162` | `fn :: fmt is bare clause tok String` | `Bool` |
| `163` | `fn :: fmt all bare clause toks [String]` | `Bool` |
| `164` | `fn :: fmt is bare clause lhs Int [String] Bool Bool` | `Bool` |
| `165` | `fn :: fmt highlight bare clause tok Int String FmtTarget FmtTheme` | `String` |
| `166` | `fn :: fmt highlight bare clause lhs loop String Int Int [String] [FmtToken] FmtTarget FmtTheme String` | `String` |
| `167` | `fn :: fmt highlight no sig tokens String Int [FmtToken] Bool FmtTarget FmtTheme` | `String` |
| `168` | `fn :: fmt highlight no sig clause split String Int [FmtToken] ([String] Bool Int) Bool FmtTarget FmtTheme` | `String` |
| `169` | `fn :: fmt highlight no sig clean String String String Bool FmtTarget FmtTheme` | `String` |
| `170` | `fn :: fmt highlight no sig line String Bool FmtTarget FmtTheme` | `String` |
| `171` | `fn :: fmt highlight line String FmtTarget FmtTheme` | `String` |
| `172` | `fn :: fmt highlight single line dispatch String FmtSig FmtTarget FmtTheme` | `String` |
| `173` | `fn :: fmt next active sig FmtSig String` | `FmtSig` |
| `174` | `fn :: fmt hl group by clause String FmtSig FmtClause Bool FmtTarget FmtTheme` | `String FmtSig` |
| `175` | `fn :: fmt hl group by sig String [String] FmtSig FmtSig FmtTarget FmtTheme` | `String FmtSig` |
| `176` | `fn :: fmt highlight line in group String [String] FmtSig FmtTarget FmtTheme` | `String FmtSig` |
| `177` | `fn :: fmt hl lines step (String FmtSig) [String] FmtTarget FmtTheme` | `[String]` |
| `178` | `fn :: fmt highlight lines with sig [String] FmtSig FmtTarget FmtTheme` | `[String]` |
| `179` | `fn :: fmt highlight lines [String] FmtTarget FmtTheme` | `[String]` |
| `180` | `fn :: fmt join rtf lines [String]` | `String` |
| `181` | `fn :: fmt html pre open FmtTheme` | `String` |
| `182` | `fn :: fmt rtf colortbl FmtTheme` | `String` |
| `183` | `fn :: fmt wrap target doc [String] FmtTarget FmtTheme` | `String` |
| `184` | `fn :: fmt html stylesheet FmtTheme` | `String` |
| `185` | `fn :: fmt source with config String FmtConfig` | `String` |
| `186` | `fn :: format ridgun source String` | `String` |
| `187` | `fn :: fmt to tty with theme String FmtTheme` | `String` |
| `188` | `fn :: fmt to tty String` | `String` |
| `189` | `fn :: fmt to truecolor with theme String FmtTheme` | `String` |
| `190` | `fn :: fmt to truecolor String` | `String` |
| `191` | `fn :: fmt to html with theme String FmtTheme` | `String` |
| `192` | `fn :: fmt to html String` | `String` |
| `193` | `fn :: fmt to html css String` | `String` |
| `194` | `fn :: fmt to markdown String` | `String` |
| `195` | `fn :: fmt to pango with theme String FmtTheme` | `String` |
| `196` | `fn :: fmt to pango String` | `String` |
| `197` | `fn :: fmt to latex with theme String FmtTheme` | `String` |
| `198` | `fn :: fmt to latex String` | `String` |
| `199` | `fn :: fmt to rtf with theme String FmtTheme` | `String` |
| `200` | `fn :: fmt to rtf String` | `String` |

---

## 15.3. Explorando a `fmt` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `fmt` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test fmt.ridgun`.

### 15.3.1. Exemplo 1: Fluxo principal em estilo tabular com `fmt`

Repare como em Ridgun os sinais `=` e os passos de transformação com `fmt` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import fmt

fn :: formatear y verificar String => String Bool
      formatear y verificar codigo =
        format ridgun source codigo -> limpio
        (limpio, (format ridgun source limpio) == limpio)
```

### 15.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `fmt` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 38 libs do `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html String => String
      exportar bloque html codigo =
        fmt to html css codigo
```

### 15.3.3. Exemplo 3: Alinhamento tabular canónico (`format ridgun source`, `fmt source with config`) de assinaturas `=>`, cláusulas `=`, ligações `->` e comentários `--`

Neste exemplo prático exploramos de forma exaustiva como a `fmt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test fmt canonical alignment and config => ()
      test fmt canonical alignment and config =
        nl = char from code 10
        raw_src = "fn :: add Int Int => Int" + nl + "add x y = x + y" + nl + "add 0 y_long = y_long" + nl
        expected_2d = "fn :: add Int Int    => Int" + nl + "      add x   y      =  x + y" + nl + "      add 0   y_long =  y_long" + nl
        out_2d = format ridgun source raw_src
        out_2d -> assert str eq expected_2d "AC1: canonical 2D tabular alignment"

        -- Unaligned config (`is_aligned = False`) uses single-space separation
        cfg_unaligned = fmt config 2 4 80 False FmtPlain FmtThemeNone
        out_unaligned = fmt source with config raw_src cfg_unaligned
        expected_unaligned = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "      add 0 y_long = y_long" + nl
        out_unaligned -> assert str eq expected_unaligned "AC1: unaligned FmtConfig"

        -- Guard and `where` alignment with custom indent_width = 4
        guard_src = "fn :: clamp Int => Int" + nl + "clamp x" + nl + "| x < 0 = 0" + nl + "| otherwise = x" + nl + "where" + nl + "lo -> 0" + nl
        cfg_ind4 = fmt config 4 4 80 True FmtPlain FmtThemeNone
        out_ind4 = fmt source with config guard_src cfg_ind4
        str contains out_ind4 "          | x < 0 = 0" -> assert true "AC1: custom indent_width = 4 guard indentation"
        str contains out_ind4 "              lo -> 0" -> assert true "AC1: custom indent_width = 4 where binding alignment"
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
        sample = "-- @implements FR-FMT-001" + nl + "-- comment line" + nl + "fn :: greet String => String" + nl + "greet name = \"Hello " + interp_tok + "\" + (int to str 0x2A)" + nl

        tty_dark = fmt to tty sample
        str contains tty_dark (esc + "[1;32m-- @implements FR-FMT-001" + esc + "[0m") -> assert true "AC2: TTY pragma highlight"
        str contains tty_dark (esc + "[90m-- comment line" + esc + "[0m") -> assert true "AC2: TTY comment highlight"
        str contains tty_dark (esc + "[1;35mfn" + esc + "[0m") -> assert true "AC2: TTY keyword highlight"
        str contains tty_dark (esc + "[1;34mgreet" + esc + "[0m") -> assert true "AC2: TTY function name highlight"
        str contains tty_dark (esc + "[33mString" + esc + "[0m") -> assert true "AC2: TTY type highlight"
        str contains tty_dark (esc + "[36m" + interp_tok + esc + "[0m") -> assert true "AC2: TTY string interpolation highlight"
        str contains tty_dark (esc + "[36m0x2A" + esc + "[0m") -> assert true "AC2: TTY hex number highlight"

        tty_none = fmt to tty with theme sample FmtThemeNone
        str contains tty_none esc -> assert false "AC2: FmtThemeNone emits no ANSI escape codes"

        tc_dark = fmt to truecolor sample
        str contains tc_dark (esc + "[1;38;2;198;120;221mfn" + esc + "[0m") -> assert true "AC2: TrueColor dark keyword RGB"
        str contains tc_dark (esc + "[1;38;2;97;175;239mgreet" + esc + "[0m") -> assert true "AC2: TrueColor dark function RGB"

        tc_light = fmt to truecolor with theme sample FmtThemeLight
        str contains tc_light (esc + "[1;38;2;166;38;164mfn" + esc + "[0m") -> assert true "AC2: TrueColor light keyword RGB"
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
        str starts with html_out "<pre class=\"ridgun-code\"" -> assert true "AC3: HTML inline wrapper"
        str contains html_out "<span style=\"color:#c678dd;font-weight:bold\">fn</span>" -> assert true "AC3: HTML inline keyword span"
        str contains html_out "&lt;" -> assert true "AC3: HTML escapes < operator"
        str contains html_out "&gt;" -> assert true "AC3: HTML escapes > operator"

        -- 2. CSS-class HTML + Stylesheet
        css_html = fmt to html css src
        str contains css_html "<span class=\"rg-kw\">fn</span>" -> assert true "AC3: HTML CSS keyword class"
        str contains css_html "<span class=\"rg-fn\">cmp</span>" -> assert true "AC3: HTML CSS function class"
        str contains css_html "<span class=\"rg-type\">Int</span>" -> assert true "AC3: HTML CSS type class"
        str contains css_html "<span class=\"rg-logic\">AND</span>" -> assert true "AC3: HTML CSS logic operator class"
        sheet_dark = fmt html stylesheet FmtThemeDark
        sheet_light = fmt html stylesheet FmtThemeLight
        str contains sheet_dark ".ridgun-kw" -> assert true "AC3: Dark CSS stylesheet"
        str contains sheet_light "#fafafa" -> assert true "AC3: Light CSS stylesheet"

        -- 3. Markdown
        md_out = fmt to markdown src
        str starts with md_out ("```ridgun" + nl) -> assert true "AC3: Markdown fenced code block"

        -- 4. Pango Markup
        pango_out = fmt to pango src
        str starts with pango_out ("<tt>" + nl) -> assert true "AC3: Pango <tt> wrapper"
        str contains pango_out "<span foreground=\"#c678dd\" weight=\"bold\">fn</span>" -> assert true "AC3: Pango span markup"

        -- 5. LaTeX Verbatim
        latex_out = fmt to latex src
        str contains latex_out "Verbatim" -> assert true "AC3: LaTeX Verbatim environment"
        str contains latex_out "textcolor[HTML]" -> assert true "AC3: LaTeX textcolor macro"

        -- 6. RTF
        rtf_out = fmt to rtf src
        str contains rtf_out "rtf1" -> assert true "AC3: RTF header"
        str contains rtf_out "colortbl" -> assert true "AC3: RTF color table"
        str contains rtf_out "\\cf1\\b fn" -> assert true "AC3: RTF bold color span"
        ()
```

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

### 15.3.6. Exemplo 6: Realce sensível à assinatura das declarações `fn ::` e `op ::` e palavras-chave contextuais

Neste exemplo prático exploramos de forma exaustiva como a `fmt` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test fmt signature aware fn and op highlighting => ()
      test fmt signature aware fn and op highlighting =
        nl = char from code 10
        fn_src = "fn :: copy to with otherwise String Int => String" + nl + "copy to with otherwise src opt = copy src" + nl
        fn_css = fmt to html css fn_src
        str contains fn_css "<span class=\"rg-fn\">copy</span> <span class=\"rg-fn\">to</span> <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">otherwise</span> <span class=\"rg-type\">String</span> <span class=\"rg-type\">Int</span>" -> assert true "AC2/AC3: fn :: highlights keyword-named fn words as rg-fn and types as rg-type"
        str contains fn_css "      <span class=\"rg-fn\">copy</span> <span class=\"rg-fn\">to</span> <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">otherwise</span> src    opt <span class=\"rg-op\">=</span>  copy src" -> assert true "AC2/AC3: fn = clause highlights fn words as rg-fn, parameters as plain, and RHS invocation as non-rg-fn"
        str contains fn_css "<span class=\"rg-fn\">src</span>" -> assert false "AC2/AC3: fn = clause parameter src is not highlighted as rg-fn"
        str contains fn_css "<span class=\"rg-kw\">otherwise</span>" -> assert false "AC2/AC3: otherwise inside fn declaration/definition is not highlighted as rg-kw"
        str contains fn_css "<span class=\"rg-kw\">with</span>" -> assert false "AC2/AC3: with inside fn declaration/definition is not highlighted as rg-kw"
        str contains fn_css "<span class=\"rg-kw\">to</span>" -> assert false "AC2/AC3: to inside fn declaration/definition is not highlighted as rg-kw"

        op_src = "op :: Int unwrap or Int with to Int => Int" + nl + "a unwrap or b with to c = a + b + c" + nl
        op_css = fmt to html css op_src
        str contains op_css "<span class=\"rg-type\">Int</span> <span class=\"rg-fn\">unwrap</span> <span class=\"rg-fn\">or</span> <span class=\"rg-type\">Int</span> <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">to</span> <span class=\"rg-type\">Int</span>" -> assert true "AC2/AC3: op :: highlights mixfix op words (or, with, to) as rg-fn and parameter types as rg-type"
        str contains op_css "      a   <span class=\"rg-fn\">unwrap</span> <span class=\"rg-fn\">or</span> b   <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">to</span> c   <span class=\"rg-op\">=</span>" -> assert true "AC2/AC3: op = clause highlights mixfix op words as rg-fn and interleaved parameter slots (a, b, c) as plain"
        str contains op_css "<span class=\"rg-logic\">or</span>" -> assert false "AC2/AC3: or inside op declaration/definition is not highlighted as rg-logic"

        -- Bare declarations without fn :: / op :: prefix (unindented and indented)
        bare_swap = "swap A with B => (B, A)" + nl + "swap x with y =  (y, x)" + nl
        bare_swap_css = fmt to html css bare_swap
        str contains bare_swap_css "<span class=\"rg-fn\">swap</span> <span class=\"rg-type\">A</span> <span class=\"rg-fn\">with</span> <span class=\"rg-type\">B</span>" -> assert true "AC2/AC3: bare op signature highlights swap and with as rg-fn"
        str contains bare_swap_css "<span class=\"rg-fn\">swap</span> x <span class=\"rg-fn\">with</span> y <span class=\"rg-op\">=</span>" -> assert true "AC2/AC3: bare op clause highlights swap and with as rg-fn and parameters x, y as plain"
        str contains bare_swap_css "<span class=\"rg-kw\">with</span>" -> assert false "AC2/AC3: with in bare op signature/clause is not highlighted as rg-kw"

        ind_swap = fmt join lines (fmt highlight lines ["  swap A with B => (B, A)", "  swap x with y =  (y, x)"] FmtHtmlCss FmtThemeDark)
        str contains ind_swap "<span class=\"rg-fn\">swap</span> <span class=\"rg-type\">A</span> <span class=\"rg-fn\">with</span> <span class=\"rg-type\">B</span>" -> assert true "AC2/AC3: indented bare op signature highlights swap and with as rg-fn"
        str contains ind_swap "<span class=\"rg-fn\">swap</span> x <span class=\"rg-fn\">with</span> y <span class=\"rg-op\">=</span>" -> assert true "AC2/AC3: indented bare op clause highlights swap and with as rg-fn"

        -- Clause parameter slots in bigger a b = ... (both with signature, without signature, and via fmt highlight line)
        bigger_hl = fmt highlight line "      bigger a   b   =  a" FmtHtmlCss FmtThemeDark
        str contains bigger_hl "<span class=\"rg-fn\">bigger</span> a   b   <span class=\"rg-op\">=</span>" -> assert true "AC2/AC3: fmt highlight line highlights bigger as rg-fn and parameters a, b as plain"
        str contains bigger_hl "<span class=\"rg-fn\">a</span>" -> assert false "AC2/AC3: parameter a is not highlighted as rg-fn"
        str contains bigger_hl "<span class=\"rg-fn\">b</span>" -> assert false "AC2/AC3: parameter b is not highlighted as rg-fn"

        nosig_bigger = fmt to html css ("bigger a b =" + nl + "  | a > b = a" + nl + "  | otherwise = b" + nl)
        str contains nosig_bigger "<span class=\"rg-fn\">bigger</span> a b <span class=\"rg-op\">=</span>" -> assert true "AC2/AC3: signature-less clause highlights bigger as rg-fn and parameters a, b as plain"

        -- Record update with and agent send/to/receive/from remain keywords, and where is not a keyword
        kw_expr = fmt to html css ("  c with tls: True" + nl + "  send msg to worker" + nl + "  receive from worker -> reply" + nl + "  where_var = where" + nl)
        str contains kw_expr "c <span class=\"rg-kw\">with</span> tls:" -> assert true "AC2/AC3: with in record update remains rg-kw"
        str contains kw_expr "<span class=\"rg-kw\">send</span> msg <span class=\"rg-kw\">to</span> worker" -> assert true "AC2/AC3: send and to remain rg-kw in expressions"
        str contains kw_expr "<span class=\"rg-kw\">receive</span> <span class=\"rg-kw\">from</span> worker" -> assert true "AC2/AC3: receive and from remain rg-kw in expressions"
        str contains kw_expr "<span class=\"rg-kw\">where</span>" -> assert false "AC2/AC3: where is not a reserved keyword in Ridgun"
        ()
```

---

## 15.4. Debaixo do capô: como a `fmt` é construída em Ridgun puro (`src/main/ridgun/lib/fmt.ridgun`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/fmt.ridgun` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 15.4.1. Implementação interna: Configuration Constructors

Observe como `fmt.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: fmt

fn :: default fmt config => FmtConfig
      default fmt config =  FmtConfig 2 4 80 True FmtPlain FmtThemeNone

fn :: fmt config Int Int Int Bool FmtTarget FmtTheme => FmtConfig
      fmt config indent_w max_params max_w aligned target theme =
        FmtConfig (fmt max 1 indent_w) (fmt max 0 max_params) (fmt max 20 max_w) aligned target theme
```

### 15.4.2. Implementação interna: Signature Parsing (`fn ::` / `op ::`)

Observe como `fmt.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: fmt split sig arrow [FmtToken] [String] => Bool [String] String Int
      fmt split sig arrow [] _ = (False, [], "", 0)
      fmt split sig arrow ((FmtTok tok col):rest) lhs_acc =
        | tok == "=>" or tok == "->" = (True, lhs_acc, tok, col)
        | otherwise = fmt split sig arrow rest (lhs_acc :: [tok])

fn :: fmt is sig type tok String => Bool
      fmt is sig type tok "" = False
      fmt is sig type tok tok =
        ch = str char at tok 0
        (ch >= 65 and ch <= 90) or ch == 91 or ch == 40

fn :: fmt all type toks [String] => Bool
      fmt all type toks []       =  True
      fmt all type toks (t:rest) =
        | fmt is sig type tok t = fmt all type toks rest
        | otherwise = False

fn :: fmt is bare fn lhs [String] => Bool
      fmt is bare fn lhs [] = False
      fmt is bare fn lhs (first_w:rest) =
        | not (fmt is sig type tok first_w) = fmt all type toks rest
        | otherwise = False

fn :: fmt infer bare kind [String] => String
      fmt infer bare kind lhs_strs =
        | fmt is bare fn lhs lhs_strs = "bare_fn"
        | otherwise = "bare_op"

fn :: fmt is valid sig name tok String => Bool
      fmt is valid sig name tok "" = False
      fmt is valid sig name tok tok =
        ch = str char at tok 0
        tok != "=" and tok != "->" and tok != "<-" and tok != ":" and tok != "::" and ch != 34 and ch != 39 and ch != 124 and (not (fmt is digit ch))

fn :: fmt is valid sig lhs [String] => Bool
      fmt is valid sig lhs [] = True
      fmt is valid sig lhs (t:rest) =
        | (fmt is sig type tok t) or (fmt is valid sig name tok t) = fmt is valid sig lhs rest
        | otherwise = False

fn :: fmt is valid bare sig lhs [String] => Bool
      fmt is valid bare sig lhs lhs_strs =
        lhs_strs != [] and (fmt is valid sig lhs lhs_strs) and (not (fmt all type toks lhs_strs))

fn :: fmt is non sig head word String => Bool
      fmt is non sig head word w =
        w == "type" or w == "expand" or w == "import" or w == "module" or w == "global" or w == "context" or w == "shared" or w == "hardware" or (str starts with w "@") or (str starts with w "--") or (str starts with w "|")

fn :: fmt parse sig line String => FmtSig
      fmt parse sig line line   =
        line fmt strip comment -> clean
        line fmt extract comment -> cmt
        clean fmt scan tokens -> toks
        fmt parse sig tokens (fmt leading indent line) clean cmt toks

fn :: fmt parse sig tokens Int String String [FmtToken] => FmtSig
      fmt parse sig tokens _ clean cmt ((FmtTok kind _):(FmtTok "::" _):rest) =
        | kind == "fn" or kind == "op" = fmt finish sig parse clean cmt kind (fmt split sig arrow rest [])
        | otherwise = NoSig
      fmt parse sig tokens _ clean cmt ((FmtTok w col):rest) =
        | fmt is non sig head word w = NoSig
        | otherwise = fmt finish bare sig parse clean cmt (fmt split sig arrow ([FmtTok w col] :: rest) [])
      fmt parse sig tokens _ _ _ _ = NoSig

fn :: fmt finish bare sig parse String String (Bool [String] String Int) => FmtSig
      fmt finish bare sig parse _ _ (False, _, _, _) = NoSig
      fmt finish bare sig parse _ _ (True, [], _, _) = NoSig
      fmt finish bare sig parse clean cmt (True, lhs_strs, arrow_s, arrow_col) =
        | arrow_s == "=>" and (fmt is valid bare sig lhs lhs_strs) = fmt finish sig parse clean cmt (fmt infer bare kind lhs_strs) (True, lhs_strs, arrow_s, arrow_col)
        | otherwise = NoSig

fn :: fmt finish sig parse String String String (Bool [String] String Int) => FmtSig
      fmt finish sig parse _ _ _ (False, _, _, _) = NoSig
      fmt finish sig parse _ _ _ (True, [], _, _) = NoSig
      fmt finish sig parse clean cmt kind (True, lhs_strs, arrow_s, arrow_col) =
        ret_start = arrow_col + (str len arrow_s)
        ret_core = fmt trim (str slice clean ret_start (str len clean))
        ret_full = fmt append comment ret_core cmt
        SigInfo kind lhs_strs arrow_s ret_full [] 0 0

fn :: fmt append comment String String => String
      fmt append comment core   ""     =  core
      fmt append comment ""     cmt    =  cmt
      fmt append comment core   cmt    =  core + " " + cmt
```

### 15.4.3. Implementação interna: Lexical Token Classification & Syntax Highlighting

Observe como `fmt.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: fmt is digit Int => Bool
      fmt is digit c   =  c >= 48 and c <= 57

fn :: fmt is upper Int => Bool
      fmt is upper c   =  c >= 65 and c <= 90

fn :: fmt is lower Int => Bool
      fmt is lower c   =  c >= 97 and c <= 122

fn :: fmt is ident char Int => Bool
      fmt is ident char c   =  (fmt is upper c) or (fmt is lower c) or (fmt is digit c) or c == 95

fn :: fmt is keyword String => Bool
      fmt is keyword w      =
        w == "fn" or w == "op" or w == "type" or w == "expand" or w == "import" or w == "module" or w == "otherwise" or w == "with" or w == "do" or w == "mut" or w == "in" or w == "agent" or w == "send" or w == "to" or w == "receive" or w == "from" or w == "try" or w == "stop" or w == "timeout" or w == "global" or w == "context" or w == "shared" or w == "hardware" or w == "atomic" or w == "region" or w == "limit" or w == "map" or w == "filter" or w == "fold"

fn :: fmt is logic op String => Bool
      fmt is logic op w      =
        w == "AND" or w == "OR" or w == "XOR" or w == "NOT" or w == "and" or w == "or" or w == "xor" or w == "not" or w == "shl" or w == "shr" or w == "rotr" or w == "rotl"

fn :: fmt is bool lit String => Bool
      fmt is bool lit w      =  w == "True" or w == "False"

fn :: fmt classify word String Bool  => String
      fmt classify word ""     _     =  "plain"
      fmt classify word w      in_fn =
        | in_fn and (not (fmt is upper (str char at w 0))) and (not (fmt is digit (str char at w 0))) = "function"
        | fmt is keyword w = "keyword"
        | fmt is logic op w = "logic"
        | fmt is bool lit w = "bool"
        | fmt is upper (str char at w 0) = "type"
        | fmt is digit (str char at w 0) = "number"
        | otherwise = "plain"

fn :: fmt classify param word String => String
      fmt classify param word ""     =  "plain"
      fmt classify param word w      =
        | fmt is bool lit w = "bool"
        | fmt is upper (str char at w 0) = "type"
        | fmt is digit (str char at w 0) = "number"
        | otherwise = "plain"
```

### 15.4.4. Implementação interna: Public Entry Points

Observe como `fmt.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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
      format ridgun source src    =  fmt source with config src (default fmt config)

fn :: fmt to tty with theme String FmtTheme => String
      fmt to tty with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtTty theme)

fn :: fmt to tty String => String
      fmt to tty src    =  fmt to tty with theme src FmtThemeDark

fn :: fmt to truecolor with theme String FmtTheme => String
      fmt to truecolor with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtTrueColor theme)

fn :: fmt to truecolor String => String
      fmt to truecolor src    =  fmt to truecolor with theme src FmtThemeDark

fn :: fmt to html with theme String FmtTheme => String
      fmt to html with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtHtmlInline theme)

fn :: fmt to html String => String
      fmt to html src    =  fmt to html with theme src FmtThemeDark

fn :: fmt to html css String => String
      fmt to html css src    =
        fmt source with config src (FmtConfig 2 4 80 True FmtHtmlCss FmtThemeDark)

fn :: fmt to markdown String => String
      fmt to markdown src    =
        fmt source with config src (FmtConfig 2 4 80 True FmtMarkdown FmtThemeNone)

fn :: fmt to pango with theme String FmtTheme => String
      fmt to pango with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtPango theme)

fn :: fmt to pango String => String
      fmt to pango src    =  fmt to pango with theme src FmtThemeDark

fn :: fmt to latex with theme String FmtTheme => String
      fmt to latex with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtLatex theme)

fn :: fmt to latex String => String
      fmt to latex src    =  fmt to latex with theme src FmtThemeDark

fn :: fmt to rtf with theme String FmtTheme => String
      fmt to rtf with theme src theme =
        fmt source with config src (FmtConfig 2 4 80 True FmtRtf theme)

fn :: fmt to rtf String => String
      fmt to rtf src    =  fmt to rtf with theme src FmtThemeDark
```

---

## 15.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `fmt`

- **Garantia algorítmica e de segurança**: Idempotência estrita (`fmt source (fmt source s) == fmt source s`) e preservação de 100 % dos tokens semânticos.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/fmt.ridgun` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test fmt.ridgun`.

### As 5 Regras de Ouro ao programar com a `fmt`

1. **Declare `import fmt` no início do ficheiro** e chame as suas funções com espaços, tal como estão declaradas, para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `fmt` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `fmt` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `fmt` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 16** passaremos a explorar em profundidade a lib **`cli`** (A lib `cli` — Flags, Opções, Barreira `--`, Subcomandos e Variáveis de Ambiente).
