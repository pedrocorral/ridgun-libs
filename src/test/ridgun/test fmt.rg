-- ============================================================
-- src/test/ridgun/test fmt.rg
-- Automated test suite for the Ridgun Source Code Formatter & Multi-Target Syntax Highlighter (`fmt.rg`)
-- @tests TS-FMT-001
-- ============================================================

import test
import fmt

-- @tests TS-FMT-001
fn :: test fmt canonical alignment and config => ()
      test fmt canonical alignment and config =
        nl = char from code 10
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
        _ = assert true (str contains out_ind4 "          | x < 0 = 0") "AC1: custom indent_width = 4 guard indentation"
        _ = assert true (str contains out_ind4 "              lo -> 0") "AC1: custom indent_width = 4 where binding alignment"
        ()

-- @tests TS-FMT-001
fn :: test fmt terminal highlighting tty and truecolor => ()
      test fmt terminal highlighting tty and truecolor =
        nl = char from code 10
        esc = char from code 27
        interp_tok = (char from code 123) + "name" + (char from code 125)
        sample = "-- @implements FR-FMT-001" + nl + "-- comment line" + nl + "fn :: greet String => String" + nl + "greet name = \"Hello " + interp_tok + "\" + (int to str 0x2A)" + nl

        tty_dark = fmt to tty sample
        _ = assert true (str contains tty_dark (esc + "[1;32m-- @implements FR-FMT-001" + esc + "[0m")) "AC2: TTY pragma highlight"
        _ = assert true (str contains tty_dark (esc + "[90m-- comment line" + esc + "[0m")) "AC2: TTY comment highlight"
        _ = assert true (str contains tty_dark (esc + "[1;35mfn" + esc + "[0m")) "AC2: TTY keyword highlight"
        _ = assert true (str contains tty_dark (esc + "[1;34mgreet" + esc + "[0m")) "AC2: TTY function name highlight"
        _ = assert true (str contains tty_dark (esc + "[33mString" + esc + "[0m")) "AC2: TTY type highlight"
        _ = assert true (str contains tty_dark (esc + "[36m" + interp_tok + esc + "[0m")) "AC2: TTY string interpolation highlight"
        _ = assert true (str contains tty_dark (esc + "[36m0x2A" + esc + "[0m")) "AC2: TTY hex number highlight"

        tty_none = fmt to tty with theme sample FmtThemeNone
        _ = assert false (str contains tty_none esc) "AC2: FmtThemeNone emits no ANSI escape codes"

        tc_dark = fmt to truecolor sample
        _ = assert true (str contains tc_dark (esc + "[1;38;2;198;120;221mfn" + esc + "[0m")) "AC2: TrueColor dark keyword RGB"
        _ = assert true (str contains tc_dark (esc + "[1;38;2;97;175;239mgreet" + esc + "[0m")) "AC2: TrueColor dark function RGB"

        tc_light = fmt to truecolor with theme sample FmtThemeLight
        _ = assert true (str contains tc_light (esc + "[1;38;2;166;38;164mfn" + esc + "[0m")) "AC2: TrueColor light keyword RGB"
        ()

