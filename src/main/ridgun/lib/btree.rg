-- ============================================================
-- src/main/ridgun/lib/btree.rg
-- Pure-Ridgun O(log N) AVL Balanced Tree Map, Set & Leftist MinHeap Library (BTREE)
-- @implements FR-BTREE-001
-- @implements API-BTREE-001
-- @implements DM-Btree
-- @mitigates VUL-INPUT-001
-- ============================================================

type BTreeMap = BMapEmpty | BMapNode String String Int BTreeMap BTreeMap

type BTreeSet = BSetEmpty | BSetNode String Int BTreeSet BTreeSet

type MinHeap = HeapEmpty | HeapNode Int String Int MinHeap MinHeap

-- ── Lexicographical String Comparison & Int Helpers ──────────

fn :: bt_max Int Int => Int
      bt_max a   b
        | a >= b = a
        | otherwise = b

fn :: bt_str_cmp_loop String String Int Int Int => Int
      bt_str_cmp_loop a b idx la lb
        | idx >= la AND idx >= lb = 0
        | idx >= la = -1
        | idx >= lb = 1
        | (str_char_at a idx) < (str_char_at b idx) = -1
        | (str_char_at a idx) > (str_char_at b idx) = 1
        | otherwise = bt_str_cmp_loop a b (idx + 1) la lb

fn :: bt_str_cmp String String => Int
      bt_str_cmp a      b      =  bt_str_cmp_loop a b 0 (str_len a) (str_len b)

-- ── AVL-Balanced Ordered Map (`BTreeMap`) ────────────────────

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree empty => BTreeMap
      btree empty =  BMapEmpty

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree height BTreeMap  => Int
      btree height BMapEmpty =  0
      btree height (BMapNode _ _ h _ _) = h

fn :: bt_mk String String BTreeMap BTreeMap => BTreeMap
      bt_mk k      v      l        r        =  BMapNode k v (1 + (bt_max (btree_height l) (btree_height r))) l r

fn :: bt_bf BTreeMap  => Int
      bt_bf BMapEmpty =  0
      bt_bf (BMapNode _ _ _ l r) = (btree_height l) - (btree_height r)

fn :: bt_rot_right BTreeMap => BTreeMap
      bt_rot_right (BMapNode y yv _ (BMapNode x xv _ t1 t2) t3) = bt_mk x xv t1 (bt_mk y yv t2 t3)
      bt_rot_right node     =  node

fn :: bt_rot_left BTreeMap => BTreeMap
      bt_rot_left (BMapNode x xv _ t1 (BMapNode y yv _ t2 t3)) = bt_mk y yv (bt_mk x xv t1 t2) t3
      bt_rot_left node     =  node

fn :: bt_rebalance String String BTreeMap BTreeMap => BTreeMap
      bt_rebalance k      v      l        r
        | ((btree_height l) - (btree_height r)) > 1 AND (bt_bf l) >= 0 = bt_rot_right (bt_mk k v l r)
        | ((btree_height l) - (btree_height r)) > 1 = bt_rot_right (bt_mk k v (bt_rot_left l) r)
        | ((btree_height l) - (btree_height r)) < (-1) AND (bt_bf r) <= 0 = bt_rot_left (bt_mk k v l r)
        | ((btree_height l) - (btree_height r)) < (-1) = bt_rot_left (bt_mk k v l (bt_rot_right r))
        | otherwise = bt_mk k v l r

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree put BTreeMap  String String => BTreeMap
      btree put BMapEmpty key    val    =  BMapNode key val 1 BMapEmpty BMapEmpty
      btree put (BMapNode k v _ l r) key val
        | (bt_str_cmp key k) < 0 = bt_rebalance k v (btree_put l key val) r
        | (bt_str_cmp key k) > 0 = bt_rebalance k v l (btree_put r key val)
        | otherwise = bt_mk key val l r

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree get or BTreeMap String String => String
      btree get or BMapEmpty _ fallback = fallback
      btree get or (BMapNode k v _ l r) key fallback
        | (bt_str_cmp key k) < 0 = btree_get_or l key fallback
        | (bt_str_cmp key k) > 0 = btree_get_or r key fallback
        | otherwise = v

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree get BTreeMap String => String
      btree get t        key    =  btree_get_or t key ""

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree has BTreeMap  String => Bool
      btree has BMapEmpty _      =  False
      btree has (BMapNode k _ _ l r) key
        | (bt_str_cmp key k) < 0 = btree_has l key
        | (bt_str_cmp key k) > 0 = btree_has r key
        | otherwise = True

fn :: bt_min_pair BTreeMap  => (String String)
      bt_min_pair BMapEmpty =  ("", "")
      bt_min_pair (BMapNode k v _ BMapEmpty _) = (k, v)
      bt_min_pair (BMapNode _ _ _ l _) = bt_min_pair l

