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

fn :: re is digit Int => Bool
      re is digit c = c >= 48 and c <= 57

fn :: re is word Int => Bool
      re is word c = (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95

fn :: re is space Int => Bool
      re is space c = c == 32 or c == 9 or c == 10 or c == 13 or c == 11 or c == 12

fn :: re match short Int Int => Bool
      re match short 100 c = re is digit c
      re match short 68 c = not (re is digit c)
      re match short 119 c = re is word c
      re match short 87 c = not (re is word c)
      re match short 115 c = re is space c
      re match short 83 c = not (re is space c)
      re match short _ _ = False

fn :: re in ranges Int [Int] => Bool
      re in ranges _ [] = False
      re in ranges _ (_:[]) = False
      re in ranges c (lo:hi:rs) =
        | c >= lo and c <= hi = True
        | otherwise = re in ranges c rs

-- ── Regex Recursive-Descent Parser (`pattern_str` -> `ReNode`) ─

fn :: re escape char Int => ReNode
      re escape char 100 = ReShort 100
      re escape char 68 = ReShort 68
      re escape char 119 = ReShort 119
      re escape char 87 = ReShort 87
      re escape char 115 = ReShort 115
      re escape char 83 = ReShort 83
      re escape char 110 = ReChar 10
      re escape char 114 = ReChar 13
      re escape char 116 = ReChar 9
      re escape char c = ReChar c

fn :: re class char String Int Int => Int Int
      re class char pat pos len =
        | (str_char_at pat pos) == 92 and (pos + 1) < len and (str_char_at pat (pos + 1)) == 110 = (10, pos + 2)
        | (str_char_at pat pos) == 92 and (pos + 1) < len and (str_char_at pat (pos + 1)) == 116 = (9, pos + 2)
        | (str_char_at pat pos) == 92 and (pos + 1) < len and (str_char_at pat (pos + 1)) == 114 = (13, pos + 2)
        | (str_char_at pat pos) == 92 and (pos + 1) < len = (str_char_at pat (pos + 1), pos + 2)
        | otherwise = (str_char_at pat pos, pos + 1)

fn :: re fst int (Int Int) => Int
      re fst int (a, _) = a

fn :: re snd int (Int Int) => Int
      re snd int (_, b) = b

fn :: re parse class items String Int Int [Int] => [Int] Int
      re parse class items pat pos len acc =
        | pos >= len = (acc, len)
        | (str_char_at pat pos) == 93 = (acc, pos + 1)
        | otherwise = re parse class item step pat pos len acc

fn :: re parse class item step String Int Int [Int] => [Int] Int
      re parse class item step pat pos len acc =
        c1_pair = re class char pat pos len
        c1 = re fst int c1_pair
        next_p = re snd int c1_pair
        re parse class range check pat next_p len c1 acc

fn :: re parse class range check String Int Int Int [Int] => [Int] Int
      re parse class range check pat next_p len c1 acc =
        | (next_p + 1) < len and (str_char_at pat next_p) == 45 and (str_char_at pat (next_p + 1)) != 93 = re parse class range hi pat (next_p + 1) len c1 acc
        | otherwise = re parse class items pat next_p len (acc :: [c1, c1])

fn :: re parse class range hi String Int Int Int [Int] => [Int] Int
      re parse class range hi pat pos2 len c1 acc =
        c2_pair = re class char pat pos2 len
        c2 = re fst int c2_pair
        after_p = re snd int c2_pair
        re parse class items pat after_p len (acc :: [c1, c2])

fn :: re fst ranges ([Int] Int) => [Int]
      re fst ranges (r, _) = r

fn :: re snd pos ([Int] Int) => Int
      re snd pos (_, p) = p

fn :: re parse class String Int Int => ReParseRes
      re parse class pat pos len =
        | pos < len and (str_char_at pat pos) == 94 = re finish class True (re parse class items pat (pos + 1) len [])
        | otherwise = re finish class False (re parse class items pat pos len [])

fn :: re finish class Bool ([Int] Int) => ReParseRes
      re finish class neg res = ReParseRes (ReClass neg (re fst ranges res)) (re snd pos res)

fn :: re res node ReParseRes => ReNode
      re res node (ReParseRes node _) = node

fn :: re res pos ReParseRes => Int
      re res pos (ReParseRes _ pos) = pos

fn :: re parse group String Int Int => ReParseRes
      re parse group pat pos len =
        sub = re parse alt pat pos len
        sub_p = re res pos sub
        re close group (re res node sub) pat sub_p len

fn :: re close group ReNode String Int Int => ReParseRes
      re close group node pat pos len =
        | pos < len and (str_char_at pat pos) == 41 = ReParseRes node (pos + 1)
        | otherwise = ReParseRes node pos

fn :: re parse atom String Int Int => ReParseRes
      re parse atom pat pos len =
        | pos >= len = ReParseRes ReEmpty pos
        | (str_char_at pat pos) == 40 = re parse group pat (pos + 1) len
        | (str_char_at pat pos) == 91 = re parse class pat (pos + 1) len
        | (str_char_at pat pos) == 46 = ReParseRes ReAny (pos + 1)
        | (str_char_at pat pos) == 94 = ReParseRes ReBol (pos + 1)
        | (str_char_at pat pos) == 36 = ReParseRes ReEol (pos + 1)
        | (str_char_at pat pos) == 92 and (pos + 1) < len = ReParseRes (re escape char (str_char_at pat (pos + 1))) (pos + 2)
        | otherwise = ReParseRes (ReChar (str_char_at pat pos)) (pos + 1)

fn :: re parse postfix ReNode String Int Int => ReParseRes
      re parse postfix node pat pos len =
        | pos < len and (str_char_at pat pos) == 42 = re parse postfix (ReStar node) pat (pos + 1) len
        | pos < len and (str_char_at pat pos) == 43 = re parse postfix (RePlus node) pat (pos + 1) len
        | pos < len and (str_char_at pat pos) == 63 = re parse postfix (ReOpt node) pat (pos + 1) len
        | otherwise = ReParseRes node pos

fn :: re parse factor String Int Int => ReParseRes
      re parse factor pat pos len =
        atom = re parse atom pat pos len
        re parse postfix (re res node atom) pat (re res pos atom) len

fn :: re is seq stop Int => Bool
      re is seq stop c = c == 124 or c == 41

fn :: re parse seq loop ReNode String Int Int => ReParseRes
      re parse seq loop acc pat pos len =
        | pos >= len = ReParseRes acc pos
        | re is seq stop (str_char_at pat pos) = ReParseRes acc pos
        | otherwise = re parse seq step acc pat pos len

fn :: re parse seq step ReNode String Int Int => ReParseRes
      re parse seq step acc pat pos len =
        next_f = re parse factor pat pos len
        re parse seq loop (ReSeq acc (re res node next_f)) pat (re res pos next_f) len

fn :: re parse seq String Int Int => ReParseRes
      re parse seq pat pos len =
        | pos >= len = ReParseRes ReEmpty pos
        | re is seq stop (str_char_at pat pos) = ReParseRes ReEmpty pos
        | otherwise = re parse seq first pat pos len

fn :: re parse seq first String Int Int => ReParseRes
      re parse seq first pat pos len =
        first_f = re parse factor pat pos len
        re parse seq loop (re res node first_f) pat (re res pos first_f) len

fn :: re parse alt loop ReNode String Int Int => ReParseRes
      re parse alt loop left pat pos len =
        | pos < len and (str_char_at pat pos) == 124 = re parse alt branch left pat (pos + 1) len
        | otherwise = ReParseRes left pos

fn :: re parse alt branch ReNode String Int Int => ReParseRes
      re parse alt branch left pat pos len =
        right_s = re parse seq pat pos len
        re parse alt loop (ReAlt left (re res node right_s)) pat (re res pos right_s) len

fn :: re parse alt String Int Int => ReParseRes
      re parse alt pat pos len =
        first_s = re parse seq pat pos len
        re parse alt loop (re res node first_s) pat (re res pos first_s) len

-- ── Thompson NFA Compiler (`ReNode` -> `[NfaInst]`) ──────────

fn :: nfa len [NfaInst] => Int
      nfa len [] = 0
      nfa len (_:rest) = 1 + (nfa len rest)

fn :: re compile seq ReNode ReNode Int => [NfaInst]
      re compile seq a b start_id =
        insts_a = re compile node a start_id
        mid_id = start_id + (nfa len insts_a)
        insts_b = re compile node b mid_id
        insts_a :: insts_b

fn :: re compile opt ReNode Int => [NfaInst]
      re compile opt a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 1 + (nfa len body)
        [InstSplit (start_id + 1) end_id] :: body

fn :: re compile star ReNode Int => [NfaInst]
      re compile star a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 2 + (nfa len body)
        ([InstSplit (start_id + 1) end_id] :: body) :: [InstJump start_id]

fn :: re compile plus ReNode Int => [NfaInst]
      re compile plus a start_id =
        body = re compile node a start_id
        split_id = start_id + (nfa len body)
        body :: [InstSplit start_id (split_id + 1)]

fn :: re compile alt ReNode ReNode Int => [NfaInst]
      re compile alt a b start_id =
        body_a = re compile node a (start_id + 1)
        jump_id = start_id + 1 + (nfa len body_a)
        start_b = jump_id + 1
        body_b = re compile node b start_b
        end_id = start_b + (nfa len body_b)
        (([InstSplit (start_id + 1) start_b] :: body_a) :: [InstJump end_id]) :: body_b

fn :: re compile node ReNode Int => [NfaInst]
      re compile node ReEmpty _ = []
      re compile node (ReChar c) start_id = [InstChar c (start_id + 1)]
      re compile node ReAny start_id = [InstAny (start_id + 1)]
      re compile node (ReClass neg rngs) start_id = [InstClass neg rngs (start_id + 1)]
      re compile node (ReShort k) start_id = [InstShort k (start_id + 1)]
      re compile node ReBol start_id = [InstBol (start_id + 1)]
      re compile node ReEol start_id = [InstEol (start_id + 1)]
      re compile node (ReOpt a) start_id = re compile opt a start_id
      re compile node (ReStar a) start_id = re compile star a start_id
      re compile node (RePlus a) start_id = re compile plus a start_id
      re compile node (ReSeq a b) start_id = re compile seq a b start_id
      re compile node (ReAlt a b) start_id = re compile alt a b start_id

fn :: re compile String => [NfaInst]
      re compile pat =
        parsed = re parse alt pat 0 (str_len pat)
        (re compile node (re res node parsed) 0) :: [InstMatch]

-- ── Linear-Time Thompson NFA State-Set Simulation ────────────

fn :: nfa inst at [NfaInst] Int => NfaInst
      nfa inst at [] _ = InstMatch
      nfa inst at (i:_) 0 = i
      nfa inst at (_:rest) idx = nfa inst at rest (idx - 1)

fn :: nfa set has [Int] Int => Bool
      nfa set has [] _ = False
      nfa set has (x:xs) v =
        | x == v = True
        | otherwise = nfa set has xs v

fn :: nfa closure [NfaInst] [Int] Int Int [Int] => [Int]
      nfa closure _ [] _ _ visited = visited
      nfa closure prog (s:ss) pos len visited =
        | nfa set has visited s = nfa closure prog ss pos len visited
        | otherwise = nfa closure inst prog s ss pos len (visited :: [s]) (nfa inst at prog s)

fn :: nfa closure inst [NfaInst] Int [Int] Int Int [Int] NfaInst => [Int]
      nfa closure inst prog _ ss pos len vis (InstJump out) = nfa closure prog ([out] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstSplit o1 o2) = nfa closure prog ([o1, o2] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstBol out) =
        | pos == 0 = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis (InstEol out) =
        | pos == len = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis _ = nfa closure prog ss pos len vis

fn :: nfa step one NfaInst Int => [Int]
      nfa step one (InstChar expected out) c =
        | c == expected = [out]
        | otherwise = []
      nfa step one (InstAny out) c =
        | c != 10 = [out]
        | otherwise = []
      nfa step one (InstClass neg rngs out) c =
        | (re in ranges c rngs) != neg = [out]
        | otherwise = []
      nfa step one (InstShort kind out) c =
        | re match short kind c = [out]
        | otherwise = []
      nfa step one _ _ = []

fn :: nfa step [NfaInst] [Int] Int => [Int]
      nfa step _ [] _ = []
      nfa step prog (s:ss) c = (nfa step one (nfa inst at prog s) c) :: (nfa step prog ss c)

fn :: nfa is match inst NfaInst => Bool
      nfa is match inst InstMatch = True
      nfa is match inst _ = False

fn :: nfa has match [NfaInst] [Int] => Bool
      nfa has match _ [] = False
      nfa has match prog (s:ss) =
        | nfa is match inst (nfa inst at prog s) = True
        | otherwise = nfa has match prog ss

fn :: nfa update last [NfaInst] [Int] Int Int => Int
      nfa update last prog active cand cur =
        | nfa has match prog active = cand
        | otherwise = cur

fn :: nfa sim loop [NfaInst] String Int Int [Int] Int => Int
      nfa sim loop _ _ _ _ [] last_m = last_m
      nfa sim loop prog input pos len active last_m =
        | pos >= len = last_m
        | otherwise = nfa sim step prog input pos len active last_m

fn :: nfa sim step [NfaInst] String Int Int [Int] Int => Int
      nfa sim step prog input pos len active last_m =
        c = str_char_at input pos
        next_act = nfa closure prog (nfa step prog active c) (pos + 1) len []
        next_last = nfa update last prog next_act (pos + 1) last_m
        nfa sim loop prog input (pos + 1) len next_act next_last

fn :: nfa longest from [NfaInst] String Int Int => Int
      nfa longest from prog input pos len =
        init_act = nfa closure prog [0] pos len []
        init_last = nfa update last prog init_act pos (0 - 1)
        nfa sim loop prog input pos len init_act init_last

fn :: nfa full loop [NfaInst] String Int Int [Int] => Bool
      nfa full loop _ _ _ _ [] = False
      nfa full loop prog input pos len active =
        | pos >= len = nfa has match prog active
        | otherwise = nfa full step prog input pos len active

fn :: nfa full step [NfaInst] String Int Int [Int] => Bool
      nfa full step prog input pos len active =
        c = str_char_at input pos
        next_act = nfa closure prog (nfa step prog active c) (pos + 1) len []
        nfa full loop prog input (pos + 1) len next_act

-- ── Public Regex API (`API-REGEX-001`) ───────────────────────

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex match String String => Bool
      regex match pat input =
        prog = re compile pat
        len = str_len input
        init_act = nfa closure prog [0] 0 len []
        nfa full loop prog input 0 len init_act

fn :: nfa find from [NfaInst] String Int Int => RegexMatch
      nfa find from prog input pos len =
        | pos > len = RegexMatch False (0 - 1) (0 - 1) ""
        | otherwise = nfa find check prog input pos len (nfa longest from prog input pos len)

fn :: nfa find check [NfaInst] String Int Int Int => RegexMatch
      nfa find check prog input pos len end_pos =
        | end_pos >= pos = RegexMatch True pos end_pos (str_slice input pos end_pos)
        | otherwise = nfa find from prog input (pos + 1) len

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex find String String => RegexMatch
      regex find pat input =
        prog = re compile pat
        nfa find from prog input 0 (str_len input)

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex is match String String => Bool
      regex is match pat input = matched (regex find pat input)

fn :: nfa find all loop [NfaInst] String Int Int [RegexMatch] => [RegexMatch]
      nfa find all loop prog input pos len acc =
        | pos > len = acc
        | otherwise = nfa find all step prog input pos len acc (nfa longest from prog input pos len)

fn :: nfa find all step [NfaInst] String Int Int [RegexMatch] Int => [RegexMatch]
      nfa find all step prog input pos len acc end_pos =
        | end_pos > pos = nfa find all loop prog input end_pos len (acc :: [RegexMatch True pos end_pos (str_slice input pos end_pos)])
        | end_pos == pos = nfa find all loop prog input (pos + 1) len (acc :: [RegexMatch True pos pos ""])
        | otherwise = nfa find all loop prog input (pos + 1) len acc

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex find all String String => [RegexMatch]
      regex find all pat input =
        prog = re compile pat
        nfa find all loop prog input 0 (str_len input) []

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex replace String String String => String
      regex replace pat repl input =
        m = regex find pat input
        re apply replace m repl input

fn :: re apply replace RegexMatch String String => String
      re apply replace m repl input =
        | not (matched m) = input
        | otherwise = (str_slice input 0 (match_start m)) + repl + (str_slice input (match_end m) (str_len input))

fn :: nfa replace all loop [NfaInst] String String Int Int String => String
      nfa replace all loop prog repl input pos len acc =
        | pos >= len = acc
        | otherwise = nfa replace all step prog repl input pos len acc (nfa longest from prog input pos len)

fn :: nfa replace all step [NfaInst] String String Int Int String Int => String
      nfa replace all step prog repl input pos len acc end_pos =
        | end_pos > pos = nfa replace all loop prog repl input end_pos len (acc + repl)
        | otherwise = nfa replace all loop prog repl input (pos + 1) len (acc + (str_slice input pos (pos + 1)))

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex replace all String String String => String
      regex replace all pat repl input =
        prog = re compile pat
        nfa replace all loop prog repl input 0 (str_len input) ""

fn :: nfa split loop [NfaInst] String Int Int Int [String] => [String]
      nfa split loop prog input pos len last_s acc =
        | pos >= len = acc :: [str_slice input last_s len]
        | otherwise = nfa split step prog input pos len last_s acc (nfa longest from prog input pos len)

fn :: nfa split step [NfaInst] String Int Int Int [String] Int => [String]
      nfa split step prog input pos len last_s acc end_pos =
        | end_pos > pos = nfa split loop prog input end_pos len end_pos (acc :: [str_slice input last_s pos])
        | otherwise = nfa split loop prog input (pos + 1) len last_s acc

-- @implements FR-REGEX-001
-- @implements API-REGEX-001
fn :: regex split String String => [String]
      regex split pat input =
        prog = re compile pat
        nfa split loop prog input 0 (str_len input) 0 []
