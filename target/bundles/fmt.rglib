-- ============================================================
-- src/main/ridgun/lib/fmt.rg
-- Configurable 2D Ridgun Source Code Formatter & Multi-Target Syntax Highlighter
-- @implements FR-FMT-001
-- @implements API-FMT-001
-- @implements DM-Formatter
-- @mitigates VUL-INPUT-001
-- Generalises `stable`'s canonical 2D formatter with configurable geometry
-- and optional syntax highlighting for TTY, TrueColor, HTML, CSS, Markdown,
-- Pango Markup, LaTeX Verbatim, and RTF.
-- ============================================================

module :: fmt

type FmtTarget = FmtPlain | FmtTty | FmtTrueColor | FmtHtmlInline | FmtHtmlCss | FmtMarkdown | FmtPango | FmtLatex | FmtRtf

type FmtTheme = FmtThemeNone | FmtThemeDark | FmtThemeLight

type FmtConfig = indent_width: Int, max_align_params: Int, max_line_width: Int, is_aligned: Bool, target_format: FmtTarget, color_theme: FmtTheme

type FmtToken = FmtTok String Int

type FmtSig = NoSig | SigInfo String [String] String String [Int] Int Int

type FmtClause = NoClause | ClauseInfo [String] Bool String

type FmtWhereBind = NoWhereBind | WhereBindInfo String String

-- ── Configuration Constructors ───────────────────────────────

fn :: default fmt config => FmtConfig
      default fmt config = FmtConfig 2 4 80 True FmtPlain FmtThemeNone

fn :: fmt config Int Int Int Bool FmtTarget FmtTheme => FmtConfig
      fmt config indent_w max_params max_w aligned target theme =
        FmtConfig (fmt max 1 indent_w) (fmt max 0 max_params) (fmt max 20 max_w) aligned target theme

-- ── Basic Integer & List Helpers ─────────────────────────────

fn :: fmt max Int Int => Int
      fmt max a b =
        | a >= b = a
        | otherwise = b

fn :: fmt str list len [String] => Int
      fmt str list len [] = 0
      fmt str list len (_:xs) = 1 + (fmt str list len xs)

fn :: fmt str head [String] => String
      fmt str head [] = ""
      fmt str head (x:_) = x

fn :: fmt int at [Int] Int => Int
      fmt int at [] _ = (0 - 1)
      fmt int at (x:_) 0 = x
      fmt int at (_:xs) idx = fmt int at xs (idx - 1)

fn :: fmt spaces Int => String
      fmt spaces n =
        | n <= 0 = ""
        | otherwise = " " + (fmt spaces (n - 1))

-- ── Whitespace & Line Splitting Helpers ──────────────────────

fn :: fmt is hspace Int => Bool
      fmt is hspace c = c == 32 or c == 9 or c == 13

fn :: fmt leading indent loop String Int Int => Int
      fmt leading indent loop s pos len =
        | pos >= len = len
        | (str char at s pos) == 32 or (str char at s pos) == 9 = fmt leading indent loop s (pos + 1) len
        | otherwise = pos

fn :: fmt leading indent String => Int
      fmt leading indent s = fmt leading indent loop s 0 (str len s)

fn :: fmt trim left loop String Int Int => String
      fmt trim left loop s pos len =
        | pos >= len = ""
        | fmt is hspace (str char at s pos) = fmt trim left loop s (pos + 1) len
        | otherwise = str slice s pos len

fn :: fmt trim left String => String
      fmt trim left s = fmt trim left loop s 0 (str len s)

fn :: fmt trim right loop String Int => String
      fmt trim right loop s end_pos =
        | end_pos <= 0 = ""
        | fmt is hspace (str char at s (end_pos - 1)) = fmt trim right loop s (end_pos - 1)
        | otherwise = str slice s 0 end_pos

fn :: fmt trim right String => String
      fmt trim right s = fmt trim right loop s (str len s)

fn :: fmt trim String => String
      fmt trim s = fmt trim left (fmt trim right s)

fn :: fmt split raw lines loop String Int Int Int Int [String] => [String]
      fmt split raw lines loop s pos len line_start quote_st acc =
        | pos >= len and line_start == len = acc
        | pos >= len = acc :: [fmt trim right (str slice s line_start len)]
        | quote_st == 34 and (str char at s pos) == 92 = fmt split raw lines loop s (pos + 2) len line_start 34 acc
        | quote_st == 34 and (str char at s pos) == 34 = fmt split raw lines loop s (pos + 1) len line_start 0 acc
        | quote_st == 34 = fmt split raw lines loop s (pos + 1) len line_start 34 acc
        | quote_st == 39 and (str char at s pos) == 39 = fmt split raw lines loop s (pos + 1) len line_start 0 acc
        | quote_st == 39 = fmt split raw lines loop s (pos + 1) len line_start 39 acc
        | quote_st == 45 and (str char at s pos) == 10 = fmt split raw lines loop s (pos + 1) len (pos + 1) 0 (acc :: [fmt trim right (str slice s line_start pos)])
        | quote_st == 45 = fmt split raw lines loop s (pos + 1) len line_start 45 acc
        | (str char at s pos) == 10 = fmt split raw lines loop s (pos + 1) len (pos + 1) 0 (acc :: [fmt trim right (str slice s line_start pos)])
        | (str char at s pos) == 45 and (pos + 1) < len and (str char at s (pos + 1)) == 45 = fmt split raw lines loop s (pos + 2) len line_start 45 acc
        | (str char at s pos) == 34 = fmt split raw lines loop s (pos + 1) len line_start 34 acc
        | (str char at s pos) == 39 = fmt split raw lines loop s (pos + 1) len line_start 39 acc
        | otherwise = fmt split raw lines loop s (pos + 1) len line_start 0 acc

fn :: fmt split raw lines String => [String]
      fmt split raw lines s = fmt split raw lines loop s 0 (str len s) 0 0 []

fn :: fmt join lines [String] => String
      fmt join lines [] = ""
      fmt join lines (l:[]) = l + (char from code 10)
      fmt join lines (l:ls) = l + (char from code 10) + (fmt join lines ls)

-- ── Quote-Aware Comment Splitting (`-- ...`) ─────────────────

fn :: fmt skip quoted String Int Int Int => Int
      fmt skip quoted s pos len quote_ch =
        | pos >= len = len
        | (str char at s pos) == 92 = fmt skip quoted s (pos + 2) len quote_ch
        | (str char at s pos) == quote_ch = pos + 1
        | otherwise = fmt skip quoted s (pos + 1) len quote_ch

fn :: fmt find comment col String Int Int => Int
      fmt find comment col s pos len =
        | pos >= len = (0 - 1)
        | (str char at s pos) == 34 = fmt find comment col s (fmt skip quoted s (pos + 1) len 34) len
        | (str char at s pos) == 39 = fmt find comment col s (fmt skip quoted s (pos + 1) len 39) len
        | (pos + 1) < len and (str char at s pos) == 45 and (str char at s (pos + 1)) == 45 = pos
        | otherwise = fmt find comment col s (pos + 1) len

fn :: fmt strip comment String => String
      fmt strip comment line =
        c_col = fmt find comment col line 0 (str len line)
        fmt strip comment at line c_col

fn :: fmt strip comment at String Int => String
      fmt strip comment at line c_col =
        | c_col == (0 - 1) = fmt trim right line
        | otherwise = fmt trim right (str slice line 0 c_col)

fn :: fmt extract comment String => String
      fmt extract comment line =
        c_col = fmt find comment col line 0 (str len line)
        fmt extract comment at line c_col