-- @tests TS-FMT-001
fn :: test fmt enriched document targets => ()
      test fmt enriched document targets =
        nl = char from code 10
        src = "fn :: cmp Int Int => Bool" + nl + "cmp a b = a < b AND b > 0" + nl

        -- 1. Inline HTML
        html_out = fmt to html src
        _ = assert true (str starts with html_out "<pre class=\"ridgun-code\"") "AC3: HTML inline wrapper"
        _ = assert true (str contains html_out "<span style=\"color:#c678dd;font-weight:bold\">fn</span>") "AC3: HTML inline keyword span"
        _ = assert true (str contains html_out "&lt;") "AC3: HTML escapes < operator"
        _ = assert true (str contains html_out "&gt;") "AC3: HTML escapes > operator"

        -- 2. CSS-class HTML + Stylesheet
        css_html = fmt to html css src
        _ = assert true (str contains css_html "<span class=\"rg-kw\">fn</span>") "AC3: HTML CSS keyword class"
        _ = assert true (str contains css_html "<span class=\"rg-fn\">cmp</span>") "AC3: HTML CSS function class"
        _ = assert true (str contains css_html "<span class=\"rg-type\">Int</span>") "AC3: HTML CSS type class"
        _ = assert true (str contains css_html "<span class=\"rg-logic\">AND</span>") "AC3: HTML CSS logic operator class"
        sheet_dark = fmt html stylesheet FmtThemeDark
        sheet_light = fmt html stylesheet FmtThemeLight
        _ = assert true (str contains sheet_dark ".rg-kw") "AC3: Dark CSS stylesheet"
        _ = assert true (str contains sheet_light "#fafafa") "AC3: Light CSS stylesheet"

        -- 3. Markdown
        md_out = fmt to markdown src
        _ = assert true (str starts with md_out ("```ridgun" + nl)) "AC3: Markdown fenced code block"

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

