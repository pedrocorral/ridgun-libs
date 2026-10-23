-- ============================================================
-- src/main/ridgun/lib/regex.rg
-- Pure-Ridgun Linear-Time Thompson NFA Regular Expression Engine (REGEX)
-- @implements FR-REGEX-001
-- @implements API-REGEX-001
-- @implements DM-Regex
-- @mitigates VUL-INPUT-001
-- ============================================================

type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String

type ReNode = ReEmpty | ReChar Int | ReAny | ReClass Bool [Int] | ReShort Int | ReBol | ReEol | ReStar ReNode | RePlus ReNode | ReOpt ReNode | ReSeq ReNode ReNode | ReAlt ReNode ReNode

type ReParseRes = ReParseRes ReNode Int

type NfaInst = InstChar Int Int | InstAny Int | InstClass Bool [Int] Int | InstShort Int Int | InstBol Int | InstEol Int | InstSplit Int Int | InstJump Int | InstMatch

-- ── Character Class & Shorthand Helpers ──────────────────────

fn :: re_is_digit Int => Bool
      re_is_digit c   =  c >= 48 AND c <= 57

fn :: re_is_word Int => Bool
      re_is_word c   =  (c >= 48 AND c <= 57) OR (c >= 65 AND c <= 90) OR (c >= 97 AND c <= 122) OR c == 95

fn :: re_is_space Int => Bool
      re_is_space c   =  c == 32 OR c == 9 OR c == 10 OR c == 13 OR c == 11 OR c == 12

fn :: re_match_short Int Int => Bool
      re_match_short 100 c   =  re_is_digit c
      re_match_short 68  c   =  NOT (re_is_digit c)
      re_match_short 119 c   =  re_is_word c
      re_match_short 87  c   =  NOT (re_is_word c)
      re_match_short 115 c   =  re_is_space c
      re_match_short 83  c   =  NOT (re_is_space c)
      re_match_short _   _   =  False

fn :: re_in_ranges Int [Int]      => Bool
      re_in_ranges _   []         =  False
      re_in_ranges _   (_:[])     =  False
      re_in_ranges c   (lo:hi:rs)
        | c >= lo AND c <= hi = True
        | otherwise = re_in_ranges c rs

-- ── Regex Recursive-Descent Parser (`pattern_str` -> `ReNode`) ─

fn :: re_escape_char Int => ReNode
      re_escape_char 100 =  ReShort 100
      re_escape_char 68  =  ReShort 68
      re_escape_char 119 =  ReShort 119
      re_escape_char 87  =  ReShort 87
      re_escape_char 115 =  ReShort 115
      re_escape_char 83  =  ReShort 83
      re_escape_char 110 =  ReChar 10
      re_escape_char 114 =  ReChar 13
      re_escape_char 116 =  ReChar 9
      re_escape_char c   =  ReChar c

fn :: re_class_char String Int Int => (Int Int)
      re_class_char pat    pos len
        | (str_char_at pat pos) == 92 AND (pos + 1) < len AND (str_char_at pat (pos + 1)) == 110 = (10, pos + 2)
        | (str_char_at pat pos) == 92 AND (pos + 1) < len AND (str_char_at pat (pos + 1)) == 116 = (9, pos + 2)
        | (str_char_at pat pos) == 92 AND (pos + 1) < len AND (str_char_at pat (pos + 1)) == 114 = (13, pos + 2)
        | (str_char_at pat pos) == 92 AND (pos + 1) < len = (str_char_at pat (pos + 1), pos + 2)
        | otherwise = (str_char_at pat pos, pos + 1)

fn :: re_fst_int (Int Int) => Int
      re_fst_int (a, _)    =  a

fn :: re_snd_int (Int Int) => Int
      re_snd_int (_, b)    =  b

fn :: re_parse_class_items String Int Int [Int] => ([Int] Int)
      re_parse_class_items pat    pos len acc
        | pos >= len = (acc, len)
        | (str_char_at pat pos) == 93 = (acc, pos + 1)
        | otherwise = re_parse_class_item_step pat pos len acc

fn :: re_parse_class_item_step String Int Int [Int] => ([Int] Int)
      re_parse_class_item_step pat    pos len acc   =
        c1_pair = re_class_char pat pos len
        c1 = re_fst_int c1_pair
        next_p = re_snd_int c1_pair
        re_parse_class_range_check pat next_p len c1 acc