fn :: bt_pair_k (String String) => String
      bt_pair_k (k, _)          =  k

fn :: bt_pair_v (String String) => String
      bt_pair_v (_, v)          =  v

fn :: bt_delete_root BTreeMap  BTreeMap  => BTreeMap
      bt_delete_root BMapEmpty r         =  r
      bt_delete_root l         BMapEmpty =  l
      bt_delete_root l         r         =
        succ = bt_min_pair r
        sk = bt_pair_k succ
        sv = bt_pair_v succ
        bt_rebalance sk sv l (btree_remove r sk)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree remove BTreeMap  String => BTreeMap
      btree remove BMapEmpty _      =  BMapEmpty
      btree remove (BMapNode k v _ l r) key
        | (bt_str_cmp key k) < 0 = bt_rebalance k v (btree_remove l key) r
        | (bt_str_cmp key k) > 0 = bt_rebalance k v l (btree_remove r key)
        | otherwise = bt_delete_root l r

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree size BTreeMap  => Int
      btree size BMapEmpty =  0
      btree size (BMapNode _ _ _ l r) = 1 + (btree_size l) + (btree_size r)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree keys BTreeMap  => [String]
      btree keys BMapEmpty =  []
      btree keys (BMapNode k _ _ l r) = ((btree_keys l) :: [k]) :: (btree_keys r)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree values BTreeMap  => [String]
      btree values BMapEmpty =  []
      btree values (BMapNode _ v _ l r) = ((btree_values l) :: [v]) :: (btree_values r)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree to list BTreeMap  => [String String]
      btree to list BMapEmpty =  []
      btree to list (BMapNode k v _ l r) = ((btree_to_list l) :: [(k, v)]) :: (btree_to_list r)

fn :: bt_from_pairs [String String] BTreeMap => BTreeMap
      bt_from_pairs []              acc      =  acc
      bt_from_pairs (p:rest)        acc      =  bt_from_pairs rest (btree_put acc (bt_pair_k p) (bt_pair_v p))

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: btree from list [String String] => BTreeMap
      btree from list pairs           =  bt_from_pairs pairs BMapEmpty

-- ── AVL-Balanced Ordered Set (`BTreeSet`) ────────────────────

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset empty => BTreeSet
      bset empty =  BSetEmpty

fn :: bs_height BTreeSet           => Int
      bs_height BSetEmpty          =  0
      bs_height (BSetNode _ h _ _) =  h

fn :: bs_mk String BTreeSet BTreeSet => BTreeSet
      bs_mk k      l        r        =  BSetNode k (1 + (bt_max (bs_height l) (bs_height r))) l r

fn :: bs_bf BTreeSet           => Int
      bs_bf BSetEmpty          =  0
      bs_bf (BSetNode _ _ l r) =  (bs_height l) - (bs_height r)

fn :: bs_rot_right BTreeSet => BTreeSet
      bs_rot_right (BSetNode y _ (BSetNode x _ t1 t2) t3) = bs_mk x t1 (bs_mk y t2 t3)
      bs_rot_right node     =  node

fn :: bs_rot_left BTreeSet => BTreeSet
      bs_rot_left (BSetNode x _ t1 (BSetNode y _ t2 t3)) = bs_mk y (bs_mk x t1 t2) t3
      bs_rot_left node     =  node

fn :: bs_rebalance String BTreeSet BTreeSet => BTreeSet
      bs_rebalance k      l        r
        | ((bs_height l) - (bs_height r)) > 1 AND (bs_bf l) >= 0 = bs_rot_right (bs_mk k l r)
        | ((bs_height l) - (bs_height r)) > 1 = bs_rot_right (bs_mk k (bs_rot_left l) r)
        | ((bs_height l) - (bs_height r)) < (-1) AND (bs_bf r) <= 0 = bs_rot_left (bs_mk k l r)
        | ((bs_height l) - (bs_height r)) < (-1) = bs_rot_left (bs_mk k l (bs_rot_right r))
        | otherwise = bs_mk k l r

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset add BTreeSet           String => BTreeSet
      bset add BSetEmpty          key    =  BSetNode key 1 BSetEmpty BSetEmpty
      bset add (BSetNode k _ l r) key
        | (bt_str_cmp key k) < 0 = bs_rebalance k (bset_add l key) r
        | (bt_str_cmp key k) > 0 = bs_rebalance k l (bset_add r key)
        | otherwise = bs_mk k l r

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset has BTreeSet           String => Bool
      bset has BSetEmpty          _      =  False
      bset has (BSetNode k _ l r) key
        | (bt_str_cmp key k) < 0 = bset_has l key
        | (bt_str_cmp key k) > 0 = bset_has r key
        | otherwise = True

