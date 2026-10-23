-- ============================================================
-- src/test/ridgun/test template.rg
-- Comprehensive test suite for template.rg inspired by mustache/spec (interpolation, sections, inverted, comments, HTML/LaTeX escaping)
-- @tests TS-TMPL-001
-- ============================================================

import test
import template

fn :: tag2 String => String
      tag2 inner  =
        lb = char_from_code 123
        rb = char_from_code 125
        lb + lb + inner + rb + rb

fn :: tag3 String => String
      tag3 inner  =
        lb = char_from_code 123
        rb = char_from_code 125
        lb + lb + lb + inner + rb + rb + rb

-- 1. Plain interpolation, missing variables, whitespace-padded tags, and comments
-- @tests TS-TMPL-001
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

-- 2. HTML auto-escaping vs triple-brace {{{raw}}} and {{&raw}} unescaped interpolation
-- @tests TS-TMPL-001
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

-- 3. Conditional sections {{#key}}...{{/key}} and inverted sections {{^key}}...{{/key}}
-- @tests TS-TMPL-001
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

-- 4. Nested conditional sections (same key and distinct keys)
-- @tests TS-TMPL-001
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

-- 5. LaTeX auto-escaping for special characters (\, {, }, &, %, $, #, _, ~, ^)
-- @tests TS-TMPL-001
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

-- 6. Malformed/unclosed tags graceful handling (no crash or infinite loop)
-- @tests TS-TMPL-001
fn :: test_tmpl_malformed_tags => ()
      test_tmpl_malformed_tags =
        lb = char_from_code 123
        ctx = [("x", "1")]
        _ = assert str eq (tmpl render ("trailing " + lb + lb) ctx) ("trailing " + lb + lb) "AC1: trailing double brace"
        _ = assert str eq (tmpl render ("unclosed " + lb + lb + "x") ctx) ("unclosed " + lb + lb + "x") "AC1: unclosed var tag"
        _ = assert str eq (tmpl render ("unclosed raw " + lb + lb + lb + "x") ctx) ("unclosed raw " + lb + lb + lb + "x") "AC1: unclosed raw3 tag"
        _ = assert str eq (tmpl render ("unclosed comment " + lb + lb + "! hidden") ctx) "unclosed comment " "AC1: unclosed comment tag"
        ()

-- @tests TS-TMPL-001
fn :: main => ()
      main =
        _ = test_tmpl_interpolation_and_comments
        _ = test_tmpl_html_escaping_and_raw
        _ = test_tmpl_sections_and_inverted
        _ = test_tmpl_nested_sections
        _ = test_tmpl_latex_escaping
        _ = test_tmpl_malformed_tags
        echo "[PASS] test template: TS-TMPL-001 passed"
