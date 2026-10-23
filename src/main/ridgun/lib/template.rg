-- ============================================================
-- src/main/ridgun/lib/template.rg
-- Pure-Ridgun Safe Mustache-Style Text Template Engine Library (TMPL)
-- @implements FR-TMPL-001
-- @implements API-TMPL-001
-- @implements DM-Template
-- @mitigates VUL-INPUT-001
-- ============================================================

type TmplEscape = TmplEscapeNone | TmplEscapeHtml | TmplEscapeLatex

-- ── Internal Helpers ─────────────────────────────────────────

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

fn :: tm_is_truthy [(String, String)] String => Bool
      tm_is_truthy ctx                key    =  tm_val_truthy (tm_lookup ctx key)

fn :: tm_escape_html_char Int => String
      tm_escape_html_char c
        | c == 38 = "&amp;"
        | c == 60 = "&lt;"
        | c == 62 = "&gt;"
        | c == 34 = "&quot;"
        | c == 39 = "&#39;"
        | otherwise = char_from_code c

fn :: tm_escape_html_loop String Int Int String => String
      tm_escape_html_loop s      idx n   acc
        | idx >= n = acc
        | otherwise = tm_escape_html_loop s (idx + 1) n (acc + (tm_escape_html_char (str_char_at s idx)))

fn :: tm_escape_latex_char Int => String
      tm_escape_latex_char c
        | c == 92 = (char_from_code 92) + "textbackslash" + tm_braces
        | c == 123 = (char_from_code 92) + tm_lbrace
        | c == 125 = (char_from_code 92) + tm_rbrace
        | c == 38 = (char_from_code 92) + "&"
        | c == 37 = (char_from_code 92) + "%"
        | c == 36 = (char_from_code 92) + "$"
        | c == 35 = (char_from_code 92) + "#"
        | c == 95 = (char_from_code 92) + "_"
        | c == 126 = (char_from_code 92) + "textasciitilde" + tm_braces
        | c == 94 = (char_from_code 92) + "textasciicircum" + tm_braces
        | otherwise = char_from_code c

fn :: tm_escape_latex_loop String Int Int String => String
      tm_escape_latex_loop s      idx n   acc
        | idx >= n = acc
        | otherwise = tm_escape_latex_loop s (idx + 1) n (acc + (tm_escape_latex_char (str_char_at s idx)))

fn :: tm_escape String TmplEscape      => String
      tm_escape s      TmplEscapeNone  =  s
      tm_escape s      TmplEscapeHtml  =  tm_escape_html_loop s 0 (str_len s) ""
      tm_escape s      TmplEscapeLatex =  tm_escape_latex_loop s 0 (str_len s) ""

fn :: tm_find_close2 String Int Int => Int
      tm_find_close2 s      idx n
        | (idx + 1) >= n = 0 - 1
        | (str_char_at s idx) == 125 AND (str_char_at s (idx + 1)) == 125 = idx
        | otherwise = tm_find_close2 s (idx + 1) n

fn :: tm_find_close3 String Int Int => Int
      tm_find_close3 s      idx n
        | (idx + 2) >= n = 0 - 1
        | (str_char_at s idx) == 125 AND (str_char_at s (idx + 1)) == 125 AND (str_char_at s (idx + 2)) == 125 = idx
        | otherwise = tm_find_close3 s (idx + 1) n

fn :: tm_find_section_close String Int Int String Int => (Int, Int)
      tm_find_section_close s idx n sec_key depth
        | (idx + 3) >= n = (n, n)
        | (str_char_at s idx) == 123 AND (str_char_at s (idx + 1)) == 123 =
          tm_check_section_tag s idx n sec_key depth (str_char_at s (idx + 2))
        | otherwise = tm_find_section_close s (idx + 1) n sec_key depth

fn :: tm_check_section_tag String Int Int String Int Int => (Int, Int)
      tm_check_section_tag s idx n sec_key depth sig
        | sig == 47 = tm_check_close_tag s idx n sec_key depth (tm_find_close2 s (idx + 3) n)
        | sig == 35 OR sig == 94 = tm_check_open_tag s idx n sec_key depth (tm_find_close2 s (idx + 3) n)
        | otherwise = tm_find_section_close s (idx + 2) n sec_key depth

fn :: tm_check_close_tag String Int Int String Int Int => (Int, Int)
      tm_check_close_tag s idx n sec_key depth close_pos
        | close_pos < 0 = (n, n)
        | (tm_trim (str_slice s (idx + 3) close_pos)) == sec_key =
          tm_close_tag_match s idx n sec_key depth close_pos
        | otherwise = tm_find_section_close s (close_pos + 2) n sec_key depth

fn :: tm_close_tag_match String Int Int String Int Int => (Int, Int)
      tm_close_tag_match s idx n sec_key depth close_pos
        | depth <= 1 = (idx, close_pos + 2)
        | otherwise = tm_find_section_close s (close_pos + 2) n sec_key (depth - 1)

fn :: tm_check_open_tag String Int Int String Int Int => (Int, Int)
      tm_check_open_tag s idx n sec_key depth close_pos
        | close_pos < 0 = (n, n)
        | (tm_trim (str_slice s (idx + 3) close_pos)) == sec_key =
          tm_find_section_close s (close_pos + 2) n sec_key (depth + 1)
        | otherwise = tm_find_section_close s (close_pos + 2) n sec_key depth

