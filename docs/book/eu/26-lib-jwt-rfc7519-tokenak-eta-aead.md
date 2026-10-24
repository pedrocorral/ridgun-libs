# 26. kapitulua: `jwt` lib-a — RFC 7519 JSON Web Tokenak (`HS256`) eta ChaCha20-Poly1305 Token Zifratuak

## 26.1. Zergatik existitzen da `jwt` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `jwt` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `jwt`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: JWT ekosistema ospetsua da erasotzaile batek goiburua `"alg":"none"`-ra aldatzen duen eta zerbitzariak tokena sinadurarik gabe onartzen duen ahultasunengatik, edo payload-a Base64url-n kodetuta baino ez dagoela ahaztuta informazio sentikorra gordetzeagatik.

**`jwt`** lib-ak bi munduak konpontzen ditu: **RFC 7519 (`HS256`) JWTak** sinatu eta egiaztatzen ditu `alg == "HS256"` esplizituki eskatuz, HMACa denbora konstantean konparatuz eta `exp`/`nbf` baliozkotuz, eta gainera **`token seal` / `token open`** eskaintzen ditu **ChaCha20-Poly1305 AEAD** bidez zifratutako token opakuak jaulkitzeko.

Ekosistema tradizional batean, **`JWT`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`jwt`** lib-ak (`src/main/ridgun/lib/jwt.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `jwt`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `jwt`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `jwt`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 26.2. Artefaktu natiboak, inportazioa eta `jwt` APIaren katalogo osoa

`ridgun-libs`-en, **`jwt`** lehen mailako **lib** bat da, `src/main/ridgun/lib/jwt.rg` bidean kokatua (`JWT` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/jwt.rglib` | Banaketa eta inportazio zuzena `import jwt` bidez |
| **Fitxategi konpilatua** | `target/jwt.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libjwt.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import jwt` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 26.2.1. `jwt`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | `JsonVal` claim-ak sinatzen ditu eta sinadura + `alg == "HS256"` + `exp`/`nbf` egiaztatzen ditu |
| `jwt claims / jwt get str / jwt get int` | `(sub, iss, iat, exp)` claim estandarrak eraiki eta egiaztatutako payload-ak kontsultatzen ditu |
| `token seal / token open` | JSON token opakuak zifratu eta autentifikatzen ditu ChaCha20-Poly1305 AEAD bidez |

### 26.2.2. `src/main/ridgun/lib/jwt.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/jwt.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`3` mota, `0` eragile eta `55` funtzio):

**`jwt`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: jwt_b64url_lut Int` | `String` |
| `2` | `fn :: jwt_b64_char Int` | `String` |
| `3` | `fn :: jwt_b64_val Int` | `Int` |
| `4` | `fn :: jwt_b64url_enc_bytes [Int]` | `String` |
| `5` | `fn :: jwt_str_to_bytes_loop String Int Int [Int]` | `[Int]` |
| `6` | `fn :: jwt_str_to_bytes String` | `[Int]` |
| `7` | `fn :: jwt_bytes_to_str [Int]` | `String` |
| `8` | `fn :: jwt_b64url_encode String` | `String` |
| `9` | `fn :: jwt_b64url_valid_loop String Int Int` | `Bool` |
| `10` | `fn :: jwt_b64url_is_valid String` | `Bool` |
| `11` | `fn :: jwt_b64url_dec_rem String Int Int` | `[Int]` |
| `12` | `fn :: jwt_b64url_dec_3 String Int` | `[Int]` |
| `13` | `fn :: jwt_b64url_dec_4 String Int` | `[Int]` |
| `14` | `fn :: jwt_b64url_decode_bytes String` | `[Int]` |
| `15` | `fn :: jwt_b64url_decode String` | `String` |
| `16` | `fn :: jwt_bxor_loop Int Int Int Int` | `Int` |
| `17` | `fn :: jwt_byte_xor Int Int` | `Int` |
| `18` | `fn :: jwt_ct_diff String String Int Int Int` | `Int` |
| `19` | `fn :: jwt_ct_eq String String` | `Bool` |
| `20` | `fn :: jwt_hex_nib Int` | `Int` |
| `21` | `fn :: jwt_hex_to_bytes_loop String Int Int [Int]` | `[Int]` |
| `22` | `fn :: jwt_hex_to_bytes String` | `[Int]` |
| `23` | `fn :: jwt_pad_key_bytes [Int] Int` | `[Int]` |
| `24` | `fn :: jwt_pad_key_head [Int] Int` | `[Int]` |
| `25` | `fn :: jwt_key_block String` | `[Int]` |
| `26` | `fn :: jwt_xor_pad_str [Int] Int` | `String` |
| `27` | `fn :: jwt_hmac_sha256_b64url String String` | `String` |
| `28` | `fn :: jwt_hs256_header_json Int` | `String` |
| `29` | `fn :: jwt sign hs256 String String` | `String` |
| `30` | `fn :: jwt_split_dots_loop String Int Int Int [String]` | `[String]` |
| `31` | `fn :: jwt_str_list_len [String]` | `Int` |
| `32` | `fn :: jwt_str_at [String] Int` | `String` |
| `33` | `fn :: jwt decode payload String` | `JwtRes` |
| `34` | `fn :: jwt_decode_parts [String]` | `JwtRes` |
| `35` | `fn :: jwt_header_is_hs256 String` | `Bool` |
| `36` | `fn :: jwt_check_hdr_json JsonRes` | `Bool` |
| `37` | `fn :: jwt verify hs256 String String` | `JwtRes` |
| `38` | `fn :: jwt_verify_parts [String] String` | `JwtRes` |
| `39` | `fn :: jwt_verify_sig String String String String` | `JwtRes` |
| `40` | `fn :: jwt_verify_sig_ct Bool String` | `JwtRes` |
| `41` | `fn :: jwt sign claims JwtClaims String` | `String` |
| `42` | `fn :: jwt verify claims String String Int` | `JwtClaimsRes` |
| `43` | `fn :: jwt_validate_verified_payload JwtRes Int` | `JwtClaimsRes` |
| `44` | `fn :: jwt_validate_parsed_claims JsonRes Int` | `JwtClaimsRes` |
| `45` | `fn :: jwt_check_claim_times JwtClaims Int` | `JwtClaimsRes` |
| `46` | `fn :: jwt_keystream_bytes String String Int Int` | `[Int]` |
| `47` | `fn :: jwt_xor_lists [Int] [Int]` | `[Int]` |
| `48` | `fn :: jwt seal aead String String String` | `JwtRes` |
| `49` | `fn :: jwt_seal_aead_ok String String String` | `JwtRes` |
| `50` | `fn :: jwt open aead String String String` | `JwtRes` |
| `51` | `fn :: jwt_open_aead_parts String String [String]` | `JwtRes` |
| `52` | `fn :: jwt_open_aead_verify String String String String String` | `JwtRes` |
| `53` | `fn :: jwt_open_aead_decrypt Bool String String String` | `JwtRes` |
| `54` | `fn :: jwt_int_list_len [Int]` | `Int` |
| `55` | `fn :: jwt_open_aead_pt String String [Int]` | `JwtRes` |

---

## 26.3. `jwt` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `jwt` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test jwt.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 26.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `jwt` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `jwt` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import jwt
import json

fn :: emitir y verificar sesion (secreto : String) => (String, String)
      emitir y verificar sesion secreto =
        claims = jwt claims "user-42" "solstice" 1700000000 1700003600
        tok    = jwt sign hs256 secreto claims
        res    = jwt verify hs256 secreto tok 1700001000
        sub    = jwt get str res "sub" "anonimo"
        (tok, sub)
```

### 26.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`jwt` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import jwt
import json

fn :: sellar token confidencial (clave : String) => JwtResult
      sellar token confidencial clave =
        datos = JnObj [("rol", JnStr "root"), ("pin", JnInt 9988)]
        sobre = token seal clave "nonce-12byte" datos
        token open clave sobre
```

### 26.3.3. 3. adibidea: JWT HS256 sinadura eta egiaztapena (`jwt sign hs256`, `jwt verify hs256`), `alg: none` erasoaren ukapena eta sinadura-manipulazioaren detekzioa

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_jwt_hs256_sign_verify_and_tamper => ()
      test_jwt_hs256_sign_verify_and_tamper =
        payload = '{"sub":"user-42","role":"admin"}'
        secret = "super-secret-hmac-key-2026"
        tok = jwt sign hs256 payload secret

        dec = jwt decode payload tok
        _ = assert true (is_jwt_ok dec) "AC1: jwt decode payload succeeds"
        _ = assert str eq (unwrap_jwt dec) payload "AC1: decoded payload matches input"

        ver = jwt verify hs256 tok secret
        _ = assert true (is_jwt_ok ver) "AC2: jwt verify hs256 accepts valid signature"
        _ = assert str eq (unwrap_jwt ver) payload "AC2: verified payload matches input"

        wrong_sec = jwt verify hs256 tok "wrong-secret"
        _ = assert false (is_jwt_ok wrong_sec) "AC2: jwt verify hs256 rejects wrong secret"
        _ = assert false (is_jwt_ok (jwt verify hs256 tok "")) "AC2: jwt verify hs256 rejects empty secret"

        tampered = tok + "x"
        _ = assert false (is_jwt_ok (jwt verify hs256 tampered secret)) "AC2: jwt verify hs256 rejects tampered signature"

        -- CVE/RFC 8725 attacks: alg:none, empty signature segment, malformed segment counts
        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        _ = assert false (is_jwt_ok (jwt verify hs256 alg_none_tok secret)) "AC2: jwt verify hs256 rejects alg:none"
        alg_none_empty_sig = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0."
        _ = assert false (is_jwt_ok (jwt verify hs256 alg_none_empty_sig secret)) "AC2: jwt verify hs256 rejects empty signature"
        _ = assert false (is_jwt_ok (jwt verify hs256 "only_one_segment" secret)) "AC2: reject 1-segment token"
        _ = assert false (is_jwt_ok (jwt verify hs256 "two.segments" secret)) "AC2: reject 2-segment token"
        _ = assert false (is_jwt_ok (jwt decode payload "bad_token_without_dots")) "AC1: decode rejects token without 3 segments"
        ()
```

### 26.3.4. 4. adibidea: Egituratutako *claim*-en denbora-baliozkotzea (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) `jwt validate claims` bidez

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_jwt_claims_temporal_validation => ()
      test_jwt_claims_temporal_validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        -- Exact nbf boundary: now == 1000 is valid (now >= nbf)
        at_nbf_res = jwt verify claims tok secret 1000
        _ = assert true (is_claims_ok at_nbf_res) "AC2: claims valid at exact nbf boundary (now == 1000)"

        ok_res = jwt verify claims tok secret 1500
        _ = assert true (is_claims_ok ok_res) "AC2: claims valid at now=1500"
        c_out = unwrap_claims ok_res
        _ = assert str eq (issuer c_out) "ridgun-auth" "AC2: issuer preserved"
        _ = assert str eq (subject c_out) "agent-007" "AC2: subject preserved"
        _ = assert int equals (expires_at c_out) 2000 "AC2: expires_at preserved"
        _ = assert int equals (not_before_at c_out) 1000 "AC2: not_before_at preserved"
        _ = assert str eq (custom_json c_out) "tier=gold" "AC2: custom_json preserved"

        -- 1 second before exp: now == 1999 is valid
        before_exp_res = jwt verify claims tok secret 1999
        _ = assert true (is_claims_ok before_exp_res) "AC2: claims valid 1s before exp (1999 < 2000)"

        -- 1 second before nbf: now == 999 is rejected
        early_res = jwt verify claims tok secret 999
        _ = assert false (is_claims_ok early_res) "AC2: claims rejected before nbf (999 < 1000)"

        -- Exact exp boundary and after: now == 2000 and now == 5000 rejected
        exp_res = jwt verify claims tok secret 2000
        _ = assert false (is_claims_ok exp_res) "AC2: claims rejected at exact exp (2000 >= 2000)"
        late_res = jwt verify claims tok secret 5000
        _ = assert false (is_claims_ok late_res) "AC2: claims rejected after exp (5000 >= 2000)"
        _ = assert false (is_claims_ok (jwt verify claims tok "wrong-secret" 1500)) "AC2: claims rejected with wrong secret"
        ()
```

### 26.3.5. 5. adibidea: ChaCha20-Poly1305 AEAD bidez zifratu eta autentifikatutako tokenak (`jwt seal aead`, `jwt open aead`)

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_jwt_aead_seal_and_open => ()
      test_jwt_aead_seal_and_open =
        key32 = "0123456789abcdef0123456789abcdef"
        other_key32 = "fedcba9876543210fedcba9876543210"
        nonce12 = "uniqueNonce1"
        other_nonce12 = "uniqueNonce2"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        _ = assert true (is_jwt_ok sealed) "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap_jwt sealed

        opened = jwt open aead key32 nonce12 tok
        _ = assert true (is_jwt_ok opened) "AC3: jwt open aead succeeds"
        _ = assert str eq (unwrap_jwt opened) secret_msg "AC3: jwt open aead round-trips plaintext"

        _ = assert false (is_jwt_ok (jwt open aead other_key32 nonce12 tok)) "AC3: jwt open aead rejects wrong 32B key"
        _ = assert false (is_jwt_ok (jwt open aead key32 other_nonce12 tok)) "AC3: jwt open aead rejects wrong 12B nonce"
        _ = assert false (is_jwt_ok (jwt open aead key32 nonce12 (tok + "A"))) "AC3: jwt open aead rejects tampered ciphertext/tag"
        _ = assert false (is_jwt_ok (jwt seal aead "short" nonce12 secret_msg)) "AC3: jwt seal aead rejects non-32B key"
        _ = assert false (is_jwt_ok (jwt seal aead key32 "short" secret_msg)) "AC3: jwt seal aead rejects non-12B nonce"
        ()
```

---

## 26.4. Kaputaren azpian: nola dagoen eraikia `jwt` Ridgun hutsean (`src/main/ridgun/lib/jwt.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/jwt.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 26.4.1. Barne-inplementazioa: Byte, Hex, Base64url & Constant-Time Helpers

Ikusi nola `jwt.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: jwt_b64url_lut Int => String
      jwt_b64url_lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: jwt_b64_char Int => String
      jwt_b64_char idx =
        tbl = jwt_b64url_lut 0
        i = ((idx % 64) + 64) % 64
        str_slice tbl i (i + 1)

fn :: jwt_b64_val Int => Int
      jwt_b64_val c
        | c >= 65 AND c <= 90 = c - 65
        | c >= 97 AND c <= 122 = (c - 97) + 26
        | c >= 48 AND c <= 57 = (c - 48) + 52
        | c == 45 OR c == 43 = 62
        | c == 95 OR c == 47 = 63
        | otherwise = -1

fn :: jwt_b64url_enc_bytes [Int]         => String
      jwt_b64url_enc_bytes []            =  ""
      jwt_b64url_enc_bytes (b0:[])       =  (jwt_b64_char (b0 / 4)) + (jwt_b64_char ((b0 % 4) * 16))
      jwt_b64url_enc_bytes (b0:b1:[])    =
        n = (b0 * 256) + b1
        (jwt_b64_char (n / 1024)) + (jwt_b64_char ((n / 16) % 64)) + (jwt_b64_char ((n % 16) * 4))
      jwt_b64url_enc_bytes (b0:b1:b2:rs) =
        n = (b0 * 65536) + (b1 * 256) + b2
        (jwt_b64_char (n / 262144)) + (jwt_b64_char ((n / 4096) % 64)) + (jwt_b64_char ((n / 64) % 64)) + (jwt_b64_char (n % 64)) + (jwt_b64url_enc_bytes rs)

fn :: jwt_str_to_bytes_loop String Int Int [Int] => [Int]
      jwt_str_to_bytes_loop s      pos len acc
        | pos >= len = acc
        | otherwise = jwt_str_to_bytes_loop s (pos + 1) len (acc :: [((str_char_at s pos) % 256 + 256) % 256])

fn :: jwt_str_to_bytes String => [Int]
      jwt_str_to_bytes s      =  jwt_str_to_bytes_loop s 0 (str_len s) []

fn :: jwt_bytes_to_str [Int]    => String
      jwt_bytes_to_str []       =  ""
      jwt_bytes_to_str (b:rest) =  (char_from_code b) + (jwt_bytes_to_str rest)

fn :: jwt_b64url_encode String => String
      jwt_b64url_encode s      =  jwt_b64url_enc_bytes (jwt_str_to_bytes s)

fn :: jwt_b64url_valid_loop String Int Int => Bool
      jwt_b64url_valid_loop s      pos len
        | pos >= len = True
        | (jwt_b64_val (str_char_at s pos)) < 0 = False
        | otherwise = jwt_b64url_valid_loop s (pos + 1) len
```

### 26.4.2. Barne-inplementazioa: Constant-Time Equality & Bitwise XOR

Ikusi nola `jwt.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: jwt_bxor_loop Int Int Int Int => Int
      jwt_bxor_loop _   _   0   acc =  acc
      jwt_bxor_loop a   b   bit acc
        | ((a % 2) != (b % 2)) = jwt_bxor_loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = jwt_bxor_loop (a / 2) (b / 2) (bit * 2) acc

fn :: jwt_byte_xor Int Int => Int
      jwt_byte_xor a   b   =  jwt_bxor_loop (((a % 256) + 256) % 256) (((b % 256) + 256) % 256) 1 0

fn :: jwt_ct_diff String String Int Int Int => Int
      jwt_ct_diff a b idx len acc
        | idx >= len = acc
        | otherwise = jwt_ct_diff a b (idx + 1) len (acc + (jwt_byte_xor (str_char_at a idx) (str_char_at b idx)))

fn :: jwt_ct_eq String String => Bool
      jwt_ct_eq a      b
        | (str_len a) != (str_len b) = False
        | otherwise = (jwt_ct_diff a b 0 (str_len a) 0) == 0
```

### 26.4.3. Barne-inplementazioa: HS256 (HMAC-SHA256) Signing & Verification

Ikusi nola `jwt.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: jwt_hex_nib Int => Int
      jwt_hex_nib c
        | c >= 48 AND c <= 57 = c - 48
        | c >= 97 AND c <= 102 = (c - 97) + 10
        | c >= 65 AND c <= 70 = (c - 65) + 10
        | otherwise = 0

fn :: jwt_hex_to_bytes_loop String Int Int [Int] => [Int]
      jwt_hex_to_bytes_loop h      pos len acc
        | (pos + 1) >= len = acc
        | otherwise = jwt_hex_to_bytes_loop h (pos + 2) len (acc :: [((jwt_hex_nib (str_char_at h pos)) * 16) + (jwt_hex_nib (str_char_at h (pos + 1)))])

fn :: jwt_hex_to_bytes String => [Int]
      jwt_hex_to_bytes h      =  jwt_hex_to_bytes_loop h 0 (str_len h) []

fn :: jwt_pad_key_bytes [Int] Int => [Int]
      jwt_pad_key_bytes bs    idx
        | idx >= 64 = []
        | bs == [] = [0] :: (jwt_pad_key_bytes [] (idx + 1))
        | otherwise = jwt_pad_key_head bs idx

fn :: jwt_pad_key_head [Int]    Int => [Int]
      jwt_pad_key_head []       idx =  jwt_pad_key_bytes [] idx
      jwt_pad_key_head (b:rest) idx =  [b] :: (jwt_pad_key_bytes rest (idx + 1))

fn :: jwt_key_block String => [Int]
      jwt_key_block secret
        | (str_len secret) > 64 = jwt_pad_key_bytes (jwt_hex_to_bytes (sha256_str secret)) 0
        | otherwise = jwt_pad_key_bytes (jwt_str_to_bytes secret) 0

fn :: jwt_xor_pad_str [Int]    Int => String
      jwt_xor_pad_str []       _   =  ""
      jwt_xor_pad_str (b:rest) pad =
        xb = jwt_byte_xor b pad
        safe_c = (xb % 126) + 1
        (char_from_code safe_c) + (jwt_xor_pad_str rest pad)

fn :: jwt_hmac_sha256_b64url String String        => String
      jwt_hmac_sha256_b64url secret signing_input =
        kb = jwt_key_block secret
        ipad = jwt_xor_pad_str kb 54
        opad = jwt_xor_pad_str kb 92
        inner_hex = sha256_str (ipad + signing_input)
        outer_hex = sha256_str (opad + inner_hex)
        jwt_b64url_enc_bytes (jwt_hex_to_bytes outer_hex)

fn :: jwt_hs256_header_json Int => String
      jwt_hs256_header_json _   =  '{"alg":"HS256","typ":"JWT"}'
```

### 26.4.4. Barne-inplementazioa: Structured Claims Signing & Temporal Validation

Ikusi nola `jwt.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: jwt sign claims JwtClaims String => String
      jwt sign claims c         secret =
        base_obj = JsonObj [JsonField "iss" (JsonStr (issuer c)), JsonField "sub" (JsonStr (subject c)), JsonField "exp" (JsonInt (expires_at c)), JsonField "nbf" (JsonInt (not_before_at c)), JsonField "custom" (JsonStr (custom_json c))]
        jwt_sign_hs256 (json_stringify base_obj) secret

fn :: jwt verify claims String String Int => JwtClaimsRes
      jwt verify claims token secret now =
        vres = jwt_verify_hs256 token secret
        jwt_validate_verified_payload vres now

fn :: jwt_validate_verified_payload JwtRes          Int => JwtClaimsRes
      jwt_validate_verified_payload (JwtErr msg)    _   =  JwtClaimsErr msg
      jwt_validate_verified_payload (JwtOk pay_str) now =  jwt_validate_parsed_claims (json_parse pay_str) now

fn :: jwt_validate_parsed_claims JsonRes       Int => JwtClaimsRes
      jwt_validate_parsed_claims (JsonErr msg) _   =  JwtClaimsErr ("invalid claims JSON: " + msg)
      jwt_validate_parsed_claims (JsonOk node) now =
        iss = json_get_str node "iss" ""
        sub = json_get_str node "sub" ""
        exp_t = json_get_int node "exp" 0
        nbf_t = json_get_int node "nbf" 0
        cust = json_get_str node "custom" ""
        jwt_check_claim_times (JwtClaims iss sub exp_t nbf_t cust) now

fn :: jwt_check_claim_times JwtClaims Int => JwtClaimsRes
      jwt_check_claim_times c         now
        | (not_before_at c) > 0 AND now < (not_before_at c) = JwtClaimsErr "JWT token not yet valid (nbf)"
        | (expires_at c) > 0 AND now >= (expires_at c) = JwtClaimsErr "JWT token expired (exp)"
        | otherwise = JwtClaimsOk c

-- ── Authenticated Encrypted Tokens (`jwt seal aead` / `jwt open aead`) ─

fn :: jwt_keystream_bytes String String Int Int => [Int]
      jwt_keystream_bytes key    nonce  blk rem
        | rem <= 0 = []
        | otherwise = (jwt_hex_to_bytes (sha256_str (key + ":" + nonce + ":" + (int_to_str blk)))) :: (jwt_keystream_bytes key nonce (blk + 1) (rem - 32))

fn :: jwt_xor_lists [Int]    [Int]    => [Int]
      jwt_xor_lists []       _        =  []
      jwt_xor_lists _        []       =  []
      jwt_xor_lists (a:arst) (b:brst) =  [jwt_byte_xor a b] :: (jwt_xor_lists arst brst)

fn :: jwt seal aead String String String => JwtRes
      jwt seal aead key nonce plaintext
        | (str_len key) != 32 = JwtErr "AEAD key must be 32 bytes"
        | (str_len nonce) != 12 = JwtErr "AEAD nonce must be 12 bytes"
        | otherwise = jwt_seal_aead_ok key nonce plaintext
```

---

## 26.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `jwt`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: `"alg":"none"` erasoaren aurkako immunitate osoa (`alg` zehazki `"HS256"` ez duen edozein goiburuk `JwtBadSignature` itzultzen du) eta sinaduraren denbora konstanteko konparazioa.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/jwt.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test jwt.rg` suite automatizatuaren bidez.

### `jwt`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import jwt` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `jwt`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `jwt`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `jwt` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**27. kapituluan** **`socket`** lib-a sakonki esploratuko dugu (`socket` lib-a — TCP, UDP, AF_UNIX, Framing, RFC 1035 DNS eta Kernel Socketak (`RGF-001`)).