fn :: re_parse_class_range_check String Int Int Int [Int] => ([Int] Int)
      re_parse_class_range_check pat next_p len c1 acc
        | (next_p + 1) < len AND (str_char_at pat next_p) == 45 AND (str_char_at pat (next_p + 1)) != 93 = re_parse_class_range_hi pat (next_p + 1) len c1 acc
        | otherwise = re_parse_class_items pat next_p len (acc :: [c1, c1])

fn :: re_parse_class_range_hi String Int Int Int [Int] => ([Int] Int)
      re_parse_class_range_hi pat pos2 len c1 acc =
        c2_pair = re_class_char pat pos2 len
        c2 = re_fst_int c2_pair
        after_p = re_snd_int c2_pair
        re_parse_class_items pat after_p len (acc :: [c1, c2])

fn :: re_fst_ranges ([Int] Int) => [Int]
      re_fst_ranges (r, _)      =  r

fn :: re_snd_pos ([Int] Int) => Int
      re_snd_pos (_, p)      =  p

fn :: re_parse_class String Int Int => ReParseRes
      re_parse_class pat    pos len
        | pos < len AND (str_char_at pat pos) == 94 = re_finish_class True (re_parse_class_items pat (pos + 1) len [])
        | otherwise = re_finish_class False (re_parse_class_items pat pos len [])

fn :: re_finish_class Bool ([Int] Int) => ReParseRes
      re_finish_class neg  res         =  ReParseRes (ReClass neg (re_fst_ranges res)) (re_snd_pos res)

fn :: re_res_node ReParseRes => ReNode
      re_res_node (ReParseRes node _) = node

fn :: re_res_pos ReParseRes         => Int
      re_res_pos (ReParseRes _ pos) =  pos

fn :: re_parse_group String Int Int => ReParseRes
      re_parse_group pat    pos len =
        sub = re_parse_alt pat pos len
        sub_p = re_res_pos sub
        re_close_group (re_res_node sub) pat sub_p len

fn :: re_close_group ReNode String Int Int => ReParseRes
      re_close_group node   pat    pos len
        | pos < len AND (str_char_at pat pos) == 41 = ReParseRes node (pos + 1)
        | otherwise = ReParseRes node pos

fn :: re_parse_atom String Int Int => ReParseRes
      re_parse_atom pat    pos len
        | pos >= len = ReParseRes ReEmpty pos
        | (str_char_at pat pos) == 40 = re_parse_group pat (pos + 1) len
        | (str_char_at pat pos) == 91 = re_parse_class pat (pos + 1) len
        | (str_char_at pat pos) == 46 = ReParseRes ReAny (pos + 1)
        | (str_char_at pat pos) == 94 = ReParseRes ReBol (pos + 1)
        | (str_char_at pat pos) == 36 = ReParseRes ReEol (pos + 1)
        | (str_char_at pat pos) == 92 AND (pos + 1) < len = ReParseRes (re_escape_char (str_char_at pat (pos + 1))) (pos + 2)
        | otherwise = ReParseRes (ReChar (str_char_at pat pos)) (pos + 1)

fn :: re_parse_postfix ReNode String Int Int => ReParseRes
      re_parse_postfix node   pat    pos len
        | pos < len AND (str_char_at pat pos) == 42 = re_parse_postfix (ReStar node) pat (pos + 1) len
        | pos < len AND (str_char_at pat pos) == 43 = re_parse_postfix (RePlus node) pat (pos + 1) len
        | pos < len AND (str_char_at pat pos) == 63 = re_parse_postfix (ReOpt node) pat (pos + 1) len
        | otherwise = ReParseRes node pos

fn :: re_parse_factor String Int Int => ReParseRes
      re_parse_factor pat    pos len =
        atom = re_parse_atom pat pos len
        re_parse_postfix (re_res_node atom) pat (re_res_pos atom) len

fn :: re_is_seq_stop Int => Bool
      re_is_seq_stop c   =  c == 124 OR c == 41

fn :: re_parse_seq_loop ReNode String Int Int => ReParseRes
      re_parse_seq_loop acc    pat    pos len
        | pos >= len = ReParseRes acc pos
        | re_is_seq_stop (str_char_at pat pos) = ReParseRes acc pos
        | otherwise = re_parse_seq_step acc pat pos len

fn :: re_parse_seq_step ReNode String Int Int => ReParseRes
      re_parse_seq_step acc    pat    pos len =
        next_f = re_parse_factor pat pos len
        re_parse_seq_loop (ReSeq acc (re_res_node next_f)) pat (re_res_pos next_f) len