fn :: fmt extract comment at String Int => String
      fmt extract comment at line c_col =
        | c_col == (0 - 1) = ""
        | otherwise = fmt trim right (str slice line c_col (str len line))

-- ── Line Token Scanner (`ridgun--scan-tokens-with-cols`) ─────

fn :: fmt skip hspace String Int Int => Int
      fmt skip hspace s pos len =
        | pos >= len = len
        | fmt is hspace (str char at s pos) = fmt skip hspace s (pos + 1) len
        | otherwise = pos

fn :: fmt scan group end String Int Int Int => Int
      fmt scan group end s pos len depth =
        | pos >= len = len
        | (str char at s pos) == 34 = fmt scan group end s (fmt skip quoted s (pos + 1) len 34) len depth
        | (str char at s pos) == 39 = fmt scan group end s (fmt skip quoted s (pos + 1) len 39) len depth
        | (str char at s pos) == 40 or (str char at s pos) == 91 = fmt scan group end s (pos + 1) len (depth + 1)
        | ((str char at s pos) == 41 or (str char at s pos) == 93) and depth <= 1 = pos + 1
        | (str char at s pos) == 41 or (str char at s pos) == 93 = fmt scan group end s (pos + 1) len (depth - 1)
        | otherwise = fmt scan group end s (pos + 1) len depth

fn :: fmt scan word end String Int Int Int => Int
      fmt scan word end s pos len depth =
        | pos >= len = len
        | depth == 0 and (fmt is hspace (str char at s pos)) = pos
        | (str char at s pos) == 34 = fmt scan word end s (fmt skip quoted s (pos + 1) len 34) len depth
        | (str char at s pos) == 39 = fmt scan word end s (fmt skip quoted s (pos + 1) len 39) len depth
        | (str char at s pos) == 40 or (str char at s pos) == 91 = fmt scan word end s (pos + 1) len (depth + 1)
        | (str char at s pos) == 41 or (str char at s pos) == 93 = fmt scan word end s (pos + 1) len (fmt max 0 (depth - 1))
        | otherwise = fmt scan word end s (pos + 1) len depth

fn :: fmt scan token end String Int Int Int => Int
      fmt scan token end s pos len ch =
        | ch == 34 or ch == 39 = fmt skip quoted s (pos + 1) len ch
        | ch == 40 or ch == 91 = fmt scan group end s (pos + 1) len 1
        | otherwise = fmt scan word end s pos len 0

fn :: fmt scan tokens loop String Int Int [FmtToken] => [FmtToken]
      fmt scan tokens loop s pos len acc =
        p = fmt skip hspace s pos len
        fmt scan tokens at s p len acc

fn :: fmt scan tokens at String Int Int [FmtToken] => [FmtToken]
      fmt scan tokens at s p len acc =
        | p >= len = acc
        | otherwise = fmt scan tokens at step s p len acc (fmt scan token end s p len (str char at s p))

fn :: fmt scan tokens at step String Int Int [FmtToken] Int => [FmtToken]
      fmt scan tokens at step s p len acc end_p =
        tok_s = str slice s p end_p
        fmt scan tokens loop s end_p len (acc :: [FmtTok tok_s p])

fn :: fmt scan tokens String => [FmtToken]
      fmt scan tokens line = fmt scan tokens loop line 0 (str len line) []

-- ── Signature Parsing (`fn ::` / `op ::`) ────────────────────

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
      fmt all type toks [] = True
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

fn :: fmt parse sig line String => FmtSig
      fmt parse sig line line =
        line fmt strip comment -> clean
        line fmt extract comment -> cmt
        clean fmt scan tokens -> toks
        fmt parse sig tokens (fmt leading indent line) clean cmt toks

fn :: fmt parse sig tokens Int String String [FmtToken] => FmtSig
      fmt parse sig tokens _ clean cmt ((FmtTok kind _):(FmtTok "::" _):rest) =
        | kind == "fn" or kind == "op" = fmt finish sig parse clean cmt kind (fmt split sig arrow rest [])
        | otherwise = NoSig
      fmt parse sig tokens 0 clean cmt ((FmtTok w col):rest) =
        | w == "type" or w == "expand" or w == "import" or w == "global" or w == "context" or w == "shared" or w == "hardware" or (str starts with w "@") or (str starts with w "--") or (str starts with w "|") = NoSig
        | otherwise = fmt finish bare sig parse clean cmt (fmt split sig arrow ([FmtTok w col] :: rest) [])
      fmt parse sig tokens _ _ _ _ = NoSig

fn :: fmt finish bare sig parse String String (Bool [String] String Int) => FmtSig
      fmt finish bare sig parse _ _ (False, _, _, _) = NoSig
      fmt finish bare sig parse _ _ (True, [], _, _) = NoSig
      fmt finish bare sig parse clean cmt (True, lhs_strs, arrow_s, arrow_col) =
        | arrow_s == "=>" = fmt finish sig parse clean cmt (fmt infer bare kind lhs_strs) (True, lhs_strs, arrow_s, arrow_col)
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
      fmt append comment core "" = core
      fmt append comment "" cmt = cmt
      fmt append comment core cmt = core + " " + cmt

-- ── Clause & `where` Binding Recognition ─────────────────────

fn :: fmt has fat arrow [FmtToken] => Bool
      fmt has fat arrow [] = False
      fmt has fat arrow ((FmtTok "=>" _):_) = True
      fmt has fat arrow (_:rest) = fmt has fat arrow rest

fn :: fmt is top decl line String => Bool
      fmt is top decl line line =
        ind = fmt leading indent line
        tr = fmt trim line
        toks = fmt scan tokens (fmt strip comment tr)
        fmt is top decl toks ind tr toks

fn :: fmt is top decl toks Int String [FmtToken] => Bool
      fmt is top decl toks _ tr [] = str starts with tr "@"
      fmt is top decl toks ind tr ((FmtTok w col):rest) =
        | str starts with tr "@" = True
        | w == "fn" or w == "op" or w == "type" or w == "expand" or w == "import" or w == "global" or w == "context" or w == "shared" or w == "hardware" = True
        | ind == 0 and (not (str starts with w "--")) and (not (str starts with w "|")) = fmt has fat arrow ([FmtTok w col] :: rest)
        | otherwise = False

fn :: fmt op tokens match [String] [String] => Bool
      fmt op tokens match [] [] = True
      fmt op tokens match (s_tok:s_rest) (c_tok:c_rest) =
        | fmt is sig type tok s_tok = fmt op tokens match s_rest c_rest
        | s_tok == c_tok = fmt op tokens match s_rest c_rest
        | otherwise = False
      fmt op tokens match _ _ = False

fn :: fmt is bare kind String => Bool
      fmt is bare kind kind = kind == "bare_fn" or kind == "bare_op"

fn :: fmt sig base col String => Int
      fmt sig base col kind =
        | fmt is bare kind kind = 0
        | otherwise = 6

fn :: fmt sig base col of FmtSig => Int
      fmt sig base col of (SigInfo kind _ _ _ _ _ _) = fmt sig base col kind
      fmt sig base col of _ = 6

fn :: fmt clause matches sig String [String] [String] => Bool
      fmt clause matches sig _ _ [] = False
      fmt clause matches sig "fn" sig_lhs clause_lhs =
        (fmt str list len clause_lhs) == (fmt str list len sig_lhs) and (fmt str head clause_lhs) == (fmt str head sig_lhs)
      fmt clause matches sig "bare_fn" sig_lhs clause_lhs =
        (fmt str list len clause_lhs) == (fmt str list len sig_lhs) and (fmt str head clause_lhs) == (fmt str head sig_lhs)
      fmt clause matches sig "op" sig_lhs clause_lhs =
        (fmt str list len clause_lhs) == (fmt str list len sig_lhs) and (fmt op tokens match sig_lhs clause_lhs)
      fmt clause matches sig "bare_op" sig_lhs clause_lhs =
        (fmt str list len clause_lhs) == (fmt str list len sig_lhs) and (fmt op tokens match sig_lhs clause_lhs)
      fmt clause matches sig _ _ _ = False

fn :: fmt split clause eq [FmtToken] [String] => [String] Bool Int
      fmt split clause eq [] lhs_acc = (lhs_acc, False, 0)
      fmt split clause eq ((FmtTok "=" col):_) lhs_acc = (lhs_acc, True, col)
      fmt split clause eq ((FmtTok tok _):rest) lhs_acc = fmt split clause eq rest (lhs_acc :: [tok])

fn :: fmt next nonblank is guard [String] => Bool
      fmt next nonblank is guard [] = False
      fmt next nonblank is guard (l:ls) =
        clean = fmt trim (fmt strip comment l)
        fmt check guard line clean ls

fn :: fmt check guard line String [String] => Bool
      fmt check guard line "" ls = fmt next nonblank is guard ls
      fmt check guard line clean _ =
        (str starts with clean "|") and (not (str starts with clean "||"))

fn :: fmt parse clause line FmtSig String Bool => FmtClause
      fmt parse clause line NoSig _ _ = NoClause
      fmt parse clause line (SigInfo kind sig_lhs _ _ _ _ _) line next_is_guard =
        | str contains line (char from code 10) = NoClause
        | otherwise = fmt parse clause clean kind sig_lhs line (fmt strip comment line) (fmt trim (fmt strip comment line)) next_is_guard

fn :: fmt parse clause clean String [String] String String String Bool => FmtClause
      fmt parse clause clean _ _ _ _ "" _ = NoClause
      fmt parse clause clean kind sig_lhs line clean tr next_is_guard =
        | (str starts with tr "|") or (str starts with tr "--") or (fmt is top decl line tr) = NoClause
        | otherwise = fmt check clause split kind sig_lhs line next_is_guard (fmt split clause eq (fmt scan tokens clean) [])

fn :: fmt check clause split String [String] String Bool ([String] Bool Int) => FmtClause
      fmt check clause split kind sig_lhs line next_is_guard (clause_lhs, has_eq, eq_col) =
        | (fmt clause matches sig kind sig_lhs clause_lhs) and (has_eq or next_is_guard) = fmt build clause info line clause_lhs has_eq eq_col
        | otherwise = NoClause

fn :: fmt build clause info String [String] Bool Int => FmtClause
      fmt build clause info line clause_lhs True eq_col =
        rhs = fmt trim (str slice line (eq_col + 1) (str len line))
        ClauseInfo clause_lhs True rhs
      fmt build clause info _ clause_lhs False _ =
        ClauseInfo clause_lhs False ""

fn :: fmt find whr arrow [FmtToken] => Int
      fmt find whr arrow [] = (0 - 1)
      fmt find whr arrow ((FmtTok "->" col):_) = col
      fmt find whr arrow (_:rest) = fmt find whr arrow rest

fn :: fmt parse whr line String Bool => FmtWhereBind
      fmt parse whr line _ False = NoWhereBind
      fmt parse whr line line True =
        clean = fmt strip comment line
        tr = fmt trim clean
        fmt parse whr clean line clean tr

fn :: fmt parse whr clean String String String => FmtWhereBind
      fmt parse whr clean _ _ "" = NoWhereBind
      fmt parse whr clean line clean tr =
        | (str starts with tr "|") or (tr == "where") or (fmt is top decl line tr) = NoWhereBind
        | otherwise = fmt build whr bind line clean (fmt find whr arrow (fmt scan tokens clean))

fn :: fmt build whr bind String String Int => FmtWhereBind
      fmt build whr bind line clean arrow_col =
        | arrow_col == (0 - 1) = NoWhereBind
        | otherwise = fmt check whr nonempty (fmt trim (str slice clean 0 arrow_col)) (fmt trim (str slice line (arrow_col + 2) (str len line)))

fn :: fmt check whr nonempty String String => FmtWhereBind
      fmt check whr nonempty "" _ = NoWhereBind
      fmt check whr nonempty _ "" = NoWhereBind
      fmt check whr nonempty lhs rhs = WhereBindInfo lhs rhs

-- ── Group Column Geometry Calculation (Config-Aware) ─────────

fn :: fmt str lens [String] => [Int]
      fmt str lens [] = []
      fmt str lens (s:ss) = [str len s] :: (fmt str lens ss)

fn :: fmt slot width Int Int => Int
      fmt slot width w s_len =
        | s_len > 18 = w
        | otherwise = fmt max w s_len

fn :: fmt max widths [Int] [String] => [Int]
      fmt max widths [] _ = []
      fmt max widths ws [] = ws
      fmt max widths (w:ws) (s:ss) = [fmt slot width w (str len s)] :: (fmt max widths ws ss)

fn :: fmt build col starts [Int] Int => [Int]
      fmt build col starts [] _ = []
      fmt build col starts (w:ws) cur_col = [cur_col] :: (fmt build col starts ws (cur_col + w + 1))

fn :: fmt end col [Int] Int => Int
      fmt end col [] cur_col = cur_col
      fmt end col (w:ws) cur_col = fmt end col ws (cur_col + w + 1)

fn :: fmt scan group widths FmtSig [String] [Int] Int Bool Int => [Int] Int
      fmt scan group widths _ [] widths max_where _ _ = (widths, max_where)
      fmt scan group widths sig (line:rest) widths max_where in_where ind_w =
        tr_clean = fmt trim (fmt strip comment line)
        next_is_guard = fmt next nonblank is guard rest
        cl = fmt parse clause line sig line next_is_guard
        wb = fmt parse whr line line in_where
        fmt scan group step sig tr_clean rest widths max_where in_where ind_w cl wb

fn :: fmt scan group step FmtSig String [String] [Int] Int Bool Int FmtClause FmtWhereBind => [Int] Int
      fmt scan group step sig _ rest widths max_where _ ind_w (ClauseInfo c_lhs _ _) _ =
        fmt scan group widths sig rest (fmt max widths widths c_lhs) max_where False ind_w
      fmt scan group step sig _ rest widths max_where in_where ind_w NoClause (WhereBindInfo w_lhs _) =
        w_end = (fmt sig base col of sig) + (2 * ind_w) + (str len w_lhs) + 1
        fmt scan group widths sig rest widths (fmt max max_where w_end) in_where ind_w
      fmt scan group step sig tr_clean rest widths max_where in_where ind_w NoClause NoWhereBind =
        | tr_clean == "where" = fmt scan group widths sig rest widths max_where True ind_w
        | str starts with tr_clean "|" = fmt scan group widths sig rest widths max_where False ind_w
        | otherwise = fmt scan group widths sig rest widths max_where in_where ind_w

fn :: fmt compute group geometry FmtSig [String] FmtConfig => FmtSig
      fmt compute group geometry NoSig _ _ = NoSig
      fmt compute group geometry (SigInfo kind lhs_strs arrow_s ret_s _ _ _) group_lines cfg =
        init_widths = fmt str lens lhs_strs
        base_sig = SigInfo kind lhs_strs arrow_s ret_s [] 0 0
        scan_res = fmt scan group widths base_sig group_lines init_widths 0 False (indent_width cfg)
        fmt finish group geometry kind lhs_strs arrow_s ret_s scan_res cfg