fn :: tm_scan String Int Int [(String, String)] TmplEscape String => String
      tm_scan s idx n ctx mode acc
        | idx >= n = acc
        | (idx + 1) < n AND (str_char_at s idx) == 123 AND (str_char_at s (idx + 1)) == 123 =
          tm_dispatch_tag s idx n ctx mode acc
        | otherwise = tm_scan s (idx + 1) n ctx mode (acc + (char_from_code (str_char_at s idx)))

fn :: tm_dispatch_tag String Int Int [(String, String)] TmplEscape String => String
      tm_dispatch_tag s idx n ctx mode acc
        | (idx + 2) >= n = acc + tm_lbrace + tm_lbrace
        | (str_char_at s (idx + 2)) == 123 = tm_tag_raw3 s idx n ctx mode acc (tm_find_close3 s (idx + 3) n)
        | (str_char_at s (idx + 2)) == 38 = tm_tag_raw_amp s idx n ctx mode acc (tm_find_close2 s (idx + 3) n)
        | (str_char_at s (idx + 2)) == 33 = tm_tag_comment s idx n ctx mode acc (tm_find_close2 s (idx + 3) n)
        | (str_char_at s (idx + 2)) == 35 = tm_tag_section s idx n ctx mode acc (tm_find_close2 s (idx + 3) n) False
        | (str_char_at s (idx + 2)) == 94 = tm_tag_section s idx n ctx mode acc (tm_find_close2 s (idx + 3) n) True
        | otherwise = tm_tag_var s idx n ctx mode acc (tm_find_close2 s (idx + 2) n)

fn :: tm_tag_raw3 String Int Int [(String, String)] TmplEscape String Int => String
      tm_tag_raw3 s idx n ctx mode acc close_pos
        | close_pos < 0 = tm_scan s (idx + 3) n ctx mode (acc + tm_lbrace + tm_lbrace + tm_lbrace)
        | otherwise =
          tm_scan s (close_pos + 3) n ctx mode (acc + (tm_lookup ctx (tm_trim (str_slice s (idx + 3) close_pos))))

fn :: tm_tag_raw_amp String Int Int [(String, String)] TmplEscape String Int => String
      tm_tag_raw_amp s idx n ctx mode acc close_pos
        | close_pos < 0 = tm_scan s (idx + 3) n ctx mode (acc + tm_lbrace + tm_lbrace + "&")
        | otherwise =
          tm_scan s (close_pos + 2) n ctx mode (acc + (tm_lookup ctx (tm_trim (str_slice s (idx + 3) close_pos))))

fn :: tm_tag_comment String Int Int [(String, String)] TmplEscape String Int => String
      tm_tag_comment s _ n ctx mode acc close_pos
        | close_pos < 0 = acc
        | otherwise = tm_scan s (close_pos + 2) n ctx mode acc

fn :: tm_section_active Bool  Bool  => Bool
      tm_section_active True  False =  True
      tm_section_active False True  =  True
      tm_section_active _     _     =  False

fn :: tm_render_section_body String Int (Int, Int) Int [(String, String)] TmplEscape String Bool => String
      tm_render_section_body s _ (_, after_close) n ctx mode acc False =
        tm_scan s after_close n ctx mode acc
      tm_render_section_body s body_start (body_end, after_close) n ctx mode acc True =
        rendered_body = tm_scan s body_start body_end ctx mode ""
        tm_scan s after_close n ctx mode (acc + rendered_body)

fn :: tm_tag_section String Int Int [(String, String)] TmplEscape String Int Bool => String
      tm_tag_section s idx n ctx mode acc open_close inverted
        | open_close < 0 = tm_scan s (idx + 3) n ctx mode acc
        | otherwise =
          tm_render_section_body s (open_close + 2) (tm_find_section_close s (open_close + 2) n (tm_trim (str_slice s (idx + 3) open_close)) 1) n ctx mode acc (tm_section_active (tm_is_truthy ctx (tm_trim (str_slice s (idx + 3) open_close))) inverted)

fn :: tm_tag_var String Int Int [(String, String)] TmplEscape String Int => String
      tm_tag_var s idx n ctx mode acc close_pos
        | close_pos < 0 = tm_scan s (idx + 2) n ctx mode (acc + tm_lbrace + tm_lbrace)
        | otherwise =
          tm_scan s (close_pos + 2) n ctx mode (acc + (tm_escape (tm_lookup ctx (tm_trim (str_slice s (idx + 2) close_pos))) mode))

-- ── Public API ───────────────────────────────────────────────

-- @implements FR-TMPL-001
-- @implements API-TMPL-001
-- @implements DM-Template
-- @mitigates VUL-INPUT-001
fn :: tmpl render with escape String [(String, String)] TmplEscape => String
      tmpl render with escape tmpl ctx mode = tm_scan tmpl 0 (str_len tmpl) ctx mode ""

-- @implements FR-TMPL-001
-- @implements API-TMPL-001
fn :: tmpl render String [(String, String)] => String
      tmpl render tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeNone

-- @implements FR-TMPL-001
-- @implements API-TMPL-001
fn :: tmpl render html String [(String, String)] => String
      tmpl render html tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeHtml

-- @implements FR-TMPL-001
-- @implements API-TMPL-001
fn :: tmpl render latex String [(String, String)] => String
      tmpl render latex tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeLatex
