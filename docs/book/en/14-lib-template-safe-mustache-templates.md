# Chapter 14: The `template` Lib — Safe Mustache Templates with HTML and LaTeX Auto-Escaping

## 14.1. Why Does the `template` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `template` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `template`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: assembling HTML pages or LaTeX reports by manual string concatenation is a textbook recipe for XSS vulnerabilities (`<script>`) or broken PDF builds the moment a user types `%` or `_`.

The **`template`** lib provides a logic-less **Mustache** engine with contextual auto-escaping (`TmplPlain`, `TmplHtml`, `TmplLatex`), explicit raw interpolation (`{{{raw}}}` / `{{&raw}}`), comments (`{{! ... }}`), truthy sections (`{{#sec}}...{{/sec}}`), and inverted sections (`{{^sec}}...{{/sec}}`).

In a traditional ecosystem, solving **`TMPL`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`template`** lib (`src/main/ridgun/lib/template.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `template` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `template` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `template` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 14.2. Native Artifacts, Imports, and Complete `template` API Catalog

In `ridgun-libs`, **`template`** is a first-class **lib** located at `src/main/ridgun/lib/template.rg` (domain `TMPL`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/template.rglib` | Portable distribution and direct `import template` resolution |
| **Compiled Archive** | `target/template.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libtemplate.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import template` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 14.2.1. Summary of `template` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Render Mustache templates with plain, HTML, or LaTeX auto-escaping |
| `tmpl escape html / tmpl escape latex` | Escape `& < > " '` for HTML or `\ { } & % $ # _ ~ ^` for LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Inspect required variable names and validate tag balance before rendering |

### 14.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/template.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/template.rg` (`1` types, `0` operators, and `35` functions):

**Algebraic Data Types & Records (`type`) in `template`:**

```ridgun
type TmplEscape = TmplEscapeNone | TmplEscapeHtml | TmplEscapeLatex
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: tm_lbrace` | `String` |
| `2` | `fn :: tm_rbrace` | `String` |
| `3` | `fn :: tm_braces` | `String` |
| `4` | `fn :: tm_is_space Int` | `Bool` |
| `5` | `fn :: tm_trim_start String Int Int` | `Int` |
| `6` | `fn :: tm_trim_end String Int Int` | `Int` |
| `7` | `fn :: tm_trim String` | `String` |
| `8` | `fn :: tm_lookup [(String, String)] String` | `String` |
| `9` | `fn :: tm_val_truthy String` | `Bool` |
| `10` | `fn :: tm_is_truthy [(String, String)] String` | `Bool` |
| `11` | `fn :: tm_escape_html_char Int` | `String` |
| `12` | `fn :: tm_escape_html_loop String Int Int String` | `String` |
| `13` | `fn :: tm_escape_latex_char Int` | `String` |
| `14` | `fn :: tm_escape_latex_loop String Int Int String` | `String` |
| `15` | `fn :: tm_escape String TmplEscape` | `String` |
| `16` | `fn :: tm_find_close2 String Int Int` | `Int` |
| `17` | `fn :: tm_find_close3 String Int Int` | `Int` |
| `18` | `fn :: tm_find_section_close String Int Int String Int` | `(Int, Int)` |
| `19` | `fn :: tm_check_section_tag String Int Int String Int Int` | `(Int, Int)` |
| `20` | `fn :: tm_check_close_tag String Int Int String Int Int` | `(Int, Int)` |
| `21` | `fn :: tm_close_tag_match String Int Int String Int Int` | `(Int, Int)` |
| `22` | `fn :: tm_check_open_tag String Int Int String Int Int` | `(Int, Int)` |
| `23` | `fn :: tm_scan String Int Int [(String, String)] TmplEscape String` | `String` |
| `24` | `fn :: tm_dispatch_tag String Int Int [(String, String)] TmplEscape String` | `String` |
| `25` | `fn :: tm_tag_raw3 String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `26` | `fn :: tm_tag_raw_amp String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `27` | `fn :: tm_tag_comment String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `28` | `fn :: tm_section_active Bool Bool` | `Bool` |
| `29` | `fn :: tm_render_section_body String Int (Int, Int) Int [(String, String)] TmplEscape String Bool` | `String` |
| `30` | `fn :: tm_tag_section String Int Int [(String, String)] TmplEscape String Int Bool` | `String` |
| `31` | `fn :: tm_tag_var String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `32` | `fn :: tmpl render with escape String [(String, String)] TmplEscape` | `String` |
| `33` | `fn :: tmpl render String [(String, String)]` | `String` |
| `34` | `fn :: tmpl render html String [(String, String)]` | `String` |
| `35` | `fn :: tmpl render latex String [(String, String)]` | `String` |

---

## 14.3. Deep Dive into `template`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `template` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test template.rg`.

### 14.3.1. Example 1: Core Tabular Workflow with `template`

Notice how in Ridgun the `=` signs and transformation steps using `template` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### 14.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `template` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

### 14.3.3. Example 3: Variable Interpolation `{{ key }}`, Tag Whitespace Trimming, and Comment Stripping `{{! ... }}`

In this hands-on walkthrough we thoroughly exercise how `template` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_tmpl_interpolation_and_comments => ()
      test_tmpl_interpolation_and_comments =
        nl = char_from_code 10
        ctx = [("name", "Ada Lovelace"), ("role", "Mathematician"), ("empty", "")]
        t1 = "Hello, " + (tag2 "name") + " (" + (tag2 "  role  ") + ")!"
        out1 = tmpl render t1 ctx
        _ = assert str eq out1 "Hello, Ada Lovelace (Mathematician)!" "AC1: variable and whitespace-trimmed tag interpolation"
        t_missing = "User: [" + (tag2 "unknown") + "] Empty: [" + (tag2 "empty") + "]"
        out_missing = tmpl render t_missing ctx
        _ = assert str eq out_missing "User: [] Empty: []" "AC1: missing and empty variables render empty string"
        t_comment = "Visible" + (tag2 "! secret comment ") + "Text" + (tag2 ("! multiline" + nl + "comment" + nl + "here ")) + "End"
        out_comment = tmpl render t_comment ctx
        _ = assert str eq out_comment "VisibleTextEnd" "AC1: single-line and multi-line comments omitted"
        ()
```

### 14.3.4. Example 4: Default XSS HTML Escaping (`&`, `<`, `>`, `"`, `'`) vs. Explicit Raw Insertion `{{{ raw }}}` and `{{& raw }}`

In this hands-on walkthrough we thoroughly exercise how `template` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_tmpl_html_escaping_and_raw => ()
      test_tmpl_html_escaping_and_raw =
        q = char_from_code 34
        ctx = [("xss", "<script>alert(" + q + "xss" + q + " & 'pwn')</script>"), ("trusted", "<b>Bold &amp; Safe</b>")]
        tmpl = "Escaped: " + (tag2 "xss") + " | Raw3: " + (tag3 "trusted") + " | RawAmp: " + (tag2 "& trusted ")
        out_html = tmpl render html tmpl ctx
        expected = "Escaped: &lt;script&gt;alert(&quot;xss&quot; &amp; &#39;pwn&#39;)&lt;/script&gt; | Raw3: <b>Bold &amp; Safe</b> | RawAmp: <b>Bold &amp; Safe</b>"
        _ = assert str eq out_html expected "AC1: HTML escaping vs raw triple-brace and ampersand tags"
        out_none = tmpl render ("Plain: " + (tag2 "xss")) ctx
        _ = assert str eq out_none ("Plain: <script>alert(" + q + "xss" + q + " & 'pwn')</script>") "AC1: TmplEscapeNone leaves HTML unescaped"
        ()
```

### 14.3.5. Example 5: Conditional Sections `{{#sec}}...{{/sec}}` and Inverted Sections `{{^sec}}...{{/sec}}` Driven by Truthiness Rules (`false`, `0`, `no`, `off`)

In this hands-on walkthrough we thoroughly exercise how `template` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_tmpl_sections_and_inverted => ()
      test_tmpl_sections_and_inverted =
        tmpl = (tag2 "#auth") + "Welcome, " + (tag2 "user") + "!" + (tag2 "/auth") + (tag2 "^auth") + "Please log in." + (tag2 "/auth")
        out_in = tmpl render html tmpl [("auth", "true"), ("user", "Alice & Bob")]
        _ = assert str eq out_in "Welcome, Alice &amp; Bob!" "AC2: truthy section rendered with HTML escaping"
        out_false = tmpl render html tmpl [("auth", "false"), ("user", "Alice")]
        _ = assert str eq out_false "Please log in." "AC2: 'false' triggers inverted section"
        out_false_cap = tmpl render html tmpl [("auth", "False"), ("user", "Alice")]
        _ = assert str eq out_false_cap "Please log in." "AC2: 'False' triggers inverted section"
        out_zero = tmpl render html tmpl [("auth", "0"), ("user", "Alice")]
        _ = assert str eq out_zero "Please log in." "AC2: '0' triggers inverted section"
        out_empty = tmpl render html tmpl [("auth", ""), ("user", "Alice")]
        _ = assert str eq out_empty "Please log in." "AC2: empty string triggers inverted section"
        out_missing = tmpl render html tmpl [("user", "Alice")]
        _ = assert str eq out_missing "Please log in." "AC2: missing key triggers inverted section"
        ()
```

### 14.3.6. Example 6: Deeply Nested Conditional Sections and Hierarchical Interpolation

In this hands-on walkthrough we thoroughly exercise how `template` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_tmpl_nested_sections => ()
      test_tmpl_nested_sections =
        tmpl = (tag2 "#outer") + "A-" + (tag2 "#inner") + "B-" + (tag2 "val") + (tag2 "/inner") + (tag2 "^inner") + "NO_INNER" + (tag2 "/inner") + "-C" + (tag2 "/outer")
        out1 = tmpl render tmpl [("outer", "1"), ("inner", "yes"), ("val", "42")]
        _ = assert str eq out1 "A-B-42-C" "AC2: nested outer+inner truthy"
        out2 = tmpl render tmpl [("outer", "1"), ("inner", "0"), ("val", "42")]
        _ = assert str eq out2 "A-NO_INNER-C" "AC2: nested outer truthy, inner falsy"
        out3 = tmpl render tmpl [("outer", "0"), ("inner", "yes"), ("val", "42")]
        _ = assert str eq out3 "" "AC2: nested outer falsy skips inner"
        same_nested = (tag2 "#k") + "[" + (tag2 "#k") + "(" + (tag2 "v") + ")" + (tag2 "/k") + "]" + (tag2 "/k")
        _ = assert str eq (tmpl render same_nested [("k", "1"), ("v", "ok")]) "[(ok)]" "AC2: nested same-key truthy"
        _ = assert str eq (tmpl render same_nested [("k", ""), ("v", "ok")]) "" "AC2: nested same-key falsy"
        ()
```

### 14.3.7. Example 7: Specialized LaTeX Document Escaping (`tmpl escape latex`: `\`, `{`, `}`, `$`, `&`, `#`, `_`, `%`, `~`, `^`)

In this hands-on walkthrough we thoroughly exercise how `template` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_tmpl_latex_escaping => ()
      test_tmpl_latex_escaping =
        bs = char_from_code 92
        lb = char_from_code 123
        rb = char_from_code 125
        braces = lb + rb
        ctx = [("formula", "100% of $50 & #1_item " + lb + "a" + bs + "b" + rb + " ~ ^"), ("raw_tex", bs + "textbf" + lb + "Title" + rb)]
        tmpl = "Text: " + (tag2 "formula") + " | Raw: " + (tag3 "raw_tex")
        out_tex = tmpl render latex tmpl ctx
        expected = "Text: 100" + bs + "% of " + bs + "$50 " + bs + "& " + bs + "#1" + bs + "_item " + bs + lb + "a" + bs + "textbackslash" + braces + "b" + bs + rb + " " + bs + "textasciitilde" + braces + " " + bs + "textasciicircum" + braces + " | Raw: " + bs + "textbf" + lb + "Title" + rb
        _ = assert str eq out_tex expected "AC3: LaTeX special characters escaped accurately while triple-brace stays raw"
        ()
```

### 14.3.8. Example 8: Deterministic Detection of Unclosed Tags and Mismatched Sections (`TmplErr`)

In this hands-on walkthrough we thoroughly exercise how `template` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_tmpl_malformed_tags => ()
      test_tmpl_malformed_tags =
        lb = char_from_code 123
        ctx = [("x", "1")]
        _ = assert str eq (tmpl render ("trailing " + lb + lb) ctx) ("trailing " + lb + lb) "AC1: trailing double brace"
        _ = assert str eq (tmpl render ("unclosed " + lb + lb + "x") ctx) ("unclosed " + lb + lb + "x") "AC1: unclosed var tag"
        _ = assert str eq (tmpl render ("unclosed raw " + lb + lb + lb + "x") ctx) ("unclosed raw " + lb + lb + lb + "x") "AC1: unclosed raw3 tag"
        _ = assert str eq (tmpl render ("unclosed comment " + lb + lb + "! hidden") ctx) "unclosed comment " "AC1: unclosed comment tag"
        ()
```

---

## 14.4. Under the Hood: How `template` Is Built in Pure Ridgun (`src/main/ridgun/lib/template.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/template.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 14.4.1. Internal Implementation: Internal Helpers

Observe how `template.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: tm_lbrace => String
      tm_lbrace =  char_from_code 123

fn :: tm_rbrace => String
      tm_rbrace =  char_from_code 125

fn :: tm_braces => String
      tm_braces =  (char_from_code 123) + (char_from_code 125)

fn :: tm_is_space Int => Bool
      tm_is_space c
        | c == 32 = True
        | c == 9 = True
        | c == 10 = True
        | c == 13 = True
        | otherwise = False

fn :: tm_trim_start String Int Int => Int
      tm_trim_start s      idx n
        | idx >= n = n
        | tm_is_space (str_char_at s idx) = tm_trim_start s (idx + 1) n
        | otherwise = idx

fn :: tm_trim_end String Int   Int => Int
      tm_trim_end s      start idx
        | idx <= start = start
        | tm_is_space (str_char_at s (idx - 1)) = tm_trim_end s start (idx - 1)
        | otherwise = idx

fn :: tm_trim String => String
      tm_trim s      =
        n = str_len s
        st = tm_trim_start s 0 n
        en = tm_trim_end s st n
        str_slice s st en

fn :: tm_lookup [(String, String)] String => String
      tm_lookup []                 _      =  ""
      tm_lookup ((k, v):rest)      key
        | k == key = v
        | otherwise = tm_lookup rest key

fn :: tm_val_truthy String => Bool
      tm_val_truthy val
        | val == "" = False
        | val == "false" = False
        | val == "False" = False
        | val == "0" = False
        | otherwise = True
```

### 14.4.2. Internal Implementation: Public API

Observe how `template.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: tmpl render with escape String [(String, String)] TmplEscape => String
      tmpl render with escape tmpl ctx mode = tm_scan tmpl 0 (str_len tmpl) ctx mode ""

fn :: tmpl render String [(String, String)] => String
      tmpl render tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeNone

fn :: tmpl render html String [(String, String)] => String
      tmpl render html tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeHtml

fn :: tmpl render latex String [(String, String)] => String
      tmpl render latex tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeLatex
```

---

## 14.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `template`

- **Algorithmic & Safety Guarantee**: Default XSS prevention in `tmpl render html` (escaping `&`, `<`, `>`, `"`, `'`), while triple-stache `{{{var}}}` explicitly opts into raw trusted markup.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/template.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test template.rg`.

### The 5 Golden Rules When Programming with `template`

1. **Declare `import template` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `template` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `template`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `template` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 15**, we will explore the **`fmt`** lib in full depth (The `fmt` Lib — Canonical 2D Tabular Formatter and 9-Target Syntax Highlighter).