fn :: fmt count op params [String] => Int
      fmt count op params [] = 0
      fmt count op params (tok:rest) =
        | fmt is sig type tok tok = 1 + (fmt count op params rest)
        | otherwise = fmt count op params rest

fn :: fmt count sig params String [String] => Int
      fmt count sig params "fn" lhs_strs = (fmt str list len lhs_strs) - 1
      fmt count sig params "bare_fn" lhs_strs = (fmt str list len lhs_strs) - 1
      fmt count sig params _ lhs_strs = fmt count op params lhs_strs

fn :: fmt finish group geometry String [String] String String ([Int] Int) FmtConfig => FmtSig
      fmt finish group geometry kind lhs_strs arrow_s ret_s (widths, max_where) cfg =
        base_col = fmt sig base col kind
        sig_cols = fmt build col starts widths base_col
        end_col = fmt end col widths base_col
        arrow_col = fmt max end_col max_where
        ret_col = arrow_col + (str len arrow_s) + 1
        total_sig_len = ret_col + (str len ret_s)
        num_params = fmt count sig params kind lhs_strs
        fmt select group geometry kind lhs_strs arrow_s ret_s sig_cols arrow_col ret_col num_params total_sig_len cfg

fn :: fmt select group geometry String [String] String String [Int] Int Int Int Int FmtConfig => FmtSig
      fmt select group geometry kind lhs_strs arrow_s ret_s sig_cols arrow_col ret_col num_params total_sig_len cfg =
        | (not (is_aligned cfg)) or num_params > (max_align_params cfg) or total_sig_len > (max_line_width cfg) = SigInfo kind lhs_strs arrow_s ret_s [] 0 0
        | otherwise = SigInfo kind lhs_strs arrow_s ret_s sig_cols arrow_col ret_col

-- ── Line Formatting Functions ────────────────────────────────

fn :: fmt pad lhs tokens [String] [Int] Int String => String
      fmt pad lhs tokens [] _ _ acc = acc
      fmt pad lhs tokens (tok:rest) sig_cols idx acc =
        target_col = fmt int at sig_cols idx
        pad_n = fmt max 1 (target_col - (str len acc))
        fmt pad lhs tokens rest sig_cols (idx + 1) (acc + (fmt spaces pad_n) + tok)

fn :: fmt sig prefix String String => String
      fmt sig prefix "bare_fn" first_tok = first_tok
      fmt sig prefix "bare_op" first_tok = first_tok
      fmt sig prefix kind first_tok = kind + " :: " + first_tok

fn :: fmt format sig line FmtSig => String
      fmt format sig line NoSig = ""
      fmt format sig line (SigInfo _ [] _ _ _ _ _) = ""
      fmt format sig line (SigInfo kind (first_tok:rest_toks) arrow_s ret_s sig_cols arrow_col _) =
        lhs_out = fmt pad lhs tokens rest_toks sig_cols 1 (fmt sig prefix kind first_tok)
        pad_arrow = fmt max 1 (arrow_col - (str len lhs_out))
        lhs_out + (fmt spaces pad_arrow) + arrow_s + " " + ret_s

fn :: fmt format clause line FmtSig [String] Bool String => String
      fmt format clause line _ [] _ _ = ""
      fmt format clause line (SigInfo kind _ _ _ sig_cols arrow_col ret_col) (first_tok:rest_toks) has_eq rhs =
        base_pad = fmt spaces (fmt sig base col kind)
        lhs_out = fmt pad lhs tokens rest_toks sig_cols 1 (base_pad + first_tok)
        fmt finish clause rhs lhs_out has_eq rhs arrow_col ret_col

fn :: fmt finish clause rhs String Bool String Int Int => String
      fmt finish clause rhs lhs_out False _ _ _ = lhs_out
      fmt finish clause rhs lhs_out True "" arrow_col _ =
        pad_eq = fmt max 1 (arrow_col - (str len lhs_out))
        lhs_out + (fmt spaces pad_eq) + "="
      fmt finish clause rhs lhs_out True rhs arrow_col ret_col =
        pad_eq = fmt max 1 (arrow_col - (str len lhs_out))
        with_eq = lhs_out + (fmt spaces pad_eq) + "="
        pad_rhs = fmt max 1 (ret_col - (str len with_eq))
        with_eq + (fmt spaces pad_rhs) + rhs

fn :: fmt format whr line FmtSig String String Int => String
      fmt format whr line NoSig lhs rhs ind_w = (fmt spaces (2 * ind_w)) + lhs + " -> " + rhs
      fmt format whr line (SigInfo kind _ _ _ _ arrow_col ret_col) lhs rhs ind_w =
        lhs_out = (fmt spaces ((fmt sig base col kind) + (2 * ind_w))) + lhs
        pad_arrow = fmt max 1 (arrow_col - (str len lhs_out))
        with_arrow = lhs_out + (fmt spaces pad_arrow) + "->"
        pad_rhs = fmt max 1 (ret_col - (str len with_arrow))
        with_arrow + (fmt spaces pad_rhs) + rhs

-- ── Structural Block & Group Formatting ──────────────────────

fn :: fmt line opens block String => Bool
      fmt line opens block prev_text =
        clean = fmt trim (fmt strip comment prev_text)
        len = str len clean
        fmt check block opener clean len

fn :: fmt check block opener String Int => Bool
      fmt check block opener clean len =
        | len == 0 = False
        | clean == "where" or clean == "do" = True
        | (str char at clean (len - 1)) == 61 and (len < 2 or ((str char at clean (len - 2)) != 61 and (str char at clean (len - 2)) != 33 and (str char at clean (len - 2)) != 60 and (str char at clean (len - 2)) != 62)) = True
        | len >= 6 and (str slice clean (len - 6) len) == " where" = True
        | len >= 3 and (str slice clean (len - 3) len) == " do" = True
        | otherwise = False

fn :: fmt line closes block String => Bool
      fmt line closes block prev_text =
        clean = fmt trim (fmt strip comment prev_text)
        len = str len clean
        (len >= 2 and (str slice clean (len - 2) len) == "|.") or (len >= 3 and (str slice clean (len - 3) len) == "||.")

fn :: fmt guard indent Int Int Int String Int => Int
      fmt guard indent base_g orig_indent prev_indent prev_text ind_w =
        prev_clean = fmt trim (fmt strip comment prev_text)
        fmt guard indent clean base_g orig_indent prev_indent prev_text prev_clean ind_w

fn :: fmt guard indent clean Int Int Int String String Int => Int
      fmt guard indent clean base_g orig_indent prev_indent prev_text prev_clean ind_w =
        | str starts with prev_clean "||" = base_g
        | fmt line opens block prev_text = fmt max base_g (prev_indent + ind_w)
        | fmt line closes block prev_text and orig_indent >= base_g and orig_indent < prev_indent = orig_indent
        | fmt line closes block prev_text = fmt max base_g (prev_indent - ind_w)
        | str starts with prev_clean "|" = fmt max base_g prev_indent
        | otherwise = base_g

fn :: fmt format group body FmtSig [String] Int String Bool FmtConfig => [String]
      fmt format group body _ [] _ _ _ _ = []
      fmt format group body geom (line:rest) prev_indent prev_text in_where cfg =
        tr = fmt trim line
        tr_clean = fmt trim (fmt strip comment line)
        orig_indent = fmt leading indent line
        next_is_guard = fmt next nonblank is guard rest
        cl = fmt parse clause line geom line next_is_guard
        wb = fmt parse whr line line in_where
        fmt format group line geom line tr tr_clean orig_indent rest prev_indent prev_text in_where cfg cl wb

fn :: fmt format group line FmtSig String String String Int [String] Int String Bool FmtConfig FmtClause FmtWhereBind => [String]
      fmt format group line geom _ "" _ _ rest prev_indent prev_text in_where cfg _ _ =
        [""] :: (fmt format group body geom rest prev_indent prev_text in_where cfg)
      fmt format group line geom _ _ _ _ rest _ _ _ cfg (ClauseInfo c_lhs has_eq rhs) _ =
        f_line = fmt format clause line geom c_lhs has_eq rhs
        [f_line] :: (fmt format group body geom rest (fmt sig base col of geom) f_line False cfg)
      fmt format group line geom _ _ _ _ rest _ _ in_where cfg NoClause (WhereBindInfo w_lhs w_rhs) =
        ind_w = indent_width cfg
        f_line = fmt format whr line geom w_lhs w_rhs ind_w
        [f_line] :: (fmt format group body geom rest ((fmt sig base col of geom) + (2 * ind_w)) f_line in_where cfg)
      fmt format group line geom _ tr tr_clean orig_indent rest prev_indent prev_text in_where cfg NoClause NoWhereBind =
        | orig_indent == 0 and (str starts with tr "--") = [tr] :: (fmt format group body geom rest prev_indent prev_text in_where cfg)
        | tr_clean == "where" = [(fmt spaces ((fmt sig base col of geom) + (indent_width cfg))) + tr] :: (fmt format group body geom rest ((fmt sig base col of geom) + (indent_width cfg)) "where" True cfg)
        | str starts with tr_clean "||" = [(fmt spaces ((fmt sig base col of geom) + (indent_width cfg))) + tr] :: (fmt format group body geom rest ((fmt sig base col of geom) + (indent_width cfg)) tr False cfg)
        | str starts with tr_clean "|" = fmt format guard line geom tr orig_indent rest prev_indent prev_text cfg (indent_width cfg)
        | str starts with tr "--" = [fmt indent body line prev_indent prev_text tr (indent_width cfg)] :: (fmt format group body geom rest prev_indent prev_text in_where cfg)
        | otherwise = [fmt indent body line prev_indent prev_text tr (indent_width cfg)] :: (fmt format group body geom rest (fmt next body indent prev_indent prev_text (indent_width cfg)) tr in_where cfg)

fn :: fmt format guard line FmtSig String Int [String] Int String FmtConfig Int => [String]
      fmt format guard line geom tr orig_indent rest prev_indent prev_text cfg ind_w =
        base_g = (fmt sig base col of geom) + ind_w
        g_ind = fmt guard indent base_g orig_indent prev_indent prev_text ind_w
        [(fmt spaces g_ind) + tr] :: (fmt format group body geom rest g_ind tr False cfg)

fn :: fmt next body indent Int String Int => Int
      fmt next body indent prev_indent prev_text ind_w =
        prev_clean = fmt trim (fmt strip comment prev_text)
        fmt next body indent clean prev_indent prev_text prev_clean ind_w

fn :: fmt next body indent clean Int String String Int => Int
      fmt next body indent clean prev_indent prev_text prev_clean ind_w =
        | fmt line opens block prev_text = prev_indent + ind_w
        | fmt line closes block prev_text = fmt max (6 + ind_w) (prev_indent - ind_w)
        | (str starts with prev_clean "|") and (not (str starts with prev_clean "||")) = fmt max (6 + ind_w) (prev_indent - ind_w)
        | otherwise = prev_indent

fn :: fmt indent body line Int String String Int => String
      fmt indent body line prev_indent prev_text tr ind_w =
        ind = fmt next body indent prev_indent prev_text ind_w
        (fmt spaces ind) + tr

-- ── Top-Level File Partitioning into Groups ──────────────────

fn :: fmt take group lines [String] [String] => [String] [String]
      fmt take group lines [] acc = (acc, [])
      fmt take group lines (l:ls) acc =
        | fmt is top decl line l = (acc, [l] :: ls)
        | otherwise = fmt take group lines ls (acc :: [l])

fn :: fmt format top lines [String] Int String FmtConfig => [String]
      fmt format top lines [] _ _ _ = []
      fmt format top lines (line:rest) prev_indent prev_text cfg =
        sig = fmt parse sig line line
        fmt dispatch top line line rest prev_indent prev_text cfg sig

fn :: fmt dispatch top line String [String] Int String FmtConfig FmtSig => [String]
      fmt dispatch top line _ rest _ _ cfg (SigInfo kind lhs_strs arrow_s ret_s cols a_col r_col) =
        grp_split = fmt take group lines rest []
        fmt run sig group (SigInfo kind lhs_strs arrow_s ret_s cols a_col r_col) grp_split cfg
      fmt dispatch top line line rest prev_indent prev_text cfg NoSig =
        tr = fmt trim line
        fmt format non sig top tr rest prev_indent prev_text cfg

fn :: fmt run sig group FmtSig ([String] [String]) FmtConfig => [String]
      fmt run sig group raw_sig (grp_lines, rem_lines) cfg =
        geom = fmt compute group geometry raw_sig grp_lines cfg
        sig_line = fmt format sig line geom
        body_lines = fmt format group body geom grp_lines (fmt sig base col of geom) "" False cfg
        [sig_line] :: body_lines :: (fmt format top lines rem_lines 0 "" cfg)

fn :: fmt format non sig top String [String] Int String FmtConfig => [String]
      fmt format non sig top "" rest prev_indent prev_text cfg =
        [""] :: (fmt format top lines rest prev_indent prev_text cfg)
      fmt format non sig top tr rest prev_indent prev_text cfg =
        | fmt is top decl line tr = [tr] :: (fmt format top lines rest 0 tr cfg)
        | str starts with tr "--" = [tr] :: (fmt format top lines rest prev_indent prev_text cfg)
        | otherwise = [fmt indent body line prev_indent prev_text tr (indent_width cfg)] :: (fmt format top lines rest (fmt next body indent prev_indent prev_text (indent_width cfg)) tr cfg)

-- ── Lexical Token Classification & Syntax Highlighting ───────

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

-- ── Escaping for HTML, Pango, LaTeX, and RTF ─────────────────

fn :: fmt escape html loop String Int Int String => String
      fmt escape html loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 38 = fmt escape html loop s (pos + 1) len (acc + "&amp;")
        | (str char at s pos) == 60 = fmt escape html loop s (pos + 1) len (acc + "&lt;")
        | (str char at s pos) == 62 = fmt escape html loop s (pos + 1) len (acc + "&gt;")
        | otherwise = fmt escape html loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: fmt escape html String => String
      fmt escape html s = fmt escape html loop s 0 (str len s) ""

fn :: fmt escape latex loop String Int Int String => String
      fmt escape latex loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 92 = fmt escape latex loop s (pos + 1) len (acc + (char from code 92) + "textbackslash" + (char from code 123) + (char from code 125))
        | (str char at s pos) == 123 = fmt escape latex loop s (pos + 1) len (acc + (char from code 92) + (char from code 123))
        | (str char at s pos) == 125 = fmt escape latex loop s (pos + 1) len (acc + (char from code 92) + (char from code 125))
        | otherwise = fmt escape latex loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: fmt escape latex String => String
      fmt escape latex s = fmt escape latex loop s 0 (str len s) ""

fn :: fmt escape rtf loop String Int Int String => String
      fmt escape rtf loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 92 = fmt escape rtf loop s (pos + 1) len (acc + (char from code 92) + (char from code 92))
        | (str char at s pos) == 123 = fmt escape rtf loop s (pos + 1) len (acc + (char from code 92) + (char from code 123))
        | (str char at s pos) == 125 = fmt escape rtf loop s (pos + 1) len (acc + (char from code 92) + (char from code 125))
        | otherwise = fmt escape rtf loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: fmt escape rtf String => String
      fmt escape rtf s = fmt escape rtf loop s 0 (str len s) ""

