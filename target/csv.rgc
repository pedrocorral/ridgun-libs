-- ============================================================
-- src/main/ridgun/lib/csv.rg
-- Pure-Ridgun RFC 4180 CSV & TSV Parser, Serializer & Header Lookup Library (CSV)
-- @implements FR-CSV-001
-- @implements API-CSV-001
-- @implements DM-Csv
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: csv

type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool

-- ── RFC 4180 State-Machine Parser ────────────────────────────

fn :: csv delim code String => Int
      csv delim code "" = 44
      csv delim code d = str char at d 0

fn :: csv append final row [[String]] [String] String => [[String]]
      csv append final row rows [] "" = rows
      csv append final row rows cur_row cell = rows :: [cur_row :: [cell]]

fn :: csv parse quoted String Int Int Int String [String] [[String]] => [[String]]
      csv parse quoted s pos len d_code cell cur_row rows =
        | pos >= len = csv append final row rows cur_row cell
        | (str char at s pos) == 34 and (pos + 1) < len and (str char at s (pos + 1)) == 34 = csv parse quoted s (pos + 2) len d_code (cell + (char from code 34)) cur_row rows
        | (str char at s pos) == 34 = csv parse unquoted s (pos + 1) len d_code cell cur_row rows
        | otherwise = csv parse quoted s (pos + 1) len d_code (cell + (str slice s pos (pos + 1))) cur_row rows

fn :: csv parse unquoted String Int Int Int String [String] [[String]] => [[String]]
      csv parse unquoted s pos len d_code cell cur_row rows =
        | pos >= len = csv append final row rows cur_row cell
        | (str char at s pos) == 34 and cell == "" = csv parse quoted s (pos + 1) len d_code "" cur_row rows
        | (str char at s pos) == d_code = csv parse unquoted s (pos + 1) len d_code "" (cur_row :: [cell]) rows
        | (str char at s pos) == 13 and (pos + 1) < len and (str char at s (pos + 1)) == 10 = csv parse unquoted s (pos + 2) len d_code "" [] (rows :: [cur_row :: [cell]])
        | (str char at s pos) == 10 or (str char at s pos) == 13 = csv parse unquoted s (pos + 1) len d_code "" [] (rows :: [cur_row :: [cell]])
        | otherwise = csv parse unquoted s (pos + 1) len d_code (cell + (str slice s pos (pos + 1))) cur_row rows

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv parse with delim String String => [[String]]
      csv parse with delim s delim =
        csv parse unquoted s 0 (str len s) (csv delim code delim) "" [] []

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv parse String => [[String]]
      csv parse s = csv parse with delim s ","

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: tsv parse String => [[String]]
      tsv parse s = csv parse with delim s (char from code 9)

fn :: csv build table [[String]] Bool => CsvTable
      csv build table [] has_h = CsvTable [] [] "," has_h
      csv build table (h:rest) True = CsvTable h rest "," True
      csv build table all_rows False = CsvTable [] all_rows "," False

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv parse table String Bool => CsvTable
      csv parse table s has_h = csv build table (csv parse s) has_h

-- ── RFC 4180 Serialization & Escaping ────────────────────────

fn :: csv needs quotes loop String Int Int Int => Bool
      csv needs quotes loop s pos len d_code =
        | pos >= len = False
        | (str char at s pos) == d_code or (str char at s pos) == 34 or (str char at s pos) == 10 or (str char at s pos) == 13 = True
        | otherwise = csv needs quotes loop s (pos + 1) len d_code

fn :: csv double quotes loop String Int Int String => String
      csv double quotes loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 34 = csv double quotes loop s (pos + 1) len (acc + (char from code 34) + (char from code 34))
        | otherwise = csv double quotes loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: csv format cell String Int => String
      csv format cell cell d_code =
        | csv needs quotes loop cell 0 (str len cell) d_code = (char from code 34) + (csv double quotes loop cell 0 (str len cell) "") + (char from code 34)
        | otherwise = cell

fn :: csv join row [String] String Int => String
      csv join row [] _ _ = ""
      csv join row (c:[]) _ d_code = csv format cell c d_code
      csv join row (c:cs) delim d_code = (csv format cell c d_code) + delim + (csv join row cs delim d_code)

fn :: csv join rows [[String]] String Int => String
      csv join rows [] _ _ = ""
      csv join rows (r:rs) delim d_code = (csv join row r delim d_code) + (char from code 10) + (csv join rows rs delim d_code)

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv stringify with delim [[String]] String => String
      csv stringify with delim rows delim =
        csv join rows rows delim (csv delim code delim)

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv stringify [[String]] => String
      csv stringify rows = csv stringify with delim rows ","

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: tsv stringify [[String]] => String
      tsv stringify rows = csv stringify with delim rows (char from code 9)

-- ── Column Extraction & Header-Mapped Lookup ─────────────────

fn :: csv nth str [String] Int => String
      csv nth str [] _ = ""
      csv nth str (x:xs) idx =
        | idx < 0 = ""
        | idx == 0 = x
        | otherwise = csv nth str xs (idx - 1)

fn :: csv nth row [[String]] Int => [String]
      csv nth row [] _ = []
      csv nth row (r:rs) idx =
        | idx < 0 = []
        | idx == 0 = r
        | otherwise = csv nth row rs (idx - 1)

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv col [[String]] Int => [String]
      csv col [] _ = []
      csv col (r:rs) col_idx = [csv nth str r col_idx] :: (csv col rs col_idx)

fn :: csv find header idx [String] String Int => Int
      csv find header idx [] _ _ = (0 - 1)
      csv find header idx (h:hs) target idx =
        | h == target = idx
        | otherwise = csv find header idx hs target (idx + 1)

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv get by header CsvTable Int String => String
      csv get by header tbl row_idx col_name =
        headers tbl -> csv find header idx col_name 0 -> c_idx
        rows tbl -> csv nth row row_idx -> csv nth str c_idx

-- @implements FR-CSV-001
-- @implements API-CSV-001
fn :: csv row to map [String] [String] => [String String]
      csv row to map [] _ = []
      csv row to map _ [] = []
      csv row to map (h:hs) (v:vs) = [(h, v)] :: (csv row to map hs vs)
