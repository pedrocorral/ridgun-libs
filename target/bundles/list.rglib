-- ============================================================
-- src/main/ridgun/lib/list.rg
-- Pure-Ridgun List Operations, Sorting, Grouping & Key-Value Map Library (LIST)
-- @implements FR-LIST-001
-- @implements FR-LIST-002
-- @implements API-LIST-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: list

import hashmap

-- ── List Length & Emptiness ──────────────────────────────────
-- `list len`, `list nth or`, `list last or`, `list take`, `list drop`, `list reverse` and
-- `list contains` are the generic ones of the compiler prelude (ridgunc 0.9.55).
-- The `list str` names stay as one-line aliases.

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str len [String] => Int
      list str len xs       =  list len xs

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list is empty [Int] => Bool
      list is empty []    =  True
      list is empty _     =  False

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str is empty [String] => Bool
      list str is empty []       =  True
      list str is empty _        =  False

-- ── Indexing, Head & Last ────────────────────────────────────

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list nth [Int] Int => Int
      list nth xs    idx =  list nth or xs idx 0

-- @implements FR-LIST-001
-- @implements API-LIST-001
-- @mitigates VUL-INPUT-001
fn :: list str nth or [String] Int String => String
      list str nth or xs       idx fallback =  list nth or xs idx fallback

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str nth [String] Int => String
      list str nth xs       idx =  list str nth or xs idx ""

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list head [Int] Int      => Int
      list head []    fallback =  fallback
      list head (x:_) _        =  x

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list last [Int]    Int      => Int
      list last []       fallback =  fallback
      list last (x:[])   _        =  x
      list last (_:rest) fallback =  list last rest fallback

-- ── Slicing (`take`, `drop`, `slice`) & Reversal ─────────────

-- @implements FR-LIST-001
-- @implements API-LIST-001
-- @mitigates VUL-INPUT-001
fn :: list str take [String] Int => [String]
      list str take xs       n   =  list take xs n

-- @implements FR-LIST-001
-- @implements API-LIST-001
-- @mitigates VUL-INPUT-001
fn :: list str drop [String] Int => [String]
      list str drop xs       n   =  list drop xs n

fn :: l clamp nonneg Int => Int
      l clamp nonneg x   =
        | x < 0     = 0
        | otherwise = x

fn :: l slice ints from [Int] Int Int => [Int]
      l slice ints from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list take (list drop xs s0) (end_idx - s0)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list slice [Int] Int   Int     => [Int]
      list slice xs    start end_idx =
        start l clamp nonneg -> s0
        l slice ints from xs s0 end_idx

fn :: l slice strs from [String] Int Int => [String]
      l slice strs from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list str take (list str drop xs s0) (end_idx - s0)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str slice [String] Int Int => [String]
      list str slice xs start end_idx =
        start l clamp nonneg -> s0
        l slice strs from xs s0 end_idx

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str reverse [String] => [String]
      list str reverse xs       =  list reverse xs

-- ── Range & Replication ──────────────────────────────────────

-- @implements FR-LIST-001
-- @implements API-LIST-001
-- @mitigates VUL-INPUT-001
fn :: list range step Int Int Int => [Int]
      list range step cur hi step =
        | step == 0             = []
        | step > 0 and cur > hi = []
        | step < 0 and cur < hi = []
        | otherwise             = [cur] :: (list range step (cur + step) hi step)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list range Int Int => [Int]
      list range lo  hi  =
        | lo > hi   = []
        | otherwise = list range step lo hi 1

-- @implements FR-LIST-001
-- @implements API-LIST-001
-- @mitigates VUL-INPUT-001
fn :: list replicate Int Int => [Int]
      list replicate n   val =
        | n <= 0    = []
        | otherwise = [val] :: (list replicate (n - 1) val)

-- ── Search, Count & Deduplication ────────────────────────────