fn :: re_parse_seq String Int Int => ReParseRes
      re_parse_seq pat    pos len
        | pos >= len = ReParseRes ReEmpty pos
        | re_is_seq_stop (str_char_at pat pos) = ReParseRes ReEmpty pos
        | otherwise = re_parse_seq_first pat pos len

fn :: re_parse_seq_first String Int Int => ReParseRes
      re_parse_seq_first pat    pos len =
        first_f = re_parse_factor pat pos len
        re_parse_seq_loop (re_res_node first_f) pat (re_res_pos first_f) len

fn :: re_parse_alt_loop ReNode String Int Int => ReParseRes
      re_parse_alt_loop left   pat    pos len
        | pos < len AND (str_char_at pat pos) == 124 = re_parse_alt_branch left pat (pos + 1) len
        | otherwise = ReParseRes left pos

fn :: re_parse_alt_branch ReNode String Int Int => ReParseRes
      re_parse_alt_branch left   pat    pos len =
        right_s = re_parse_seq pat pos len
        re_parse_alt_loop (ReAlt left (re_res_node right_s)) pat (re_res_pos right_s) len

fn :: re_parse_alt String Int Int => ReParseRes
      re_parse_alt pat    pos len =
        first_s = re_parse_seq pat pos len
        re_parse_alt_loop (re_res_node first_s) pat (re_res_pos first_s) len

-- ── Thompson NFA Compiler (`ReNode` -> `[NfaInst]`) ──────────

fn :: nfa_len [NfaInst] => Int
      nfa_len []        =  0
      nfa_len (_:rest)  =  1 + (nfa_len rest)

fn :: re_compile_seq ReNode ReNode Int      => [NfaInst]
      re_compile_seq a      b      start_id =
        insts_a = re_compile_node a start_id
        mid_id = start_id + (nfa_len insts_a)
        insts_b = re_compile_node b mid_id
        insts_a :: insts_b

fn :: re_compile_opt ReNode Int      => [NfaInst]
      re_compile_opt a      start_id =
        body = re_compile_node a (start_id + 1)
        end_id = start_id + 1 + (nfa_len body)
        [InstSplit (start_id + 1) end_id] :: body

fn :: re_compile_star ReNode Int      => [NfaInst]
      re_compile_star a      start_id =
        body = re_compile_node a (start_id + 1)
        end_id = start_id + 2 + (nfa_len body)
        ([InstSplit (start_id + 1) end_id] :: body) :: [InstJump start_id]

fn :: re_compile_plus ReNode Int      => [NfaInst]
      re_compile_plus a      start_id =
        body = re_compile_node a start_id
        split_id = start_id + (nfa_len body)
        body :: [InstSplit start_id (split_id + 1)]

fn :: re_compile_alt ReNode ReNode Int      => [NfaInst]
      re_compile_alt a      b      start_id =
        body_a = re_compile_node a (start_id + 1)
        jump_id = start_id + 1 + (nfa_len body_a)
        start_b = jump_id + 1
        body_b = re_compile_node b start_b
        end_id = start_b + (nfa_len body_b)
        (([InstSplit (start_id + 1) start_b] :: body_a) :: [InstJump end_id]) :: body_b

fn :: re_compile_node ReNode             Int      => [NfaInst]
      re_compile_node ReEmpty            _        =  []
      re_compile_node (ReChar c)         start_id =  [InstChar c (start_id + 1)]
      re_compile_node ReAny              start_id =  [InstAny (start_id + 1)]
      re_compile_node (ReClass neg rngs) start_id =  [InstClass neg rngs (start_id + 1)]
      re_compile_node (ReShort k)        start_id =  [InstShort k (start_id + 1)]
      re_compile_node ReBol              start_id =  [InstBol (start_id + 1)]
      re_compile_node ReEol              start_id =  [InstEol (start_id + 1)]
      re_compile_node (ReOpt a)          start_id =  re_compile_opt a start_id
      re_compile_node (ReStar a)         start_id =  re_compile_star a start_id
      re_compile_node (RePlus a)         start_id =  re_compile_plus a start_id
      re_compile_node (ReSeq a b)        start_id =  re_compile_seq a b start_id
      re_compile_node (ReAlt a b)        start_id =  re_compile_alt a b start_id

fn :: re_compile String => [NfaInst]
      re_compile pat    =
        parsed = re_parse_alt pat 0 (str_len pat)
        (re_compile_node (re_res_node parsed) 0) :: [InstMatch]