-- @tests TS-FMT-001
fn :: test fmt signature aware fn and op highlighting => ()
      test fmt signature aware fn and op highlighting =
        nl = char from code 10
        fn_src = "fn :: copy to with otherwise String Int => String" + nl + "copy to with otherwise src opt = copy src" + nl
        fn_css = fmt to html css fn_src
        _ = assert true (str contains fn_css "<span class=\"rg-fn\">copy</span> <span class=\"rg-fn\">to</span> <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">otherwise</span> <span class=\"rg-type\">String</span> <span class=\"rg-type\">Int</span>") "AC2/AC3: fn :: highlights keyword-named fn words as rg-fn and types as rg-type"
        _ = assert true (str contains fn_css "      <span class=\"rg-fn\">copy</span> <span class=\"rg-fn\">to</span> <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">otherwise</span> src    opt <span class=\"rg-op\">=</span>  copy src") "AC2/AC3: fn = clause highlights fn words as rg-fn, parameters as plain, and RHS invocation as non-rg-fn"
        _ = assert false (str contains fn_css "<span class=\"rg-fn\">src</span>") "AC2/AC3: fn = clause parameter src is not highlighted as rg-fn"
        _ = assert false (str contains fn_css "<span class=\"rg-kw\">otherwise</span>") "AC2/AC3: otherwise inside fn declaration/definition is not highlighted as rg-kw"
        _ = assert false (str contains fn_css "<span class=\"rg-kw\">with</span>") "AC2/AC3: with inside fn declaration/definition is not highlighted as rg-kw"
        _ = assert false (str contains fn_css "<span class=\"rg-kw\">to</span>") "AC2/AC3: to inside fn declaration/definition is not highlighted as rg-kw"

        op_src = "op :: Int unwrap or Int with to Int => Int" + nl + "a unwrap or b with to c = a + b + c" + nl
        op_css = fmt to html css op_src
        _ = assert true (str contains op_css "<span class=\"rg-type\">Int</span> <span class=\"rg-fn\">unwrap</span> <span class=\"rg-fn\">or</span> <span class=\"rg-type\">Int</span> <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">to</span> <span class=\"rg-type\">Int</span>") "AC2/AC3: op :: highlights mixfix op words (or, with, to) as rg-fn and parameter types as rg-type"
        _ = assert true (str contains op_css "      a   <span class=\"rg-fn\">unwrap</span> <span class=\"rg-fn\">or</span> b   <span class=\"rg-fn\">with</span> <span class=\"rg-fn\">to</span> c   <span class=\"rg-op\">=</span>") "AC2/AC3: op = clause highlights mixfix op words as rg-fn and interleaved parameter slots (a, b, c) as plain"
        _ = assert false (str contains op_css "<span class=\"rg-logic\">or</span>") "AC2/AC3: or inside op declaration/definition is not highlighted as rg-logic"

        -- Bare declarations without fn :: / op :: prefix (unindented and indented)
        bare_swap = "swap A with B => (B, A)" + nl + "swap x with y =  (y, x)" + nl
        bare_swap_css = fmt to html css bare_swap
        _ = assert true (str contains bare_swap_css "<span class=\"rg-fn\">swap</span> <span class=\"rg-type\">A</span> <span class=\"rg-fn\">with</span> <span class=\"rg-type\">B</span>") "AC2/AC3: bare op signature highlights swap and with as rg-fn"
        _ = assert true (str contains bare_swap_css "<span class=\"rg-fn\">swap</span> x <span class=\"rg-fn\">with</span> y <span class=\"rg-op\">=</span>") "AC2/AC3: bare op clause highlights swap and with as rg-fn and parameters x, y as plain"
        _ = assert false (str contains bare_swap_css "<span class=\"rg-kw\">with</span>") "AC2/AC3: with in bare op signature/clause is not highlighted as rg-kw"

        ind_swap = fmt join lines (fmt highlight lines ["  swap A with B => (B, A)", "  swap x with y =  (y, x)"] FmtHtmlCss FmtThemeDark)
        _ = assert true (str contains ind_swap "<span class=\"rg-fn\">swap</span> <span class=\"rg-type\">A</span> <span class=\"rg-fn\">with</span> <span class=\"rg-type\">B</span>") "AC2/AC3: indented bare op signature highlights swap and with as rg-fn"
        _ = assert true (str contains ind_swap "<span class=\"rg-fn\">swap</span> x <span class=\"rg-fn\">with</span> y <span class=\"rg-op\">=</span>") "AC2/AC3: indented bare op clause highlights swap and with as rg-fn"

        -- Clause parameter slots in bigger a b = ... (both with signature, without signature, and via fmt highlight line)
        bigger_hl = fmt highlight line "      bigger a   b   =  a" FmtHtmlCss FmtThemeDark
        _ = assert true (str contains bigger_hl "<span class=\"rg-fn\">bigger</span> a   b   <span class=\"rg-op\">=</span>") "AC2/AC3: fmt highlight line highlights bigger as rg-fn and parameters a, b as plain"
        _ = assert false (str contains bigger_hl "<span class=\"rg-fn\">a</span>") "AC2/AC3: parameter a is not highlighted as rg-fn"
        _ = assert false (str contains bigger_hl "<span class=\"rg-fn\">b</span>") "AC2/AC3: parameter b is not highlighted as rg-fn"

        nosig_bigger = fmt to html css ("bigger a b =" + nl + "  | a > b = a" + nl + "  | otherwise = b" + nl)
        _ = assert true (str contains nosig_bigger "<span class=\"rg-fn\">bigger</span> a b <span class=\"rg-op\">=</span>") "AC2/AC3: signature-less clause highlights bigger as rg-fn and parameters a, b as plain"

        -- Record update with and agent send/to/receive/from remain keywords, and where is not a keyword
        kw_expr = fmt to html css ("  c with tls: True" + nl + "  send msg to worker" + nl + "  receive from worker -> reply" + nl + "  where_var = where" + nl)
        _ = assert true (str contains kw_expr "c <span class=\"rg-kw\">with</span> tls:") "AC2/AC3: with in record update remains rg-kw"
        _ = assert true (str contains kw_expr "<span class=\"rg-kw\">send</span> msg <span class=\"rg-kw\">to</span> worker") "AC2/AC3: send and to remain rg-kw in expressions"
        _ = assert true (str contains kw_expr "<span class=\"rg-kw\">receive</span> <span class=\"rg-kw\">from</span> worker") "AC2/AC3: receive and from remain rg-kw in expressions"
        _ = assert false (str contains kw_expr "<span class=\"rg-kw\">where</span>") "AC2/AC3: where is not a reserved keyword in Ridgun"
        ()

-- @tests TS-FMT-001
fn :: main => ()
      main =
        _ = test fmt canonical alignment and config
        _ = test fmt terminal highlighting tty and truecolor
        _ = test fmt enriched document targets
        _ = test fmt signature aware fn and op highlighting
        echo "[PASS] test fmt: TS-FMT-001 passed"