fn :: fmt escape target String FmtTarget => String
      fmt escape target s FmtHtmlInline = fmt escape html s
      fmt escape target s FmtHtmlCss = fmt escape html s
      fmt escape target s FmtPango = fmt escape html s
      fmt escape target s FmtLatex = fmt escape latex s
      fmt escape target s FmtRtf = fmt escape rtf s
      fmt escape target s _ = s

-- ── Palette & Span Rendering per Target and Theme ────────────

fn :: fmt cat css class String => String
      fmt cat css class "keyword" = "rg-kw"
      fmt cat css class "logic" = "rg-logic"
      fmt cat css class "function" = "rg-fn"
      fmt cat css class "type" = "rg-type"
      fmt cat css class "string" = "rg-str"
      fmt cat css class "interp" = "rg-interp"
      fmt cat css class "number" = "rg-num"
      fmt cat css class "bool" = "rg-bool"
      fmt cat css class "operator" = "rg-op"
      fmt cat css class "pragma" = "rg-pragma"
      fmt cat css class "comment" = "rg-cmt"
      fmt cat css class _ = ""

fn :: fmt cat ansi16 String => String
      fmt cat ansi16 "keyword" = "1;35"
      fmt cat ansi16 "logic" = "1;35"
      fmt cat ansi16 "function" = "1;34"
      fmt cat ansi16 "type" = "33"
      fmt cat ansi16 "string" = "32"
      fmt cat ansi16 "interp" = "36"
      fmt cat ansi16 "number" = "36"
      fmt cat ansi16 "bool" = "1;36"
      fmt cat ansi16 "operator" = "36"
      fmt cat ansi16 "pragma" = "1;32"
      fmt cat ansi16 "comment" = "90"
      fmt cat ansi16 _ = ""

fn :: fmt cat rgb String FmtTheme => String
      fmt cat rgb _ FmtThemeNone = ""
      fmt cat rgb "keyword" FmtThemeDark = "198;120;221"
      fmt cat rgb "logic" FmtThemeDark = "198;120;221"
      fmt cat rgb "function" FmtThemeDark = "97;175;239"
      fmt cat rgb "type" FmtThemeDark = "229;192;123"
      fmt cat rgb "string" FmtThemeDark = "152;195;121"
      fmt cat rgb "interp" FmtThemeDark = "86;182;194"
      fmt cat rgb "number" FmtThemeDark = "209;154;102"
      fmt cat rgb "bool" FmtThemeDark = "209;154;102"
      fmt cat rgb "operator" FmtThemeDark = "86;182;194"
      fmt cat rgb "pragma" FmtThemeDark = "127;132;142"
      fmt cat rgb "comment" FmtThemeDark = "92;99;112"
      fmt cat rgb "keyword" FmtThemeLight = "166;38;164"
      fmt cat rgb "logic" FmtThemeLight = "166;38;164"
      fmt cat rgb "function" FmtThemeLight = "64;120;242"
      fmt cat rgb "type" FmtThemeLight = "193;132;1"
      fmt cat rgb "string" FmtThemeLight = "80;161;79"
      fmt cat rgb "interp" FmtThemeLight = "1;132;188"
      fmt cat rgb "number" FmtThemeLight = "152;104;1"
      fmt cat rgb "bool" FmtThemeLight = "152;104;1"
      fmt cat rgb "operator" FmtThemeLight = "1;132;188"
      fmt cat rgb "pragma" FmtThemeLight = "105;108;119"
      fmt cat rgb "comment" FmtThemeLight = "160;161;167"
      fmt cat rgb _ _ = ""

fn :: fmt cat hex String FmtTheme => String
      fmt cat hex _ FmtThemeNone = ""
      fmt cat hex "keyword" FmtThemeDark = "c678dd"
      fmt cat hex "logic" FmtThemeDark = "c678dd"
      fmt cat hex "function" FmtThemeDark = "61afef"
      fmt cat hex "type" FmtThemeDark = "e5c07b"
      fmt cat hex "string" FmtThemeDark = "98c379"
      fmt cat hex "interp" FmtThemeDark = "56b6c2"
      fmt cat hex "number" FmtThemeDark = "d19a66"
      fmt cat hex "bool" FmtThemeDark = "d19a66"
      fmt cat hex "operator" FmtThemeDark = "56b6c2"
      fmt cat hex "pragma" FmtThemeDark = "7f848e"
      fmt cat hex "comment" FmtThemeDark = "5c6370"
      fmt cat hex "keyword" FmtThemeLight = "a626a4"
      fmt cat hex "logic" FmtThemeLight = "a626a4"
      fmt cat hex "function" FmtThemeLight = "4078f2"
      fmt cat hex "type" FmtThemeLight = "c18401"
      fmt cat hex "string" FmtThemeLight = "50a14f"
      fmt cat hex "interp" FmtThemeLight = "0184bc"
      fmt cat hex "number" FmtThemeLight = "986801"
      fmt cat hex "bool" FmtThemeLight = "986801"
      fmt cat hex "operator" FmtThemeLight = "0184bc"
      fmt cat hex "pragma" FmtThemeLight = "696c77"
      fmt cat hex "comment" FmtThemeLight = "a0a1a7"
      fmt cat hex _ _ = ""

fn :: fmt cat is bold String => Bool
      fmt cat is bold "keyword" = True
      fmt cat is bold "logic" = True
      fmt cat is bold "function" = True
      fmt cat is bold "bool" = True
      fmt cat is bold "pragma" = True
      fmt cat is bold _ = False

fn :: fmt cat rtf idx String => String
      fmt cat rtf idx "keyword" = "1"
      fmt cat rtf idx "logic" = "1"
      fmt cat rtf idx "function" = "2"
      fmt cat rtf idx "type" = "3"
      fmt cat rtf idx "string" = "4"
      fmt cat rtf idx "interp" = "5"
      fmt cat rtf idx "number" = "6"
      fmt cat rtf idx "bool" = "6"
      fmt cat rtf idx "operator" = "5"
      fmt cat rtf idx "pragma" = "7"
      fmt cat rtf idx "comment" = "8"
      fmt cat rtf idx _ = ""

fn :: fmt span css String String => String
      fmt span css esc "" = esc
      fmt span css esc cls = "<span class=\"" + cls + "\">" + esc + "</span>"

fn :: fmt span tty String String => String
      fmt span tty text "" = text
      fmt span tty text code = (char from code 27) + "[" + code + "m" + text + (char from code 27) + "[0m"

fn :: fmt span truecolor String String Bool => String
      fmt span truecolor text "" _ = text
      fmt span truecolor text rgb True = (char from code 27) + "[1;38;2;" + rgb + "m" + text + (char from code 27) + "[0m"
      fmt span truecolor text rgb False = (char from code 27) + "[38;2;" + rgb + "m" + text + (char from code 27) + "[0m"

fn :: fmt span html inline String String Bool => String
      fmt span html inline esc "" _ = esc
      fmt span html inline esc hex True = "<span style=\"color:#" + hex + ";font-weight:bold\">" + esc + "</span>"
      fmt span html inline esc hex False = "<span style=\"color:#" + hex + "\">" + esc + "</span>"

fn :: fmt span pango String String Bool => String
      fmt span pango esc "" _ = esc
      fmt span pango esc hex True = "<span foreground=\"#" + hex + "\" weight=\"bold\">" + esc + "</span>"
      fmt span pango esc hex False = "<span foreground=\"#" + hex + "\">" + esc + "</span>"

