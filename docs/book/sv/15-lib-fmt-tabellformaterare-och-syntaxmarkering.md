# Kapitel 15: Lib:en `fmt` — Kanonisk 2D-tabellformaterare och Syntaxmarkering för 9 Målformat

## 15.1. Varför finns lib:en `fmt`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `fmt`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `fmt`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: skönheten i Ridgun-kod ligger i dess perfekt justerade tabellkolumner (`::`, `=`, `|`, `->`, `--`), men att justera mellanslag för hand eller exportera färgkodad syntax till terminal, HTML och LaTeX är tidsödande.

Lib:en **`fmt`** är Ridguns officiella 2D-tabellformaterare och syntaxmarkerare: den justerar `fn ::`-signaturer, ekvationer, `|`-vakter och `--`-kommentarer samt exporterar till **9 målformat** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`FMT`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`fmt`** (`src/main/ridgun/lib/fmt.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import fmt` (eller `import fmt as alias`) överst i filen**: varje lib definierar sin `module :: fmt`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `fmt` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 15.2. Inbyggda artefakter, import och komplett API-katalog för `fmt`

I `ridgun-libs` är **`fmt`** en förstklassig **lib** placerad i `src/main/ridgun/lib/fmt.rg` (domän `FMT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/fmt.rglib` | Portabel distribution och direkt import med `import fmt` |
| **Kompilerat arkiv** | `target/fmt.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libfmt.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: fmt`: skriv bara `import fmt` (eller `import fmt as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 15.2.1. Översikt över funktionella familjer i `fmt`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `fmt source / fmt source with` | Formaterar Ridgun-källkod med kanonisk 2D-tabelljustering |
| `fmt check` | Returnerar `True` om källkoden redan följer kanonisk `fmt source`-layout |
| `fmt render / fmt render with` | Formaterar och syntaxmarkerar källkod till valfritt av de 9 `FmtTarget`-målen |
| `fmt tokenize line` | Tokeniserar en rad till `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

### 15.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/fmt.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/fmt.rg` (`7` typer, `0` operatorer och `166` funktioner):

**Algebraiska datatyper och poster (`type`) i `fmt`:**

```ridgun
type FmtTarget = FmtPlain | FmtTty | FmtTrueColor | FmtHtmlInline | FmtHtmlCss | FmtMarkdown | FmtPango | FmtLatex | FmtRtf
type FmtTheme = FmtThemeNone | FmtThemeDark | FmtThemeLight
type FmtConfig = indent_width: Int, max_align_params: Int, max_line_width: Int, is_aligned: Bool, target_format: FmtTarget, color_theme: FmtTheme
type FmtToken = FmtTok String Int
type FmtSig = NoSig | SigInfo String [String] String String [Int] Int Int
type FmtClause = NoClause | ClauseInfo [String] Bool String
type FmtWhereBind = NoWhereBind | WhereBindInfo String String
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: default fmt config` | `FmtConfig` |
| `2` | `fn :: fmt config Int Int Int Bool FmtTarget FmtTheme` | `FmtConfig` |
| `3` | `fn :: fmt_max Int Int` | `Int` |
| `4` | `fn :: fmt_str_list_len [String]` | `Int` |
| `5` | `fn :: fmt_str_head [String]` | `String` |
| `6` | `fn :: fmt_int_at [Int] Int` | `Int` |
| `7` | `fn :: fmt_spaces Int` | `String` |
| `8` | `fn :: fmt_is_hspace Int` | `Bool` |
| `9` | `fn :: fmt_leading_indent_loop String Int Int` | `Int` |
| `10` | `fn :: fmt_leading_indent String` | `Int` |
| `11` | `fn :: fmt_trim_left_loop String Int Int` | `String` |
| `12` | `fn :: fmt_trim_left String` | `String` |
| `13` | `fn :: fmt_trim_right_loop String Int` | `String` |
| `14` | `fn :: fmt_trim_right String` | `String` |
| `15` | `fn :: fmt_trim String` | `String` |
| `16` | `fn :: fmt_split_raw_lines_loop String Int Int Int Int [String]` | `[String]` |
| `17` | `fn :: fmt_split_raw_lines String` | `[String]` |
| `18` | `fn :: fmt_join_lines [String]` | `String` |
| `19` | `fn :: fmt_skip_quoted String Int Int Int` | `Int` |
| `20` | `fn :: fmt_find_comment_col String Int Int` | `Int` |
| `21` | `fn :: fmt_strip_comment String` | `String` |
| `22` | `fn :: fmt_strip_comment_at String Int` | `String` |
| `23` | `fn :: fmt_extract_comment String` | `String` |
| `24` | `fn :: fmt_extract_comment_at String Int` | `String` |
| `25` | `fn :: fmt_skip_hspace String Int Int` | `Int` |
| `26` | `fn :: fmt_scan_group_end String Int Int Int` | `Int` |
| `27` | `fn :: fmt_scan_word_end String Int Int Int` | `Int` |
| `28` | `fn :: fmt_scan_token_end String Int Int Int` | `Int` |
| `29` | `fn :: fmt_scan_tokens_loop String Int Int [FmtToken]` | `[FmtToken]` |
| `30` | `fn :: fmt_scan_tokens_at String Int Int [FmtToken]` | `[FmtToken]` |
| `31` | `fn :: fmt_scan_tokens_at_step String Int Int [FmtToken] Int` | `[FmtToken]` |
| `32` | `fn :: fmt_scan_tokens String` | `[FmtToken]` |
| `33` | `fn :: fmt_split_sig_arrow [FmtToken] [String]` | `(Bool, [String], String, Int)` |
| `34` | `fn :: fmt_is_sig_type_tok String` | `Bool` |
| `35` | `fn :: fmt_all_type_toks [String]` | `Bool` |
| `36` | `fn :: fmt_is_bare_fn_lhs [String]` | `Bool` |
| `37` | `fn :: fmt_infer_bare_kind [String]` | `String` |
| `38` | `fn :: fmt_parse_sig_line String` | `FmtSig` |
| `39` | `fn :: fmt_parse_sig_tokens Int String String [FmtToken]` | `FmtSig` |
| `40` | `fn :: fmt_finish_bare_sig_parse String String (Bool, [String], String, Int)` | `FmtSig` |
| `41` | `fn :: fmt_finish_sig_parse String String String (Bool, [String], String, Int)` | `FmtSig` |
| `42` | `fn :: fmt_append_comment String String` | `String` |
| `43` | `fn :: fmt_has_fat_arrow [FmtToken]` | `Bool` |
| `44` | `fn :: fmt_is_top_decl_line String` | `Bool` |
| `45` | `fn :: fmt_is_top_decl_toks Int String [FmtToken]` | `Bool` |
| `46` | `fn :: fmt_op_tokens_match [String] [String]` | `Bool` |
| `47` | `fn :: fmt_is_bare_kind String` | `Bool` |
| `48` | `fn :: fmt_sig_base_col String` | `Int` |
| `49` | `fn :: fmt_sig_base_col_from FmtSig` | `Int` |
| `50` | `fn :: fmt_clause_matches_sig String [String] [String]` | `Bool` |
| `51` | `fn :: fmt_split_clause_eq [FmtToken] [String]` | `([String], Bool, Int)` |
| `52` | `fn :: fmt_next_nonblank_is_guard [String]` | `Bool` |
| `53` | `fn :: fmt_check_guard_line String [String]` | `Bool` |
| `54` | `fn :: fmt_parse_clause_line FmtSig String Bool` | `FmtClause` |
| `55` | `fn :: fmt_parse_clause_clean String [String] String String String Bool` | `FmtClause` |
| `56` | `fn :: fmt_check_clause_split String [String] String Bool ([String], Bool, Int)` | `FmtClause` |
| `57` | `fn :: fmt_build_clause_info String [String] Bool Int` | `FmtClause` |
| `58` | `fn :: fmt_find_where_arrow [FmtToken]` | `Int` |
| `59` | `fn :: fmt_parse_where_line String Bool` | `FmtWhereBind` |
| `60` | `fn :: fmt_parse_where_clean String String String` | `FmtWhereBind` |
| `61` | `fn :: fmt_build_where_bind String String Int` | `FmtWhereBind` |
| `62` | `fn :: fmt_check_where_nonempty String String` | `FmtWhereBind` |
| `63` | `fn :: fmt_map_str_lens [String]` | `[Int]` |
| `64` | `fn :: fmt_slot_width Int Int` | `Int` |
| `65` | `fn :: fmt_max_widths [Int] [String]` | `[Int]` |
| `66` | `fn :: fmt_build_col_starts [Int] Int` | `[Int]` |
| `67` | `fn :: fmt_end_col [Int] Int` | `Int` |
| `68` | `fn :: fmt_scan_group_widths FmtSig [String] [Int] Int Bool Int` | `([Int], Int)` |
| `69` | `fn :: fmt_scan_group_step FmtSig String [String] [Int] Int Bool Int FmtClause FmtWhereBind` | `([Int], Int)` |
| `70` | `fn :: fmt_compute_group_geometry FmtSig [String] FmtConfig` | `FmtSig` |
| `71` | `fn :: fmt_count_op_params [String]` | `Int` |
| `72` | `fn :: fmt_count_sig_params String [String]` | `Int` |
| `73` | `fn :: fmt_finish_group_geometry String [String] String String ([Int], Int) FmtConfig` | `FmtSig` |
| `74` | `fn :: fmt_select_group_geometry String [String] String String [Int] Int Int Int Int FmtConfig` | `FmtSig` |
| `75` | `fn :: fmt_pad_lhs_tokens [String] [Int] Int String` | `String` |
| `76` | `fn :: fmt_sig_prefix String String` | `String` |
| `77` | `fn :: fmt_format_sig_line FmtSig` | `String` |
| `78` | `fn :: fmt_format_clause_line FmtSig [String] Bool String` | `String` |
| `79` | `fn :: fmt_finish_clause_rhs String Bool String Int Int` | `String` |
| `80` | `fn :: fmt_format_where_line FmtSig String String Int` | `String` |
| `81` | `fn :: fmt_line_opens_block String` | `Bool` |
| `82` | `fn :: fmt_check_block_opener String Int` | `Bool` |
| `83` | `fn :: fmt_line_closes_block String` | `Bool` |
| `84` | `fn :: fmt_guard_indent Int Int Int String Int` | `Int` |
| `85` | `fn :: fmt_guard_indent_clean Int Int Int String String Int` | `Int` |
| `86` | `fn :: fmt_format_group_body FmtSig [String] Int String Bool FmtConfig` | `[String]` |
| `87` | `fn :: fmt_format_group_line FmtSig String String String Int [String] Int String Bool FmtConfig FmtClause FmtWhereBind` | `[String]` |
| `88` | `fn :: fmt_format_guard_line FmtSig String Int [String] Int String FmtConfig Int` | `[String]` |
| `89` | `fn :: fmt_next_body_indent Int String Int` | `Int` |
| `90` | `fn :: fmt_next_body_indent_clean Int String String Int` | `Int` |
| `91` | `fn :: fmt_indent_body_line Int String String Int` | `String` |
| `92` | `fn :: fmt_take_group_lines [String] [String]` | `([String], [String])` |
| `93` | `fn :: fmt_format_top_lines [String] Int String FmtConfig` | `[String]` |
| `94` | `fn :: fmt_dispatch_top_line String [String] Int String FmtConfig FmtSig` | `[String]` |
| `95` | `fn :: fmt_run_sig_group FmtSig ([String], [String]) FmtConfig` | `[String]` |
| `96` | `fn :: fmt_format_non_sig_top String [String] Int String FmtConfig` | `[String]` |
| `97` | `fn :: fmt_is_digit Int` | `Bool` |
| `98` | `fn :: fmt_is_upper Int` | `Bool` |
| `99` | `fn :: fmt_is_lower Int` | `Bool` |
| `100` | `fn :: fmt_is_ident_char Int` | `Bool` |
| `101` | `fn :: fmt_is_keyword String` | `Bool` |
| `102` | `fn :: fmt_is_logic_op String` | `Bool` |
| `103` | `fn :: fmt_is_bool_lit String` | `Bool` |
| `104` | `fn :: fmt_classify_word String Bool` | `String` |
| `105` | `fn :: fmt_escape_html_loop String Int Int String` | `String` |
| `106` | `fn :: fmt_escape_html String` | `String` |
| `107` | `fn :: fmt_escape_latex_loop String Int Int String` | `String` |
| `108` | `fn :: fmt_escape_latex String` | `String` |
| `109` | `fn :: fmt_escape_rtf_loop String Int Int String` | `String` |
| `110` | `fn :: fmt_escape_rtf String` | `String` |
| `111` | `fn :: fmt_escape_for_target String FmtTarget` | `String` |
| `112` | `fn :: fmt_cat_css_class String` | `String` |
| `113` | `fn :: fmt_cat_ansi16 String` | `String` |
| `114` | `fn :: fmt_cat_rgb String FmtTheme` | `String` |
| `115` | `fn :: fmt_cat_hex String FmtTheme` | `String` |
| `116` | `fn :: fmt_cat_is_bold String` | `Bool` |
| `117` | `fn :: fmt_cat_rtf_idx String` | `String` |
| `118` | `fn :: fmt_span_css String String` | `String` |
| `119` | `fn :: fmt_span_tty String String` | `String` |
| `120` | `fn :: fmt_span_truecolor String String Bool` | `String` |
| `121` | `fn :: fmt_span_html_inline String String Bool` | `String` |
| `122` | `fn :: fmt_span_pango String String Bool` | `String` |
| `123` | `fn :: fmt_span_latex String String Bool` | `String` |
| `124` | `fn :: fmt_span_rtf String String Bool` | `String` |
| `125` | `fn :: fmt_render_span String String FmtTarget FmtTheme` | `String` |
| `126` | `fn :: fmt_scan_ident_end String Int Int` | `Int` |
| `127` | `fn :: fmt_scan_space_end String Int Int` | `Int` |
| `128` | `fn :: fmt_find_close_brace String Int Int` | `Int` |
| `129` | `fn :: fmt_render_nonempty String String FmtTarget FmtTheme` | `String` |
| `130` | `fn :: fmt_highlight_dquote_brace String Int Int Int Int FmtTarget FmtTheme String` | `String` |
| `131` | `fn :: fmt_highlight_dquote_loop String Int Int Int FmtTarget FmtTheme String` | `String` |
| `132` | `fn :: fmt_multi_op_at String Int Int` | `String` |
| `133` | `fn :: fmt_is_single_op Int` | `Bool` |
| `134` | `fn :: fmt_comment_cat String` | `String` |
| `135` | `fn :: fmt_hl_space_step String Int Int Bool FmtTarget FmtTheme String Int` | `String` |
| `136` | `fn :: fmt_hl_dquote_step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `137` | `fn :: fmt_hl_squote_step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `138` | `fn :: fmt_hl_pragma_step String Int Int FmtTarget FmtTheme String Int` | `String` |
| `139` | `fn :: fmt_hl_mop_step String Int Int FmtTarget FmtTheme String String` | `String` |
| `140` | `fn :: fmt_hl_ident_step String Int Int Bool FmtTarget FmtTheme String Int` | `String` |
| `141` | `fn :: fmt_highlight_line_loop String Int Int Bool FmtTarget FmtTheme String` | `String` |
| `142` | `fn :: fmt_line_starts_clause String` | `Bool` |
| `143` | `fn :: fmt_map_tok_strs [FmtToken]` | `[String]` |
| `144` | `fn :: fmt highlight line String FmtTarget FmtTheme` | `String` |
| `145` | `fn :: fmt_highlight_lines [String] FmtTarget FmtTheme` | `[String]` |
| `146` | `fn :: fmt_join_rtf_lines [String]` | `String` |
| `147` | `fn :: fmt_html_pre_open FmtTheme` | `String` |
| `148` | `fn :: fmt_rtf_colortbl FmtTheme` | `String` |
| `149` | `fn :: fmt_wrap_target_doc [String] FmtTarget FmtTheme` | `String` |
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

## 15.3. Djupdykning i `fmt`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `fmt` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test fmt.rg`.

### 15.3.1. Exempel 1: Huvudflöde i tabellform med `fmt`

Lägg märke till hur `=`-tecknen och transformationsstegen med `fmt` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import fmt

fn :: formatear y verificar String => String Bool
      formatear y verificar codigo =
        codigo fmt ridgun -> limpio
        limpio fmt check ridgun -> es_ok
        (limpio, es_ok)
```

### 15.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `fmt` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html String => String
      exportar bloque html codigo =
        fmt highlight ridgun codigo FmtHtmlCss
```

### 15.3.3. Exempel 3: Kanonisk tabelljustering (`fmt ridgun`, `fmt ridgun with`) av `=>`-signaturer, `=`-klausuler, `->`-bindningar och `--`-kommentarer

I detta praktiska exempel undersöker vi grundligt hur `fmt` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 15.3.4. Exempel 4: Lexikalisk färgkodning i 16-färgers ANSI och 24-bitars TrueColor med automatisk TTY- och `NO_COLOR`-detektering

I detta praktiska exempel undersöker vi grundligt hur `fmt` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 15.3.5. Exempel 5: Exportering av färgkodade dokument till HTML5 (`<pre><code>`), Pango Markup, LaTeX, RTF och vektoriell SVG

I detta praktiska exempel undersöker vi grundligt hur `fmt` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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
        _ = assert true (str_starts_with pango_out ("<tt>" + nl)) "AC3: Pango <tt> wrapper"
        _ = assert true (str_contains pango_out "<span foreground=\"#c678dd\" weight=\"bold\">fn</span>") "AC3: Pango span markup"

        -- 5. LaTeX Verbatim
        latex_out = fmt to latex src
        _ = assert true (str_contains latex_out "Verbatim") "AC3: LaTeX Verbatim environment"
        _ = assert true (str_contains latex_out "textcolor[HTML]") "AC3: LaTeX textcolor macro"

        -- 6. RTF
        rtf_out = fmt to rtf src
        _ = assert true (str_contains rtf_out "rtf1") "AC3: RTF header"
        _ = assert true (str_contains rtf_out "colortbl") "AC3: RTF color table"
        _ = assert true (str_contains rtf_out "\\cf1\\b fn") "AC3: RTF bold color span"
        ()
```

---

## 15.4. Under huven: hur `fmt` är byggd i ren Ridgun (`src/main/ridgun/lib/fmt.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/fmt.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 15.4.1. Intern implementation: Configuration Constructors

Se hur `fmt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: fmt

fn :: default fmt config => FmtConfig
      default fmt config = FmtConfig 2 4 80 True FmtPlain FmtThemeNone

fn :: fmt config Int Int Int Bool FmtTarget FmtTheme => FmtConfig
      fmt config indent_w max_params max_w aligned target theme =
        FmtConfig (fmt max 1 indent_w) (fmt max 0 max_params) (fmt max 20 max_w) aligned target theme
```

### 15.4.2. Intern implementation: Signature Parsing (`fn ::` / `op ::`)

Se hur `fmt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 15.4.3. Intern implementation: Lexical Token Classification & Syntax Highlighting

Se hur `fmt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 15.4.4. Intern implementation: Public Entry Points

Se hur `fmt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

## 15.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `fmt`

- **Algoritmisk garanti och säkerhet**: Strikt idempotens (`fmt source (fmt source s) == fmt source s`) och 100 % bevarande av semantiska tokens.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/fmt.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test fmt.rg`.

### De 5 Gyllene Reglerna när du programmerar med `fmt`

1. **Deklarera `import fmt` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `fmt`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `fmt`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `fmt` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 16** går vi vidare och utforskar lib:en **`cli`** på djupet (Lib:en `cli` — Flaggor, Alternativ, `--`-barriär, Underkommandon och Miljövariabler).
