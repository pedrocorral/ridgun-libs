-- ============================================================
-- src/test/ridgun/test csv.rg
-- Automated test suite for the RFC 4180 CSV & TSV Library (`csv.rg`)
-- @tests TS-CSV-001
-- ============================================================

import test
import csv

fn :: csv_p_key (String String) => String
      csv_p_key (k, _)          =  k

fn :: csv_p_val (String String) => String
      csv_p_val (_, v)          =  v

fn :: csv_pair_val [String String] String => String
      csv_pair_val []              _      =  ""
      csv_pair_val (pair:rest)     key
        | (csv_p_key pair) == key = csv_p_val pair
        | otherwise = csv_pair_val rest key

fn :: csv_len [String] => Int
      csv_len []       =  0
      csv_len (_:xs)   =  1 + (csv_len xs)

-- @tests TS-CSV-001
fn :: test_csv_tsv_roundtrip => ()
      test_csv_tsv_roundtrip =
        nl = char_from_code 10
        tab = char_from_code 9
        raw_csv = "name,role,note" + nl + "Ada,\"Admin, Lead\",\"Quote \"\"here\"\"\"" + nl + "Bob,User,Simple" + nl
        parsed = csv parse raw_csv
        re_csv = csv stringify parsed
        _ = assert str eq re_csv raw_csv "AC1/AC2: RFC 4180 CSV quoted comma and escaped quote round-trip"

        raw_tsv = "col1" + tab + "col2" + nl + "val1" + tab + "val2" + nl
        parsed_tsv = tsv parse raw_tsv
        re_tsv = tsv stringify parsed_tsv
        _ = assert str eq re_tsv raw_tsv "AC1/AC2: TSV round-trip"
        ()

-- @tests TS-CSV-001
fn :: test_csv_table_lookup => ()
      test_csv_table_lookup =
        nl = char_from_code 10
        raw_csv = "id,name,dept" + nl + "10,Ada,Math" + nl + "20,Grace,Compilers" + nl
        tbl = csv parse table raw_csv True
        _ = assert str eq (csv get by header tbl 0 "name") "Ada" "AC3: csv get by header row 0"
        _ = assert str eq (csv get by header tbl 1 "dept") "Compilers" "AC3: csv get by header row 1"
        _ = assert str eq (csv get by header tbl 0 "missing") "" "AC3: csv get by header missing column"

        names = csv col (rows tbl) 1
        _ = assert int equals (csv_len names) 2 "AC3: csv col length"

        rmap = csv row to map ["id", "name"] ["10", "Ada"]
        _ = assert str eq (csv_pair_val rmap "name") "Ada" "AC3: csv row to map"
        ()

-- @tests TS-CSV-001
fn :: main => ()
      main =
        _ = test_csv_tsv_roundtrip
        _ = test_csv_table_lookup
        echo "[PASS] test csv: TS-CSV-001 passed"