-- ── Linear-Time Thompson NFA State-Set Simulation ────────────

fn :: nfa_inst_at [NfaInst] Int => NfaInst
      nfa_inst_at []        _   =  InstMatch
      nfa_inst_at (i:_)     0   =  i
      nfa_inst_at (_:rest)  idx =  nfa_inst_at rest (idx - 1)

fn :: nfa_set_has [Int]  Int => Bool
      nfa_set_has []     _   =  False
      nfa_set_has (x:xs) v
        | x == v = True
        | otherwise = nfa_set_has xs v

fn :: nfa_closure [NfaInst] [Int] Int Int [Int] => [Int]
      nfa_closure _ [] _ _ visited = visited
      nfa_closure prog (s:ss) pos len visited
        | nfa_set_has visited s = nfa_closure prog ss pos len visited
        | otherwise = nfa_closure_inst prog s ss pos len (visited :: [s]) (nfa_inst_at prog s)

fn :: nfa_closure_inst [NfaInst] Int [Int] Int Int [Int] NfaInst => [Int]
      nfa_closure_inst prog _ ss pos len vis (InstJump out) = nfa_closure prog ([out] :: ss) pos len vis
      nfa_closure_inst prog _ ss pos len vis (InstSplit o1 o2) = nfa_closure prog ([o1, o2] :: ss) pos len vis
      nfa_closure_inst prog _ ss pos len vis (InstBol out)
        | pos == 0 = nfa_closure prog ([out] :: ss) pos len vis
        | otherwise = nfa_closure prog ss pos len vis
      nfa_closure_inst prog _ ss pos len vis (InstEol out)
        | pos == len = nfa_closure prog ([out] :: ss) pos len vis
        | otherwise = nfa_closure prog ss pos len vis
      nfa_closure_inst prog _ ss pos len vis _ = nfa_closure prog ss pos len vis

fn :: nfa_step_one NfaInst       Int => [Int]
      nfa_step_one (InstChar expected out) c
        | c == expected = [out]
        | otherwise = []
      nfa_step_one (InstAny out) c
        | c != 10 = [out]
        | otherwise = []
      nfa_step_one (InstClass neg rngs out) c
        | (re_in_ranges c rngs) != neg = [out]
        | otherwise = []
      nfa_step_one (InstShort kind out) c
        | re_match_short kind c = [out]
        | otherwise = []
      nfa_step_one _             _   =  []

fn :: nfa_step [NfaInst] [Int]  Int => [Int]
      nfa_step _         []     _   =  []
      nfa_step prog      (s:ss) c   =  (nfa_step_one (nfa_inst_at prog s) c) :: (nfa_step prog ss c)

fn :: nfa_is_match_inst NfaInst   => Bool
      nfa_is_match_inst InstMatch =  True
      nfa_is_match_inst _         =  False

fn :: nfa_has_match [NfaInst] [Int]  => Bool
      nfa_has_match _         []     =  False
      nfa_has_match prog      (s:ss)
        | nfa_is_match_inst (nfa_inst_at prog s) = True
        | otherwise = nfa_has_match prog ss

fn :: nfa_update_last [NfaInst] [Int]  Int  Int => Int
      nfa_update_last prog      active cand cur
        | nfa_has_match prog active = cand
        | otherwise = cur

fn :: nfa_sim_loop [NfaInst] String Int Int [Int] Int => Int
      nfa_sim_loop _ _ _ _ [] last_m = last_m
      nfa_sim_loop prog input pos len active last_m
        | pos >= len = last_m
        | otherwise = nfa_sim_step prog input pos len active last_m

fn :: nfa_sim_step [NfaInst] String Int Int [Int] Int => Int
      nfa_sim_step prog input pos len active last_m =
        c = str_char_at input pos
        next_act = nfa_closure prog (nfa_step prog active c) (pos + 1) len []
        next_last = nfa_update_last prog next_act (pos + 1) last_m
        nfa_sim_loop prog input (pos + 1) len next_act next_last

fn :: nfa_longest_from [NfaInst] String Int Int => Int
      nfa_longest_from prog      input  pos len =
        init_act = nfa_closure prog [0] pos len []
        init_last = nfa_update_last prog init_act pos (-1)
        nfa_sim_loop prog input pos len init_act init_last

fn :: nfa_full_loop [NfaInst] String Int Int [Int] => Bool
      nfa_full_loop _ _ _ _ [] = False
      nfa_full_loop prog input pos len active
        | pos >= len = nfa_has_match prog active
        | otherwise = nfa_full_step prog input pos len active