fn :: l idx int [Int] Int Int => Int
      l idx int [] _ _ = 0 - 1
      l idx int (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx int rest tgt (idx + 1)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list index of [Int] Int => Int
      list index of xs    tgt =  l idx int xs tgt 0

fn :: l idx str [String] String Int => Int
      l idx str [] _ _ = 0 - 1
      l idx str (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx str rest tgt (idx + 1)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str index of [String] String => Int
      list str index of xs tgt = l idx str xs tgt 0

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str contains [String] String => Bool
      list str contains xs       tgt    =  list contains xs tgt

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list count [Int]    Int => Int
      list count []       _   =  0
      list count (x:rest) tgt =
        | x == tgt  = 1 + (list count rest tgt)
        | otherwise = list count rest tgt

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str count [String] String => Int
      list str count []       _      =  0
      list str count (x:rest) tgt    =
        | x == tgt  = 1 + (list str count rest tgt)
        | otherwise = list str count rest tgt

fn :: l dedup ints [Int]    [Int] => [Int]
      l dedup ints []       seen  =  list reverse seen
      l dedup ints (x:rest) seen  =
        | list contains seen x = l dedup ints rest seen
        | otherwise            = l dedup ints rest ([x] :: seen)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list dedup [Int] => [Int]
      list dedup xs    =  l dedup ints xs []

fn :: l dedup strs [String] [String] => [String]
      l dedup strs []       seen     =  list str reverse seen
      l dedup strs (x:rest) seen     =
        | list str contains seen x = l dedup strs rest seen
        | otherwise                = l dedup strs rest ([x] :: seen)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str dedup [String] => [String]
      list str dedup xs       =  l dedup strs xs []

-- ── Sorting (FR-LIST-002) ───────────────────────────────────
-- The native `sort by ints` and `sort by texts` (ridgunc 0.9.44) are stable and
-- use the order of `<` (byte order for text). The key list is built once, so f
-- is called once per element.

-- @implements FR-LIST-002
-- @implements API-LIST-001
fn :: list sort ints [Int] => [Int]
      list sort ints xs = sort by ints xs xs

-- Byte order.
-- @implements FR-LIST-002
-- @implements API-LIST-001
fn :: list sort texts [String] => [String]
      list sort texts xs = sort by texts xs xs

-- Stable: elements with equal keys keep their order. f is called once per element.
-- @implements FR-LIST-002
-- @implements API-LIST-001
fn :: list sort by int [A] (A => Int) => [A]
      list sort by int xs f = sort by ints xs (map f xs)

-- Stable, byte order of the keys. f is called once per element.
-- @implements FR-LIST-002
-- @implements API-LIST-001
fn :: list sort by text [A] (A => String) => [A]
      list sort by text xs f = sort by texts xs (map f xs)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list sort [Int] => [Int]
      list sort xs    =  list sort ints xs

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list is sorted [Int]      => Bool
      list is sorted []         =  True
      list is sorted (_:[])     =  True
      list is sorted (a:b:rest) =
        | a > b     = False
        | otherwise = list is sorted ([b] :: rest)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list str sort [String] => [String]
      list str sort xs       =  list sort texts xs

-- Length of a list of any element type.
fn :: l gen len [A] Int => Int
      l gen len []     acc = acc
      l gen len (_:xs) acc = l gen len xs (acc + 1)

-- ── Counting and grouping by key (FR-LIST-002) ──────────────
-- A hashmap lists its keys in insertion order, so the results list the keys in
-- order of first appearance.

-- Numbers each key in order of first appearance and writes the number of
-- element i to gid_(i). The map gives key -> number.
fn :: l group ids [A] (A => String) (HashMap Int) Tensor[Int * n] Int => HashMap Int
      l group ids []     f m gid i = m
      l group ids (x:xs) f m gid i = l group ids key xs f m gid i (f x)

fn :: l group ids key [A] (A => String) (HashMap Int) Tensor[Int * n] Int String => HashMap Int
      l group ids key xs f m gid i k = l group ids step xs f m gid i k (hashmap get m k (0 - 1))

fn :: l group ids step [A] (A => String) (HashMap Int) Tensor[Int * n] Int String Int => HashMap Int
      l group ids step xs f m gid i k g =
        | g >= 0    =
          gid_(i) = g
          l group ids xs f m gid (i + 1)
        | otherwise =
          ng = hashmap size m
          gid_(i) = ng
          l group ids xs f (hashmap put m k ng) gid (i + 1)

fn :: l count into [A] (A => String) (HashMap Int) => HashMap Int
      l count into []     f m = m
      l count into (x:xs) f m = l count into xs f (hashmap add m (f x) 1)

-- How many elements have each key, keys in order of first appearance.
-- @implements FR-LIST-002
-- @implements API-LIST-001
fn :: list count by [A] (A => String) => [String Int]
      list count by xs f = hashmap pairs (l count into xs f hashmap empty)

fn :: l rev gen [A] [A] => [A]
      l rev gen []     acc = acc
      l rev gen (x:xs) acc = l rev gen xs ([x] :: acc)

fn :: l collect [A] Tensor[Int * n] Tensor[[A] * n] Int => ()
      l collect []     gid groups i = ()
      l collect (x:xs) gid groups i =
        g = gid_(i)
        groups_(g) = [x] :: groups_(g)
        l collect xs gid groups (i + 1)

fn :: l group pairs [String Int] Tensor[[A] * n] [String [A]] => [String [A]]
      l group pairs []            groups acc = l rev gen acc []
      l group pairs ((k, g):rest) groups acc = l group pairs rest groups ([(k, l rev gen groups_(g) [])] :: acc)

fn :: l group by n [A] (A => String) Int => [String [A]]
      l group by n xs f n =
        | n == 0    = []
        | otherwise =
          gid    = Tensor[Int * n]
          m      = l group ids xs f hashmap empty gid 0
          ng     = hashmap size m
          groups = Tensor[[A] * ng]
          l collect xs gid groups 0
          l group pairs (hashmap pairs m) groups []

-- The elements of each key, in their original order; keys in order of first appearance.
-- @implements FR-LIST-002
-- @implements API-LIST-001
fn :: list group by [A] (A => String) => [String [A]]
      list group by xs f = l group by n xs f (l gen len xs 0)

-- ── Associative Key-Value Map (`[String String]`, `RG-066`) ─────────

fn :: l kv key (String String) => String
      l kv key (k, _)          =  k

fn :: l kv val (String String) => String
      l kv val (_, v)          =  v

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv empty => [String String]
      list kv empty =  []

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv len [String String] => Int
      list kv len []              =  0
      list kv len (_:rest)        =  1 + (list kv len rest)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv has [String String] String => Bool
      list kv has []              _      =  False
      list kv has (pair:rest)     key    =
        | (l kv key pair) == key = True
        | otherwise              = list kv has rest key

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv get or [String String] String String => String
      list kv get or [] _ fallback = fallback
      list kv get or (pair:rest) key fallback =
        | (l kv key pair) == key = l kv val pair
        | otherwise              = list kv get or rest key fallback

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv get [String String] String => String
      list kv get pairs           key    =  list kv get or pairs key ""

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv put [String String] String String => [String String]
      list kv put []              key    val    =  [(key, val)]
      list kv put (pair:rest)     key    val    =
        | (l kv key pair) == key = [(key, val)] :: rest
        | otherwise              = [pair] :: (list kv put rest key val)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv remove [String String] String => [String String]
      list kv remove []              _      =  []
      list kv remove (pair:rest)     key    =
        | (l kv key pair) == key = list kv remove rest key
        | otherwise              = [pair] :: (list kv remove rest key)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv keys [String String] => [String]
      list kv keys []              =  []
      list kv keys (pair:rest)     =  [(l kv key pair)] :: (list kv keys rest)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv values [String String] => [String]
      list kv values []              =  []
      list kv values (pair:rest)     =  [(l kv val pair)] :: (list kv values rest)

-- @implements FR-LIST-001
-- @implements API-LIST-001
fn :: list kv merge [String String] [String String] => [String String]
      list kv merge base            []              =  base
      list kv merge base            (pair:rest)     =
        list kv merge (list kv put base (l kv key pair) (l kv val pair)) rest
