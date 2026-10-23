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

-- @tests TS-FMT-001
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

-- @tests TS-FMT-001
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

-- @tests TS-FMT-001
fn :: main => ()
      main =
        _ = test fmt canonical alignment and config
        _ = test fmt terminal highlighting tty and truecolor
        _ = test fmt enriched document targets
        echo "[PASS] test fmt: TS-FMT-001 passed"