fn :: nfa_full_step [NfaInst] String Int Int [Int] => Bool
      nfa_full_step prog input pos len active =
        c = str_char_at input pos
        next_act = nfa_closure prog (nfa_step prog active c) (pos + 1) len []
        nfa_full_loop prog input (pos + 1) len next_act

-- ── Public Regex API (`API-REGEX-001`) ───────────────────────

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex match String String => Bool
      regex match pat    input  =
        prog = re_compile pat
        len = str_len input
        init_act = nfa_closure prog [0] 0 len []
        nfa_full_loop prog input 0 len init_act

fn :: nfa_find_from [NfaInst] String Int Int => RegexMatch
      nfa_find_from prog      input  pos len
        | pos > len = RegexMatch False (-1) (-1) ""
        | otherwise = nfa_find_check prog input pos len (nfa_longest_from prog input pos len)

fn :: nfa_find_check [NfaInst] String Int Int Int => RegexMatch
      nfa_find_check prog input pos len end_pos
        | end_pos >= pos = RegexMatch True pos end_pos (str_slice input pos end_pos)
        | otherwise = nfa_find_from prog input (pos + 1) len

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex find String String => RegexMatch
      regex find pat    input  =
        prog = re_compile pat
        nfa_find_from prog input 0 (str_len input)

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex is match String String => Bool
      regex is match pat    input  =  matched (regex find pat input)

fn :: nfa_find_all_loop [NfaInst] String Int Int [RegexMatch] => [RegexMatch]
      nfa_find_all_loop prog input pos len acc
        | pos > len = acc
        | otherwise = nfa_find_all_step prog input pos len acc (nfa_longest_from prog input pos len)

fn :: nfa_find_all_step [NfaInst] String Int Int [RegexMatch] Int => [RegexMatch]
      nfa_find_all_step prog input pos len acc end_pos
        | end_pos > pos = nfa_find_all_loop prog input end_pos len (acc :: [RegexMatch True pos end_pos (str_slice input pos end_pos)])
        | end_pos == pos = nfa_find_all_loop prog input (pos + 1) len (acc :: [RegexMatch True pos pos ""])
        | otherwise = nfa_find_all_loop prog input (pos + 1) len acc

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex find all String String => [RegexMatch]
      regex find all pat    input  =
        prog = re_compile pat
        nfa_find_all_loop prog input 0 (str_len input) []

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex replace String String String => String
      regex replace pat    repl   input  =
        m = regex find pat input
        re_apply_replace m repl input

fn :: re_apply_replace RegexMatch String String => String
      re_apply_replace m          repl   input
        | NOT (matched m) = input
        | otherwise = (str_slice input 0 (match_start m)) + repl + (str_slice input (match_end m) (str_len input))

fn :: nfa_replace_all_loop [NfaInst] String String Int Int String => String
      nfa_replace_all_loop prog repl input pos len acc
        | pos >= len = acc
        | otherwise = nfa_replace_all_step prog repl input pos len acc (nfa_longest_from prog input pos len)

fn :: nfa_replace_all_step [NfaInst] String String Int Int String Int => String
      nfa_replace_all_step prog repl input pos len acc end_pos
        | end_pos > pos = nfa_replace_all_loop prog repl input end_pos len (acc + repl)
        | otherwise = nfa_replace_all_loop prog repl input (pos + 1) len (acc + (str_slice input pos (pos + 1)))

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex replace all String String String => String
      regex replace all pat repl input =
        prog = re_compile pat
        nfa_replace_all_loop prog repl input 0 (str_len input) ""

fn :: nfa_split_loop [NfaInst] String Int Int Int [String] => [String]
      nfa_split_loop prog input pos len last_s acc
        | pos >= len = acc :: [str_slice input last_s len]
        | otherwise = nfa_split_step prog input pos len last_s acc (nfa_longest_from prog input pos len)

fn :: nfa_split_step [NfaInst] String Int Int Int [String] Int => [String]
      nfa_split_step prog input pos len last_s acc end_pos
        | end_pos > pos = nfa_split_loop prog input end_pos len end_pos (acc :: [str_slice input last_s pos])
        | otherwise = nfa_split_loop prog input (pos + 1) len last_s acc

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex split String String => [String]
      regex split pat    input  =
        prog = re_compile pat
        nfa_split_loop prog input 0 (str_len input) 0 []