fn :: fmt span latex String String Bool => String
      fmt span latex esc "" _ = esc
      fmt span latex esc hex True =
        bs = char from code 92
        lb = char from code 123
        rb = char from code 125
        bs + "textbf" + lb + bs + "textcolor[HTML]" + lb + hex + rb + lb + esc + rb + rb
      fmt span latex esc hex False =
        bs = char from code 92
        lb = char from code 123
        rb = char from code 125
        bs + "textcolor[HTML]" + lb + hex + rb + lb + esc + rb

fn :: fmt span rtf String String Bool => String
      fmt span rtf esc "" _ = esc
      fmt span rtf esc cidx True =
        (char from code 123) + (char from code 92) + "cf" + cidx + (char from code 92) + "b " + esc + (char from code 125)
      fmt span rtf esc cidx False =
        (char from code 123) + (char from code 92) + "cf" + cidx + " " + esc + (char from code 125)

fn :: fmt render span String String FmtTarget FmtTheme => String
      fmt render span text "plain" target _ = fmt escape target text target
      fmt render span text _ FmtPlain _ = text
      fmt render span text _ FmtMarkdown _ = text
      fmt render span text cat FmtHtmlCss _ = fmt span css (fmt escape html text) (fmt cat css class cat)
      fmt render span text _ target FmtThemeNone = fmt escape target text target
      fmt render span text cat FmtTty _ = fmt span tty text (fmt cat ansi16 cat)
      fmt render span text cat FmtTrueColor theme = fmt span truecolor text (fmt cat rgb cat theme) (fmt cat is bold cat)
      fmt render span text cat FmtHtmlInline theme = fmt span html inline (fmt escape html text) (fmt cat hex cat theme) (fmt cat is bold cat)
      fmt render span text cat FmtPango theme = fmt span pango (fmt escape html text) (fmt cat hex cat theme) (fmt cat is bold cat)
      fmt render span text cat FmtLatex theme = fmt span latex (fmt escape latex text) (fmt cat hex cat theme) (fmt cat is bold cat)
      fmt render span text cat FmtRtf _ = fmt span rtf (fmt escape rtf text) (fmt cat rtf idx cat) (fmt cat is bold cat)

-- ── Single-Line Scanner & Highlighter ────────────────────────

fn :: fmt scan ident end String Int Int => Int
      fmt scan ident end s pos len =
        | pos >= len = len
        | fmt is ident char (str char at s pos) = fmt scan ident end s (pos + 1) len
        | otherwise = pos

fn :: fmt scan space end String Int Int => Int
      fmt scan space end s pos len =
        | pos >= len = len
        | fmt is hspace (str char at s pos) = fmt scan space end s (pos + 1) len
        | otherwise = pos

fn :: fmt find close brace String Int Int => Int
      fmt find close brace s pos len =
        | pos >= len = (0 - 1)
        | (str char at s pos) == 125 = pos + 1
        | (str char at s pos) == 34 or (str char at s pos) == 123 = (0 - 1)
        | otherwise = fmt find close brace s (pos + 1) len

fn :: fmt render nonempty String String FmtTarget FmtTheme => String
      fmt render nonempty "" _ _ _ = ""
      fmt render nonempty seg_s cat target theme = fmt render span seg_s cat target theme

fn :: fmt highlight dquote brace String Int Int Int Int FmtTarget FmtTheme String => String
      fmt highlight dquote brace s pos end_pos seg_start close_p target theme acc =
        | close_p == (0 - 1) = fmt highlight dquote loop s (pos + 1) end_pos seg_start target theme acc
        | otherwise = fmt highlight dquote loop s close_p end_pos close_p target theme (acc + (fmt render nonempty (str slice s seg_start pos) "string" target theme) + (fmt render span (str slice s pos close_p) "interp" target theme))

fn :: fmt highlight dquote loop String Int Int Int FmtTarget FmtTheme String => String
      fmt highlight dquote loop s pos end_pos seg_start target theme acc =
        | pos >= end_pos = acc + (fmt render nonempty (str slice s seg_start end_pos) "string" target theme)
        | (str char at s pos) == 92 = fmt highlight dquote loop s (pos + 2) end_pos seg_start target theme acc
        | (str char at s pos) == 123 =
          fmt highlight dquote brace s pos end_pos seg_start (fmt find close brace s (pos + 1) (end_pos - 1)) target theme acc
        | otherwise = fmt highlight dquote loop s (pos + 1) end_pos seg_start target theme acc

fn :: fmt multi op at String Int Int => String
      fmt multi op at s pos len =
        | (pos + 5) <= len and (str slice s pos (pos + 5)) == "||map" = "||map"
        | (pos + 2) <= len and ((str slice s pos (pos + 2)) == "::" or (str slice s pos (pos + 2)) == "=>" or (str slice s pos (pos + 2)) == "->" or (str slice s pos (pos + 2)) == "||" or (str slice s pos (pos + 2)) == "==" or (str slice s pos (pos + 2)) == "!=" or (str slice s pos (pos + 2)) == "<=" or (str slice s pos (pos + 2)) == ">=") = str slice s pos (pos + 2)
        | otherwise = ""

fn :: fmt is single op Int => Bool
      fmt is single op ch =
        ch == 61 or ch == 124 or ch == 64 or ch == 43 or ch == 45 or ch == 42 or ch == 47 or ch == 37 or ch == 60 or ch == 62

fn :: fmt comment cat String => String
      fmt comment cat cmt =
        | (str starts with cmt "-- @implements") or (str starts with cmt "-- @tests") or (str starts with cmt "-- @mitigates") = "pragma"
        | otherwise = "comment"

fn :: fmt hl space step String Int Int Bool FmtTarget FmtTheme String Int => String
      fmt hl space step s pos len in_fn target theme acc sp_end =
        sp_s = fmt escape target (str slice s pos sp_end) target
        fmt highlight line loop s sp_end len in_fn target theme (acc + sp_s)

fn :: fmt hl dquote step String Int Int FmtTarget FmtTheme String Int => String
      fmt hl dquote step s pos len target theme acc q_end =
        str_out = fmt highlight dquote loop s pos q_end pos target theme ""
        fmt highlight line loop s q_end len False target theme (acc + str_out)

fn :: fmt hl squote step String Int Int FmtTarget FmtTheme String Int => String
      fmt hl squote step s pos len target theme acc q_end =
        str_out = fmt render span (str slice s pos q_end) "string" target theme
        fmt highlight line loop s q_end len False target theme (acc + str_out)

fn :: fmt hl pragma step String Int Int FmtTarget FmtTheme String Int => String
      fmt hl pragma step s pos len target theme acc w_end =
        prag_out = fmt render span (str slice s pos w_end) "pragma" target theme
        fmt highlight line loop s w_end len False target theme (acc + prag_out)

fn :: fmt hl mop step String Int Int FmtTarget FmtTheme String String => String
      fmt hl mop step s pos len target theme acc mop =
        op_out = fmt render span mop "operator" target theme
        fmt highlight line loop s (pos + (str len mop)) len (mop == "::") target theme (acc + op_out)

fn :: fmt hl ident step String Int Int Bool FmtTarget FmtTheme String Int => String
      fmt hl ident step s pos len the_in_fn target theme acc w_end =
        w = str slice s pos w_end
        cat = fmt classify word w the_in_fn
        w_out = fmt render span w cat target theme
        fmt highlight line loop s w_end len (the_in_fn and cat == "function") target theme (acc + w_out)