fn :: bs_min_key BTreeSet           => String
      bs_min_key BSetEmpty          =  ""
      bs_min_key (BSetNode k _ BSetEmpty _) = k
      bs_min_key (BSetNode _ _ l _) =  bs_min_key l

fn :: bs_delete_root BTreeSet  BTreeSet  => BTreeSet
      bs_delete_root BSetEmpty r         =  r
      bs_delete_root l         BSetEmpty =  l
      bs_delete_root l         r         =
        sk = bs_min_key r
        bs_rebalance sk l (bset_remove r sk)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset remove BTreeSet           String => BTreeSet
      bset remove BSetEmpty          _      =  BSetEmpty
      bset remove (BSetNode k _ l r) key
        | (bt_str_cmp key k) < 0 = bs_rebalance k (bset_remove l key) r
        | (bt_str_cmp key k) > 0 = bs_rebalance k l (bset_remove r key)
        | otherwise = bs_delete_root l r

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset size BTreeSet           => Int
      bset size BSetEmpty          =  0
      bset size (BSetNode _ _ l r) =  1 + (bset_size l) + (bset_size r)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset to list BTreeSet           => [String]
      bset to list BSetEmpty          =  []
      bset to list (BSetNode k _ l r) =  ((bset_to_list l) :: [k]) :: (bset_to_list r)

fn :: bs_from_strs [String] BTreeSet => BTreeSet
      bs_from_strs []       acc      =  acc
      bs_from_strs (k:rest) acc      =  bs_from_strs rest (bset_add acc k)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset from list [String] => BTreeSet
      bset from list keys     =  bs_from_strs keys BSetEmpty

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset union BTreeSet BTreeSet => BTreeSet
      bset union a        b        =  bs_from_strs (bset_to_list b) a

fn :: bs_inter_loop [String] BTreeSet BTreeSet => BTreeSet
      bs_inter_loop []       _        acc      =  acc
      bs_inter_loop (k:rest) b        acc
        | bset_has b k = bs_inter_loop rest b (bset_add acc k)
        | otherwise = bs_inter_loop rest b acc

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset intersect BTreeSet BTreeSet => BTreeSet
      bset intersect a        b        =  bs_inter_loop (bset_to_list a) b BSetEmpty

fn :: bs_diff_loop [String] BTreeSet => BTreeSet
      bs_diff_loop []       acc      =  acc
      bs_diff_loop (k:rest) acc      =  bs_diff_loop rest (bset_remove acc k)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: bset diff BTreeSet BTreeSet => BTreeSet
      bset diff a        b        =  bs_diff_loop (bset_to_list b) a

-- ── Leftist MinHeap Priority Queue (`MinHeap`) ───────────────

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: heap empty => MinHeap
      heap empty =  HeapEmpty

fn :: hp_rank MinHeap   => Int
      hp_rank HeapEmpty =  0
      hp_rank (HeapNode _ _ r _ _) = r

fn :: hp_mk Int String MinHeap MinHeap => MinHeap
      hp_mk p   v      a       b
        | (hp_rank a) >= (hp_rank b) = HeapNode p v ((hp_rank b) + 1) a b
        | otherwise = HeapNode p v ((hp_rank a) + 1) b a

fn :: hp_merge MinHeap   MinHeap   => MinHeap
      hp_merge HeapEmpty h2        =  h2
      hp_merge h1        HeapEmpty =  h1
      hp_merge (HeapNode p1 v1 r1 l1 rt1) (HeapNode p2 v2 r2 l2 rt2)
        | p1 <= p2 = hp_mk p1 v1 l1 (hp_merge rt1 (HeapNode p2 v2 r2 l2 rt2))
        | otherwise = hp_mk p2 v2 l2 (hp_merge (HeapNode p1 v1 r1 l1 rt1) rt2)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: heap push MinHeap Int  String => MinHeap
      heap push h       prio val    =  hp_merge h (HeapNode prio val 1 HeapEmpty HeapEmpty)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: heap peek MinHeap   => (Int String)
      heap peek HeapEmpty =  (0, "")
      heap peek (HeapNode p v _ _ _) = (p, v)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: heap pop MinHeap   => (Int String MinHeap)
      heap pop HeapEmpty =  (0, "", HeapEmpty)
      heap pop (HeapNode p v _ l r) = (p, v, hp_merge l r)

-- @implements FR-BTREE-001
-- @implements API-BTREE-001
fn :: heap size MinHeap   => Int
      heap size HeapEmpty =  0
      heap size (HeapNode _ _ _ l r) = 1 + (heap_size l) + (heap_size r)
