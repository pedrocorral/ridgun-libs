-- ============================================================
-- src/main/ridgun/lib/glob.rg
-- Pure-Ridgun Wildcard (*, ?), Character Class ([a-z], [!a-z]) & List Filter Library (GLOB)
-- @implements FR-GLOB-001
-- @implements API-GLOB-001
-- @mitigates VUL-INPUT-001
-- ============================================================

fn :: gl lower char String Int Int => String
      gl lower char s idx c =
        | c >= 65 and c <= 90 = char_from_code (c + 32)
        | otherwise           = str_slice s idx (idx + 1)

fn :: gl to lower loop String Int Int => String
      gl to lower loop s idx len =
        | idx >= len = ""
        | otherwise  = (gl lower char s idx (str_char_at s idx)) + (gl to lower loop s (idx + 1) len)

fn :: gl to lower String => String
      gl to lower s      =  gl to lower loop s 0 (str_len s)

-- ── Bracket Character Class `[...]` Matching ─────────────────

fn :: gl find close bracket String Int Int => Int
      gl find close bracket pat idx plen =
        | idx >= plen                  = 0 - 1
        | (str_char_at pat idx) == 93  = idx
        | otherwise                    = gl find close bracket pat (idx + 1) plen

fn :: gl match range String Int Int Int Int Int => Bool
      gl match range pat idx end_idx tc lo hi =
        | tc >= lo and tc <= hi = True
        | otherwise             = gl match class body pat (idx + 3) end_idx tc

fn :: gl match class body String Int Int Int => Bool
      gl match class body pat idx end_idx tc =
        | idx >= end_idx = False
        | ((idx + 2) < end_idx) and ((str_char_at pat (idx + 1)) == 45) =
          gl match range pat idx end_idx tc (str_char_at pat idx) (str_char_at pat (idx + 2))
        | (str_char_at pat idx) == tc = True
        | otherwise                   = gl match class body pat (idx + 1) end_idx tc

fn :: gl eval bracket char String Int Int Int Int => Bool
      gl eval bracket char pat pstart close_idx tc c0 =
        | c0 == 33 or c0 == 94 = not (gl match class body pat (pstart + 1) close_idx tc)
        | otherwise            = gl match class body pat pstart close_idx tc

fn :: gl eval bracket String Int Int Int => Bool
      gl eval bracket pat pstart close_idx tc =
        gl eval bracket char pat pstart close_idx tc (str_char_at pat pstart)

-- ── Wildcard (`*`, `?`, `[...]`) Matcher ─────────────────────

fn :: gl skip stars String Int Int => Int
      gl skip stars pat pidx plen =
        | pidx >= plen                 = pidx
        | (str_char_at pat pidx) == 42 = gl skip stars pat (pidx + 1) plen
        | otherwise                    = pidx

fn :: gl match star String Int Int String Int Int => Bool
      gl match star pat pidx plen txt tidx tlen =
        | gl match loop pat pidx plen txt tidx tlen = True
        | tidx >= tlen                              = False
        | otherwise                                 = gl match star pat pidx plen txt (tidx + 1) tlen

fn :: gl match star at String Int Int String Int Int => Bool
      gl match star at pat next_p plen txt tidx tlen =
        | next_p >= plen = True
        | otherwise      = gl match star pat next_p plen txt tidx tlen

fn :: gl match bracket step String Int Int String Int Int Int => Bool
      gl match bracket step pat pidx plen txt tidx tlen close_idx =
        | close_idx < 0 =
          | (str_char_at txt tidx) == 91 = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
          | otherwise                    = False |.
        | gl eval bracket pat (pidx + 1) close_idx (str_char_at txt tidx) =
          gl match loop pat (close_idx + 1) plen txt (tidx + 1) tlen
        | otherwise = False

fn :: gl match step String Int Int String Int Int Int => Bool
      gl match step pat pidx plen txt tidx tlen pc =
        | pc == 42                     = gl match star at pat (gl skip stars pat (pidx + 1) plen) plen txt tidx tlen
        | tidx >= tlen                 = False
        | pc == 63                     = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | pc == 91                     = gl match bracket step pat pidx plen txt tidx tlen (gl find close bracket pat (pidx + 1) plen)
        | pc == (str_char_at txt tidx) = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | otherwise                    = False

fn :: gl match loop String Int Int String Int Int => Bool
      gl match loop pat pidx plen txt tidx tlen =
        | pidx >= plen = tidx >= tlen
        | otherwise    = gl match step pat pidx plen txt tidx tlen (str_char_at pat pidx)

-- @implements FR-GLOB-001
-- @implements API-GLOB-001
-- @mitigates VUL-INPUT-001
fn :: glob match String String => Bool
      glob match pat    txt    =  gl match loop pat 0 (str_len pat) txt 0 (str_len txt)

-- @implements FR-GLOB-001
-- @implements API-GLOB-001
fn :: glob match ci String String => Bool
      glob match ci pat    txt    =  glob match (gl to lower pat) (gl to lower txt)

-- @implements FR-GLOB-001
-- @implements API-GLOB-001
fn :: glob filter String [String] => [String]
      glob filter _      []       =  []
      glob filter pat    (x:rest) =
        | glob match pat x = [x] :: (glob filter pat rest)
        | otherwise        = glob filter pat rest

-- @implements FR-GLOB-001
-- @implements API-GLOB-001
fn :: glob any match [String] String => Bool
      glob any match []       _      =  False
      glob any match (p:rest) txt    =
        | glob match p txt = True
        | otherwise        = glob any match rest txt