fn :: fmt highlight line loop String Int Int Bool FmtTarget FmtTheme String => String
      fmt highlight line loop s pos len the_in_fn target theme acc =
        | pos >= len = acc
        | fmt is hspace (str char at s pos) = fmt hl space step s pos len the_in_fn target theme acc (fmt scan space end s pos len)
        | (pos + 1) < len and (str char at s pos) == 45 and (str char at s (pos + 1)) == 45 = acc + (fmt render span (str slice s pos len) (fmt comment cat (str slice s pos len)) target theme)
        | (str char at s pos) == 34 = fmt hl dquote step s pos len target theme acc (fmt skip quoted s (pos + 1) len 34)
        | (str char at s pos) == 39 = fmt hl squote step s pos len target theme acc (fmt skip quoted s (pos + 1) len 39)
        | (str char at s pos) == 64 and (pos + 1) < len and (fmt is ident char (str char at s (pos + 1))) = fmt hl pragma step s pos len target theme acc (fmt scan ident end s (pos + 1) len)
        | (fmt multi op at s pos len) != "" = fmt hl mop step s pos len target theme acc (fmt multi op at s pos len)
        | fmt is ident char (str char at s pos) = fmt hl ident step s pos len the_in_fn target theme acc (fmt scan ident end s pos len)
        | fmt is single op (str char at s pos) = fmt highlight line loop s (pos + 1) len False target theme (acc + (fmt render span (str slice s pos (pos + 1)) "operator" target theme))
        | otherwise = fmt highlight line loop s (pos + 1) len False target theme (acc + (fmt escape target (str slice s pos (pos + 1)) target))

fn :: fmt line starts clause String => Bool
      fmt line starts clause line =
        ind = fmt leading indent line
        tr = fmt trim line
        ind == 6 and tr != "" and (fmt is lower (str char at tr 0)) and (not (fmt is keyword (fmt str head (fmt tok strs (fmt scan tokens tr)))))

fn :: fmt tok strs [FmtToken] => [String]
      fmt tok strs [] = []
      fmt tok strs ((FmtTok s _):rest) = [s] :: (fmt tok strs rest)

fn :: fmt highlight line String FmtTarget FmtTheme => String
      fmt highlight line line FmtPlain _ = line
      fmt highlight line line FmtMarkdown _ = line
      fmt highlight line line target theme =
        fmt highlight line loop line 0 (str len line) (fmt line starts clause line) target theme ""

fn :: fmt highlight lines [String] FmtTarget FmtTheme => [String]
      fmt highlight lines [] _ _ = []
      fmt highlight lines (l:ls) target theme =
        [fmt highlight line l target theme] :: (fmt highlight lines ls target theme)

fn :: fmt join rtf lines [String] => String
      fmt join rtf lines [] = ""
      fmt join rtf lines (l:[]) = l + "\\line" + (char from code 10)
      fmt join rtf lines (l:ls) = l + "\\line" + (char from code 10) + (fmt join rtf lines ls)

-- ── Document Wrappers per Target ─────────────────────────────

fn :: fmt html pre open FmtTheme => String
      fmt html pre open FmtThemeLight = "<pre class=\"ridgun-code\" style=\"background:#fafafa;color:#383a42;padding:12px;border-radius:6px;overflow-x:auto\"><code class=\"language-ridgun\">"
      fmt html pre open FmtThemeDark = "<pre class=\"ridgun-code\" style=\"background:#282c34;color:#abb2bf;padding:12px;border-radius:6px;overflow-x:auto\"><code class=\"language-ridgun\">"
      fmt html pre open FmtThemeNone = "<pre class=\"ridgun-code\"><code class=\"language-ridgun\">"

fn :: fmt rtf colortbl FmtTheme => String
      fmt rtf colortbl FmtThemeLight =
        '{\colortbl;\red166\green38\blue164;\red64\green120\blue242;\red193\green132\blue1;\red80\green161\blue79;\red1\green132\blue188;\red152\green104\blue1;\red105\green108\blue119;\red160\green161\blue167;}'
      fmt rtf colortbl _ =
        '{\colortbl;\red198\green120\blue221;\red97\green175\blue239;\red229\green192\blue123;\red152\green195\blue121;\red86\green182\blue194;\red209\green154\blue102;\red127\green132\blue142;\red92\green99\blue112;}'

fn :: fmt wrap target doc [String] FmtTarget FmtTheme => String
      fmt wrap target doc lines FmtPlain _ = fmt join lines lines
      fmt wrap target doc lines FmtTty _ = fmt join lines lines
      fmt wrap target doc lines FmtTrueColor _ = fmt join lines lines
      fmt wrap target doc lines FmtHtmlInline theme =
        (fmt html pre open theme) + (char from code 10) + (fmt join lines lines) + "</code></pre>" + (char from code 10)
      fmt wrap target doc lines FmtHtmlCss _ =
        "<pre class=\"ridgun-code\"><code class=\"language-ridgun\">" + (char from code 10) + (fmt join lines lines) + "</code></pre>" + (char from code 10)
      fmt wrap target doc lines FmtMarkdown _ =
        "```ridgun" + (char from code 10) + (fmt join lines lines) + "```" + (char from code 10)
      fmt wrap target doc lines FmtPango _ =
        "<tt>" + (char from code 10) + (fmt join lines lines) + "</tt>" + (char from code 10)
      fmt wrap target doc lines FmtLatex _ =
        '\begin{Verbatim}[commandchars=\\\{\}]' + (char from code 10) + (fmt join lines lines) + '\end{Verbatim}' + (char from code 10)
      fmt wrap target doc lines FmtRtf theme =
        '{\rtf1\ansi\deff0{\fonttbl{\f0 Courier New;}}' + (fmt rtf colortbl theme) + '\f0\fs20 ' + (char from code 10) + (fmt join rtf lines lines) + '}' + (char from code 10)

fn :: fmt html stylesheet FmtTheme => String
      fmt html stylesheet FmtThemeLight =
        nl = char from code 10
        '<style>' + nl + '.ridgun-code { background: #fafafa; color: #383a42; padding: 12px; border-radius: 6px; overflow-x: auto; }' + nl + '.rg-kw, .rg-logic { color: #a626a4; font-weight: bold; }' + nl + '.rg-fn { color: #4078f2; font-weight: bold; }' + nl + '.rg-type { color: #c18401; }' + nl + '.rg-str { color: #50a14f; }' + nl + '.rg-interp, .rg-op { color: #0184bc; }' + nl + '.rg-num { color: #986801; }' + nl + '.rg-bool { color: #986801; font-weight: bold; }' + nl + '.rg-pragma { color: #696c77; font-weight: bold; }' + nl + '.rg-cmt { color: #a0a1a7; font-style: italic; }' + nl + '</style>' + nl
      fmt html stylesheet _ =
        nl = char from code 10
        '<style>' + nl + '.ridgun-code { background: #282c34; color: #abb2bf; padding: 12px; border-radius: 6px; overflow-x: auto; }' + nl + '.rg-kw, .rg-logic { color: #c678dd; font-weight: bold; }' + nl + '.rg-fn { color: #61afef; font-weight: bold; }' + nl + '.rg-type { color: #e5c07b; }' + nl + '.rg-str { color: #98c379; }' + nl + '.rg-interp, .rg-op { color: #56b6c2; }' + nl + '.rg-num { color: #d19a66; }' + nl + '.rg-bool { color: #d19a66; font-weight: bold; }' + nl + '.rg-pragma { color: #7f848e; font-weight: bold; }' + nl + '.rg-cmt { color: #5c6370; font-style: italic; }' + nl + '</style>' + nl

-- ── Public Entry Points ──────────────────────────────────────

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
