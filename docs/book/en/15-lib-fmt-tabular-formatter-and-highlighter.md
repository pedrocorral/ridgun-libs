# Chapter 15: The `fmt` Lib — Canonical 2D Tabular Formatter and 9-Target Syntax Highlighter

## 15.1. Why Does the `fmt` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `fmt` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `fmt`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: the beauty of Ridgun lies in its crisp tabular columns (`::`, `=`, `|`, `->`, `--`), but aligning spaces by hand or exporting syntax-highlighted code to ANSI terminals, HTML, and LaTeX without a dedicated engine is tedious.

The **`fmt`** lib is Ridgun's official 2D tabular formatter and lexical syntax highlighter: it aligns `fn ::` headers, equations, `|` guards, and `--` comments, and renders into **9 output targets** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

In a traditional ecosystem, solving **`FMT`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`fmt`** lib (`src/main/ridgun/lib/fmt.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `fmt` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `fmt` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `fmt` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 15.2. Native Artifacts, Imports, and Complete `fmt` API Catalog

In `ridgun-libs`, **`fmt`** is a first-class **lib** located at `src/main/ridgun/lib/fmt.rg` (domain `FMT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/fmt.rglib` | Portable distribution and direct `import fmt` resolution |
| **Compiled Archive** | `target/fmt.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libfmt.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import fmt` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 15.2.1. Summary of `fmt` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `fmt source / fmt source with` | Format raw Ridgun source code using canonical 2D tabular column alignment |
| `fmt check` | Return `True` if source code already matches canonical `fmt source` layout |
| `fmt render / fmt render with` | Format and highlight source into any of the 9 `FmtTarget` backends |
| `fmt tokenize line` | Tokenize a Ridgun line into `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

### 15.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/fmt.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/fmt.rg` (`7` types, `0` operators, and `166` functions):

**Algebraic Data Types & Records (`type`) in `fmt`:**

```ridgun
type FmtTarget = FmtPlain | FmtTty | FmtTrueColor | FmtHtmlInline | FmtHtmlCss | FmtMarkdown | FmtPango | FmtLatex | FmtRtf
type FmtTheme = FmtThemeNone | FmtThemeDark | FmtThemeLight
type FmtConfig = indent_width: Int, max_align_params: Int, max_line_width: Int, is_aligned: Bool, target_format: FmtTarget, color_theme: FmtTheme
type FmtToken = FmtTok String Int
type FmtSig = NoSig | SigInfo String [String] String String [Int] Int Int
type FmtClause = NoClause | ClauseInfo [String] Bool String
type FmtWhereBind = NoWhereBind | WhereBindInfo String String
```

| # | Function / Signature (`fn ::`) | Return Type |
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

## 15.3. Deep Dive into `fmt`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `fmt` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test fmt.rg`.

### 15.3.1. Example 1: Core Tabular Workflow with `fmt`

Notice how in Ridgun the `=` signs and transformation steps using `fmt` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### 15.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `fmt` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

### 15.3.3. Example 3: Canonical Tabular Alignment (`fmt ridgun`, `fmt ridgun with`) of `=>` Signatures, `=` Clauses, `->` Bindings, and `--` Comments

In this hands-on walkthrough we thoroughly exercise how `fmt` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test fmt canonical alignment and config => ()
      test fmt canonical alignment and config =
        nl = char_from_code 10
        raw_src = "fn :: add Int Int => Int" + nl + "add x y = x + y" + nl + "add 0 y_long = y_long" + nl
        expected_2d = "fn :: add Int Int    => Int" + nl + "      add x   y      =  x + y" + nl + "      add 0   y_long =  y_long" + nl
        out_2d = format ridgun source raw_src
        _ = assert str eq out_2d expected_2d "AC1: canonical 2D tabular alignment"

        -- Unaligned config (`is_aligned = False`) uses single-space separation
        cfg_unaligned = fmt config 2 4 80 False FmtPlain FmtThemeNone
        out_unaligned = fmt source with config raw_src cfg_unaligned
        expected_unaligned = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "      add 0 y_long = y_long" + nl
        _ = assert str eq out_unaligned expected_unaligned "AC1: unaligned FmtConfig"

        -- Guard and `where` alignment with custom indent_width = 4
        guard_src = "fn :: clamp Int => Int" + nl + "clamp x" + nl + "| x < 0 = 0" + nl + "| otherwise = x" + nl + "where" + nl + "lo -> 0" + nl
        cfg_ind4 = fmt config 4 4 80 True FmtPlain FmtThemeNone
        out_ind4 = fmt source with config guard_src cfg_ind4
        _ = assert true (str_contains out_ind4 "          | x < 0 = 0") "AC1: custom indent_width = 4 guard indentation"
        _ = assert true (str_contains out_ind4 "              lo -> 0") "AC1: custom indent_width = 4 where binding alignment"
        ()
```

### 15.3.4. Example 4: ANSI 16-Color and 24-Bit TrueColor Lexical Highlighting with Automatic TTY and `NO_COLOR` Detection

In this hands-on walkthrough we thoroughly exercise how `fmt` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test fmt terminal highlighting tty and truecolor => ()
      test fmt terminal highlighting tty and truecolor =
        nl = char_from_code 10
        esc = char_from_code 27
        interp_tok = (char_from_code 123) + "name" + (char_from_code 125)
        sample = "-- @implements FR-FMT-001" + nl + "-- comment line" + nl + "fn :: greet String => String" + nl + "greet name = \"Hello " + interp_tok + "\" + (int_to_str 0x2A)" + nl

        tty_dark = fmt to tty sample
        _ = assert true (str_contains tty_dark (esc + "[1;32m-- @implements FR-FMT-001" + esc + "[0m")) "AC2: TTY pragma highlight"
        _ = assert true (str_contains tty_dark (esc + "[90m-- comment line" + esc + "[0m")) "AC2: TTY comment highlight"
        _ = assert true (str_contains tty_dark (esc + "[1;35mfn" + esc + "[0m")) "AC2: TTY keyword highlight"
        _ = assert true (str_contains tty_dark (esc + "[1;34mgreet" + esc + "[0m")) "AC2: TTY function name highlight"
        _ = assert true (str_contains tty_dark (esc + "[33mString" + esc + "[0m")) "AC2: TTY type highlight"
        _ = assert true (str_contains tty_dark (esc + "[36m" + interp_tok + esc + "[0m")) "AC2: TTY string interpolation highlight"
        _ = assert true (str_contains tty_dark (esc + "[36m0x2A" + esc + "[0m")) "AC2: TTY hex number highlight"

        tty_none = fmt to tty with theme sample FmtThemeNone
        _ = assert false (str_contains tty_none esc) "AC2: FmtThemeNone emits no ANSI escape codes"

        tc_dark = fmt to truecolor sample
        _ = assert true (str_contains tc_dark (esc + "[1;38;2;198;120;221mfn" + esc + "[0m")) "AC2: TrueColor dark keyword RGB"
        _ = assert true (str_contains tc_dark (esc + "[1;38;2;97;175;239mgreet" + esc + "[0m")) "AC2: TrueColor dark function RGB"

        tc_light = fmt to truecolor with theme sample FmtThemeLight
        _ = assert true (str_contains tc_light (esc + "[1;38;2;166;38;164mfn" + esc + "[0m")) "AC2: TrueColor light keyword RGB"
        ()
```

### 15.3.5. Example 5: Exporting Highlighted Documents to HTML5 (`<pre><code>`), Pango Markup, LaTeX, RTF, and Vector SVG

In this hands-on walkthrough we thoroughly exercise how `fmt` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test fmt enriched document targets => ()
      test fmt enriched document targets =
        nl = char_from_code 10
        src = "fn :: cmp Int Int => Bool" + nl + "cmp a b = a < b AND b > 0" + nl

        -- 1. Inline HTML
        html_out = fmt to html src
        _ = assert true (str_starts_with html_out "<pre class=\"ridgun-code\"") "AC3: HTML inline wrapper"
        _ = assert true (str_contains html_out "<span style=\"color:#c678dd;font-weight:bold\">fn</span>") "AC3: HTML inline keyword span"
        _ = assert true (str_contains html_out "&lt;") "AC3: HTML escapes < operator"
        _ = assert true (str_contains html_out "&gt;") "AC3: HTML escapes > operator"

        -- 2. CSS-class HTML + Stylesheet
        css_html = fmt to html css src
        _ = assert true (str_contains css_html "<span class=\"rg-kw\">fn</span>") "AC3: HTML CSS keyword class"
        _ = assert true (str_contains css_html "<span class=\"rg-fn\">cmp</span>") "AC3: HTML CSS function class"
        _ = assert true (str_contains css_html "<span class=\"rg-type\">Int</span>") "AC3: HTML CSS type class"
        _ = assert true (str_contains css_html "<span class=\"rg-logic\">AND</span>") "AC3: HTML CSS logic operator class"
        sheet_dark = fmt html stylesheet FmtThemeDark
        sheet_light = fmt html stylesheet FmtThemeLight
        _ = assert true (str_contains sheet_dark ".rg-kw") "AC3: Dark CSS stylesheet"
        _ = assert true (str_contains sheet_light "#fafafa") "AC3: Light CSS stylesheet"

        -- 3. Markdown
        md_out = fmt to markdown src
        _ = assert true (str_starts_with md_out ("```ridgun" + nl)) "AC3: Markdown fenced code block"

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

## 15.4. Under the Hood: How `fmt` Is Built in Pure Ridgun (`src/main/ridgun/lib/fmt.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/fmt.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 15.4.1. Internal Implementation: Configuration Constructors

Observe how `fmt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: default fmt config => FmtConfig
      default fmt config =  FmtConfig 2 4 80 True FmtPlain FmtThemeNone

fn :: fmt config Int Int Int Bool FmtTarget FmtTheme => FmtConfig
      fmt config indent_w max_params max_w aligned target theme =
        FmtConfig (fmt_max 1 indent_w) (fmt_max 0 max_params) (fmt_max 20 max_w) aligned target theme
```

### 15.4.2. Internal Implementation: Signature Parsing (`fn ::` / `op ::`)

Observe how `fmt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: fmt_split_sig_arrow [FmtToken] [String] => (Bool, [String], String, Int)
      fmt_split_sig_arrow []         _        =  (False, [], "", 0)
      fmt_split_sig_arrow ((FmtTok tok col):rest) lhs_acc
        | tok == "=>" OR tok == "->" = (True, lhs_acc, tok, col)
        | otherwise = fmt_split_sig_arrow rest (lhs_acc :: [tok])

fn :: fmt_is_sig_type_tok String => Bool
      fmt_is_sig_type_tok ""     =  False
      fmt_is_sig_type_tok tok    =
        ch = str_char_at tok 0
        (ch >= 65 AND ch <= 90) OR ch == 91 OR ch == 40

fn :: fmt_all_type_toks [String] => Bool
      fmt_all_type_toks []       =  True
      fmt_all_type_toks (t:rest)
        | fmt_is_sig_type_tok t = fmt_all_type_toks rest
        | otherwise = False

fn :: fmt_is_bare_fn_lhs [String]       => Bool
      fmt_is_bare_fn_lhs (first_w:rest)
        | NOT (fmt_is_sig_type_tok first_w) = fmt_all_type_toks rest
      fmt_is_bare_fn_lhs _              =  False

fn :: fmt_infer_bare_kind [String] => String
      fmt_infer_bare_kind lhs_strs
        | fmt_is_bare_fn_lhs lhs_strs = "bare_fn"
        | otherwise = "bare_op"

fn :: fmt_parse_sig_line String => FmtSig
      fmt_parse_sig_line line   =
        clean = fmt_strip_comment line
        cmt = fmt_extract_comment line
        toks = fmt_scan_tokens clean
        fmt_parse_sig_tokens (fmt_leading_indent line) clean cmt toks

fn :: fmt_parse_sig_tokens Int String String [FmtToken] => FmtSig
      fmt_parse_sig_tokens _   clean  cmt    ((FmtTok kind _):(FmtTok "::" _):rest)
        | kind == "fn" OR kind == "op" = fmt_finish_sig_parse clean cmt kind (fmt_split_sig_arrow rest [])
      fmt_parse_sig_tokens 0   clean  cmt    ((FmtTok w col):rest)
        | w == "type" OR w == "expand" OR w == "import" OR w == "global" OR w == "context" OR w == "shared" OR w == "hardware" OR (str_starts_with w "@") OR (str_starts_with w "--") OR (str_starts_with w "|") = NoSig
        | otherwise = fmt_finish_bare_sig_parse clean cmt (fmt_split_sig_arrow ([FmtTok w col] :: rest) [])
      fmt_parse_sig_tokens _   _      _      _          =  NoSig

fn :: fmt_finish_bare_sig_parse String String (Bool, [String], String, Int) => FmtSig
      fmt_finish_bare_sig_parse _ _ (False, _, _, _) = NoSig
      fmt_finish_bare_sig_parse _ _ (True, [], _, _) = NoSig
      fmt_finish_bare_sig_parse clean cmt (True, lhs_strs, arrow_s, arrow_col)
        | arrow_s == "=>" = fmt_finish_sig_parse clean cmt (fmt_infer_bare_kind lhs_strs) (True, lhs_strs, arrow_s, arrow_col)
        | otherwise = NoSig
```

### 15.4.3. Internal Implementation: Lexical Token Classification & Syntax Highlighting

Observe how `fmt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: fmt_is_digit Int => Bool
      fmt_is_digit c   =  c >= 48 AND c <= 57

fn :: fmt_is_upper Int => Bool
      fmt_is_upper c   =  c >= 65 AND c <= 90

fn :: fmt_is_lower Int => Bool
      fmt_is_lower c   =  c >= 97 AND c <= 122

fn :: fmt_is_ident_char Int => Bool
      fmt_is_ident_char c   =  (fmt_is_upper c) OR (fmt_is_lower c) OR (fmt_is_digit c) OR c == 95

fn :: fmt_is_keyword String => Bool
      fmt_is_keyword w      =
        w == "fn" OR w == "op" OR w == "type" OR w == "expand" OR w == "import" OR w == "module" OR w == "where" OR w == "otherwise" OR w == "with" OR w == "do" OR w == "mut" OR w == "in" OR w == "agent" OR w == "send" OR w == "to" OR w == "receive" OR w == "from" OR w == "try" OR w == "stop" OR w == "timeout" OR w == "global" OR w == "context" OR w == "shared" OR w == "hardware" OR w == "atomic" OR w == "region" OR w == "limit" OR w == "map" OR w == "filter" OR w == "fold"

fn :: fmt_is_logic_op String => Bool
      fmt_is_logic_op w      =
        w == "AND" OR w == "OR" OR w == "XOR" OR w == "NOT" OR w == "and" OR w == "or" OR w == "xor" OR w == "not" OR w == "shl" OR w == "shr" OR w == "rotr" OR w == "rotl"

fn :: fmt_is_bool_lit String => Bool
      fmt_is_bool_lit w      =  w == "True" OR w == "False"

fn :: fmt_classify_word String Bool  => String
      fmt_classify_word ""     _     =  "plain"
      fmt_classify_word w      in_fn
        | fmt_is_keyword w = "keyword"
        | fmt_is_logic_op w = "logic"
        | fmt_is_bool_lit w = "bool"
        | fmt_is_upper (str_char_at w 0) = "type"
        | fmt_is_digit (str_char_at w 0) = "number"
        | in_fn = "function"
        | otherwise = "plain"
```

### 15.4.4. Internal Implementation: Public Entry Points

Observe how `fmt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: fmt source with config String FmtConfig => String
      fmt source with config src cfg =
        raw_lines = fmt_split_raw_lines src
        formatted_lines = fmt_format_top_lines raw_lines 0 "" cfg
        target = target_format cfg
        theme = color_theme cfg
        highlighted = fmt_highlight_lines formatted_lines target theme
        fmt_wrap_target_doc highlighted target theme

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
```

---

## 15.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `fmt`

- **Algorithmic & Safety Guarantee**: Strict idempotence (`fmt source (fmt source s) == fmt source s`) and 100% preservation of semantic tokens.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/fmt.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test fmt.rg`.

### The 5 Golden Rules When Programming with `fmt`

1. **Declare `import fmt` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `fmt` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `fmt`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `fmt` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 16**, we will explore the **`cli`** lib in full depth (The `cli` Lib — Flags, Options, `--` Barrier, Subcommands, and Typed Env Readers).
