# 26. kapitulua: `jwt` lib-a — RFC 7519 JSON Web Tokenak (`HS256`) eta ChaCha20-Poly1305 Token Zifratuak

## 26.1. Zergatik existitzen da `jwt` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `jwt` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `jwt`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: JWT ekosistema ospetsua da erasotzaile batek goiburua `"alg":"none"`-ra aldatzen duen eta zerbitzariak tokena sinadurarik gabe onartzen duen ahultasunengatik, edo payload-a Base64url-n kodetuta baino ez dagoela ahaztuta informazio sentikorra gordetzeagatik.

**`jwt`** lib-ak bi munduak konpontzen ditu: **RFC 7519 (`HS256`) JWTak** sinatu eta egiaztatzen ditu `alg == "HS256"` esplizituki eskatuz, HMACa denbora konstantean konparatuz eta `exp`/`nbf` baliozkotuz, eta gainera **`jwt seal aead` / `jwt open aead`** eskaintzen ditu **ChaCha20-Poly1305 AEAD** bidez zifratutako token opakuak jaulkitzeko.

Ekosistema tradizional batean, **`JWT`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`jwt`** lib-ak (`src/main/ridgun/lib/jwt.ridgun`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import jwt` (edo `import jwt as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: jwt` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `jwt`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 26.2. Artefaktu natiboak, inportazioa eta `jwt` APIaren katalogo osoa

`ridgun-libs`-en, **`jwt`** lehen mailako **lib** bat da, `src/main/ridgun/lib/jwt.ridgun` bidean kokatua (`JWT` domeinua). `stable bundle`-ekin konpilatzean, formatu natibo bakarrean paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/jwt.ridgunlib` | Banaketa eta inportazio zuzena `import jwt` bidez |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: jwt` bidez: nahikoa da goiburuan `import jwt` (edo `import jwt as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 26.2.1. `jwt`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `JwtRes / JwtClaimsRes` | `JwtOk` / `JwtErr`, `JwtClaimsOk` / `JwtClaimsErr` |
| `jwt sign hs256 / jwt verify hs256` | `JsonVal` claim-ak sinatzen ditu eta sinadura + `alg == "HS256"` + `exp`/`nbf` egiaztatzen ditu |
| `jwt sign claims / jwt verify claims` | `(sub, iss, iat, exp)` claim estandarrak eraiki eta egiaztatutako payload-ak kontsultatzen ditu |
| `jwt seal aead / jwt open aead` | JSON token opakuak zifratu eta autentifikatzen ditu ChaCha20-Poly1305 AEAD bidez |

### 26.2.2. `src/main/ridgun/lib/jwt.ridgun`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/jwt.ridgun` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`3` mota, `0` eragile eta `51` funtzio):

**`jwt`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: jwt blen Tensor[U8]` | `Int` |
| `2` | `fn :: jwt u8 Int` | `Int` |
| `3` | `fn :: jwt b64url lut Int` | `String` |
| `4` | `fn :: jwt b64 code String Int` | `Int` |
| `5` | `fn :: jwt b64 val Int` | `Int` |
| `6` | `fn :: jwt b64url enc len Int` | `Int` |
| `7` | `fn :: jwt b64url enc bytes Tensor[U8]` | `String` |
| `8` | `fn :: jwt b64url enc loop Tensor[U8] Int Tensor[U8] String Int Int` | `Tensor[U8]` |
| `9` | `fn :: jwt b64url enc group Tensor[U8] Int Tensor[U8] String Int Int` | `Tensor[U8]` |
| `10` | `fn :: jwt b64url enc tail1 Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `11` | `fn :: jwt b64url enc tail2 Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `12` | `fn :: jwt b64url encode String` | `String` |
| `13` | `fn :: jwt b64url valid loop String Int Int` | `Bool` |
| `14` | `fn :: jwt b64url is valid String` | `Bool` |
| `15` | `fn :: jwt b64url dec len Int` | `Int` |
| `16` | `fn :: jwt b64 at String Int` | `Int` |
| `17` | `fn :: jwt b64url dec loop String Int Tensor[U8] Int` | `Tensor[U8]` |
| `18` | `fn :: jwt b64url dec4 String Int Tensor[U8] Int` | `Tensor[U8]` |
| `19` | `fn :: jwt b64url dec3 String Tensor[U8] Int` | `Tensor[U8]` |
| `20` | `fn :: jwt b64url dec2 String Tensor[U8] Int` | `Tensor[U8]` |
| `21` | `fn :: jwt b64url decode bytes String` | `Tensor[U8]` |
| `22` | `fn :: jwt b64url decode String` | `String` |
| `23` | `fn :: jwt byte bxor Int Int` | `Int` |
| `24` | `fn :: jwt ct diff String String Int Int Int` | `Int` |
| `25` | `fn :: jwt ct eq String String` | `Bool` |
| `26` | `fn :: jwt hmac sha256 b64url String String` | `String` |
| `27` | `fn :: jwt hs256 header json Int` | `String` |
| `28` | `fn :: jwt sign hs256 String String` | `String` |
| `29` | `fn :: jwt split dots loop String Int Int Int [String]` | `[String]` |
| `30` | `fn :: jwt str list len [String]` | `Int` |
| `31` | `fn :: jwt str at [String] Int` | `String` |
| `32` | `fn :: jwt decode payload String` | `JwtRes` |
| `33` | `fn :: jwt decode parts [String]` | `JwtRes` |
| `34` | `fn :: jwt header is hs256 String` | `Bool` |
| `35` | `fn :: jwt check hdr json JsonRes` | `Bool` |
| `36` | `fn :: jwt verify hs256 String String` | `JwtRes` |
| `37` | `fn :: jwt verify parts [String] String` | `JwtRes` |
| `38` | `fn :: jwt verify sig String String String String` | `JwtRes` |
| `39` | `fn :: jwt verify sig ct Bool String` | `JwtRes` |
| `40` | `fn :: jwt sign claims JwtClaims String` | `String` |
| `41` | `fn :: jwt verify claims String String Int` | `JwtClaimsRes` |
| `42` | `fn :: jwt validate verified payload JwtRes Int` | `JwtClaimsRes` |
| `43` | `fn :: jwt validate parsed claims JsonRes Int` | `JwtClaimsRes` |
| `44` | `fn :: jwt check claim times JwtClaims Int` | `JwtClaimsRes` |
| `45` | `fn :: jwt aead version` | `String` |
| `46` | `fn :: jwt seal aead String String String` | `JwtRes` |
| `47` | `fn :: jwt seal aead ok String String String` | `JwtRes` |
| `48` | `fn :: jwt open aead String String String` | `JwtRes` |
| `49` | `fn :: jwt open aead parts String String [String]` | `JwtRes` |
| `50` | `fn :: jwt open aead verify String String String String String` | `JwtRes` |
| `51` | `fn :: jwt open aead result (Int String)` | `JwtRes` |

---

## 26.3. `jwt` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `jwt` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test jwt.ridgun`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 26.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `jwt` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `jwt` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import jwt

fn :: sujeto de JwtClaimsRes     => String
      sujeto de (JwtClaimsOk c)  =  subject c
      sujeto de (JwtClaimsErr e) =  "error: " + e

fn :: emitir y verificar sesion String => String String
      emitir y verificar sesion secreto =
        jwt sign claims (JwtClaims "solstice" "user-42" 1700003600 0 "{}") secreto -> tok
        jwt verify claims tok secreto 1700001000 -> res
        (tok, sujeto de res)
```

### 26.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`jwt` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 38 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import jwt

fn :: abrir sobre JwtRes       String String => JwtRes
      abrir sobre (JwtOk tok)  clave  nonce  =  jwt open aead clave nonce tok
      abrir sobre (JwtErr e)   _      _      =  JwtErr e

fn :: sellar token confidencial String => JwtRes
      sellar token confidencial clave =
        jwt seal aead clave "nonce-12byte" "{\"rol\":\"root\",\"pin\":\"9988\"}" -> sobre
        abrir sobre sobre clave "nonce-12byte"
```

### 26.3.3. 3. adibidea: JWT HS256 sinadura eta egiaztapena (`jwt sign hs256`, `jwt verify hs256`), `alg: none` erasoaren ukapena eta sinadura-manipulazioaren detekzioa

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test jwt hs256 sign verify and tamper => ()
      test jwt hs256 sign verify and tamper =
        payload = '{"sub":"user-42","role":"admin"}'
        secret = "super-secret-hmac-key-2026"
        tok = jwt sign hs256 payload secret

        dec = jwt decode payload tok
        is jwt ok dec -> assert true "AC1: jwt decode payload succeeds"
        unwrap jwt dec -> assert str eq payload "AC1: decoded payload matches input"

        ver = jwt verify hs256 tok secret
        is jwt ok ver -> assert true "AC2: jwt verify hs256 accepts valid signature"
        unwrap jwt ver -> assert str eq payload "AC2: verified payload matches input"

        wrong_sec = jwt verify hs256 tok "wrong-secret"
        is jwt ok wrong_sec -> assert false "AC2: jwt verify hs256 rejects wrong secret"
        is jwt ok (jwt verify hs256 tok "") -> assert false "AC2: jwt verify hs256 rejects empty secret"

        tampered = tok + "x"
        is jwt ok (jwt verify hs256 tampered secret) -> assert false "AC2: jwt verify hs256 rejects tampered signature"

        -- CVE/RFC 8725 attacks: alg:none, empty signature segment, malformed segment counts
        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        is jwt ok (jwt verify hs256 alg_none_tok secret) -> assert false "AC2: jwt verify hs256 rejects alg:none"
        alg_none_empty_sig = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0."
        is jwt ok (jwt verify hs256 alg_none_empty_sig secret) -> assert false "AC2: jwt verify hs256 rejects empty signature"
        is jwt ok (jwt verify hs256 "only_one_segment" secret) -> assert false "AC2: reject 1-segment token"
        is jwt ok (jwt verify hs256 "two.segments" secret) -> assert false "AC2: reject 2-segment token"
        is jwt ok (jwt decode payload "bad_token_without_dots") -> assert false "AC1: decode rejects token without 3 segments"
        ()
```

### 26.3.4. 4. adibidea: Egituratutako *claim*-en denbora-baliozkotzea (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) `jwt verify claims` bidez

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test jwt claims temporal validation => ()
      test jwt claims temporal validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        -- Exact nbf boundary: now == 1000 is valid (now >= nbf)
        at_nbf_res = jwt verify claims tok secret 1000
        is claims ok at_nbf_res -> assert true "AC2: claims valid at exact nbf boundary (now == 1000)"

        ok_res = jwt verify claims tok secret 1500
        is claims ok ok_res -> assert true "AC2: claims valid at now=1500"
        c_out = unwrap claims ok_res
        issuer c_out -> assert str eq "ridgun-auth" "AC2: issuer preserved"
        subject c_out -> assert str eq "agent-007" "AC2: subject preserved"
        expires_at c_out -> assert int equals 2000 "AC2: expires_at preserved"
        not_before_at c_out -> assert int equals 1000 "AC2: not_before_at preserved"
        custom_json c_out -> assert str eq "tier=gold" "AC2: custom_json preserved"

        -- 1 second before exp: now == 1999 is valid
        before_exp_res = jwt verify claims tok secret 1999
        is claims ok before_exp_res -> assert true "AC2: claims valid 1s before exp (1999 < 2000)"

        -- 1 second before nbf: now == 999 is rejected
        early_res = jwt verify claims tok secret 999
        is claims ok early_res -> assert false "AC2: claims rejected before nbf (999 < 1000)"

        -- Exact exp boundary and after: now == 2000 and now == 5000 rejected
        exp_res = jwt verify claims tok secret 2000
        is claims ok exp_res -> assert false "AC2: claims rejected at exact exp (2000 >= 2000)"
        late_res = jwt verify claims tok secret 5000
        is claims ok late_res -> assert false "AC2: claims rejected after exp (5000 >= 2000)"
        is claims ok (jwt verify claims tok "wrong-secret" 1500) -> assert false "AC2: claims rejected with wrong secret"
        ()
```

### 26.3.5. 5. adibidea: ChaCha20-Poly1305 AEAD bidez zifratu eta autentifikatutako tokenak (`jwt seal aead`, `jwt open aead`)

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test jwt aead seal and open => ()
      test jwt aead seal and open =
        key32 = "0123456789abcdef0123456789abcdef"
        other_key32 = "fedcba9876543210fedcba9876543210"
        nonce12 = "uniqueNonce1"
        other_nonce12 = "uniqueNonce2"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        is jwt ok sealed -> assert true "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap jwt sealed

        opened = jwt open aead key32 nonce12 tok
        is jwt ok opened -> assert true "AC3: jwt open aead succeeds"
        unwrap jwt opened -> assert str eq secret_msg "AC3: jwt open aead round-trips plaintext"

        is jwt ok (jwt open aead other_key32 nonce12 tok) -> assert false "AC3: jwt open aead rejects wrong 32B key"
        is jwt ok (jwt open aead key32 other_nonce12 tok) -> assert false "AC3: jwt open aead rejects wrong 12B nonce"
        is jwt ok (jwt open aead key32 nonce12 (tok + "A")) -> assert false "AC3: jwt open aead rejects tampered ciphertext/tag"
        is jwt ok (jwt seal aead "short" nonce12 secret_msg) -> assert false "AC3: jwt seal aead rejects non-32B key"
        is jwt ok (jwt seal aead key32 "short" secret_msg) -> assert false "AC3: jwt seal aead rejects non-12B nonce"
        ()
```

### 26.3.6. 6. adibidea: Bitarrekiko segurua den Base64url eta bytez byteko UTF-8 payload-ak

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test jwt bytes and utf8 round trip => ()
      test jwt bytes and utf8 round trip =
        bs = Tensor[U8 * 3]
        bs_(1) = 128
        bs_(2) = 255
        enc = jwt b64url enc bytes bs
        enc -> assert str eq "AID_" "AC1: Base64url of bytes [0, 128, 255]"
        dec = jwt b64url decode bytes enc
        dec == bs -> assert true "AC1: Base64url decode gives bytes [0, 128, 255]"
        jwt b64url encode "foobar" -> assert str eq "Zm9vYmFy" "AC1: RFC 4648 vector foobar"
        jwt b64url decode "Zm9vYg" -> assert str eq "foob" "AC1: RFC 4648 vector foob, unpadded"

        utf8_payload = '{"name":"José"}'
        tok = jwt sign hs256 utf8_payload "utf8-secret"
        unwrap jwt (jwt verify hs256 tok "utf8-secret") -> assert str eq utf8_payload "AC2: UTF-8 payload verifies byte for byte"
        unwrap jwt (jwt decode payload tok) -> assert str eq utf8_payload "AC1: UTF-8 payload decodes byte for byte"

        key32 = "0123456789abcdef0123456789abcdef"
        nonce12 = "uniqueNonce1"
        utf8_msg = "ñandú-ü-€"
        sealed = unwrap jwt (jwt seal aead key32 nonce12 utf8_msg)
        unwrap jwt (jwt open aead key32 nonce12 sealed) -> assert str eq utf8_msg "AC3: UTF-8 plaintext round-trips byte for byte"
        ()
```

### 26.3.7. 7. adibidea: Bektore estandarrak: RFC 4231 HMAC, RFC 7515 A.1 HS256 eta RFC 8439 token zigilatuak (`RGAEAD2`)

Adibide praktiko honetan `jwt` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test jwt standard vectors => ()
      test jwt standard vectors =
        jwt hmac sha256 b64url "Jefe" "what do ya want for nothing?" -> assert str eq "W9zBRr9gdU5qBCQmCJV1x1oAPwidJzmDnexYuWTsOEM" "AC2: HMAC-SHA256 is RFC 4231 test case 2"

        rfc_key = jwt b64url decode "AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow"
        rfc_in = "eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ"
        rfc_sig = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        jwt hmac sha256 b64url rfc_key rfc_in -> assert str eq rfc_sig "AC2: RFC 7515 A.1 HS256 signature"
        rfc_res = jwt verify hs256 (rfc_in + "." + rfc_sig) rfc_key
        is jwt ok rfc_res -> assert true "AC2: RFC 7515 A.1 token verifies"
        str starts with (unwrap jwt rfc_res) '{"iss":"joe",' -> assert true "AC2: RFC 7515 A.1 payload"

        key = bytes from list [128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159]
        nonce = bytes from list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        pt = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
        sealed = jwt seal aead key nonce pt
        is jwt ok sealed -> assert true "AC3: jwt seal aead with the RFC 8439 key and nonce"
        ct = jwt b64url decode bytes (jwt token part sealed 2)
        ct_list = tensor to list ct
        (first n ct_list 16) == [211, 26, 141, 52, 100, 142, 96, 219, 123, 134, 175, 188, 83, 239, 126, 194] -> assert true "AC3: ciphertext is RFC 8439 2.8.2 ChaCha20"
        aad = "RGAEAD2." + (jwt token part sealed 1)
        tag = jwt b64url decode (jwt token part sealed 3)
        (aead seal key nonce aad pt) == ((tensor to str ct) + tag) -> assert true "AC3: token is RFC 8439 ChaCha20-Poly1305 over the version and nonce as AAD"
        is jwt ok (jwt open aead key nonce ("RGAEAD1." + (jwt token part sealed 1) + "." + (jwt token part sealed 2) + "." + (jwt token part sealed 3))) -> assert false "AC3: tokens of the old RGAEAD1 format are rejected"
        ()
```

---

## 26.4. Kaputaren azpian: nola dagoen eraikia `jwt` Ridgun hutsean (`src/main/ridgun/lib/jwt.ridgun`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/jwt.ridgun` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 26.4.1. Barne-inplementazioa: Tensor[U8] Byte & Base64url Helpers (ADR-0010)

Ikusi nola `jwt.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
module :: jwt

fn :: jwt blen Tensor[U8] => Int
      jwt blen (Tensor[U8 * n] t) = n

fn :: jwt u8 Int => Int
      jwt u8 x = ((x % 256) + 256) % 256

fn :: jwt b64url lut Int => String
      jwt b64url lut _ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: jwt b64 code String Int => Int
      jwt b64 code tbl idx = str char at tbl (((idx % 64) + 64) % 64)

fn :: jwt b64 val Int => Int
      jwt b64 val c =
        | c >= 65 and c <= 90 = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57 = (c - 48) + 52
        | c == 45 or c == 43 = 62
        | c == 95 or c == 47 = 63
        | otherwise = (0 - 1)

-- Unpadded Base64url (RFC 4648 §5) length of n bytes.
fn :: jwt b64url enc len Int => Int
      jwt b64url enc len n =
        | (n % 3) == 0 = (n / 3) * 4
        | otherwise = ((n / 3) * 4) + (n % 3) + 1

fn :: jwt b64url enc bytes Tensor[U8] => String
      jwt b64url enc bytes bs =
        n = jwt blen bs
        out = Tensor[U8 * (jwt b64url enc len n)]
        jwt b64url enc loop bs n out (jwt b64url lut 0) 0 0 -> tensor to str

fn :: jwt b64url enc loop Tensor[U8] Int Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc loop bs n out tbl i o =
        | i >= n = out
        | (n - i) == 1 = jwt b64url enc tail1 bs out tbl i o
        | (n - i) == 2 = jwt b64url enc tail2 bs out tbl i o
        | otherwise = jwt b64url enc group bs n out tbl i o

fn :: jwt b64url enc group Tensor[U8] Int Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc group bs n out tbl i o =
        v = (bs_(i) * 65536) + (bs_(i + 1) * 256) + bs_(i + 2)
        out_(o) = jwt b64 code tbl (v / 262144)
        out_(o + 1) = jwt b64 code tbl ((v / 4096) % 64)
        out_(o + 2) = jwt b64 code tbl ((v / 64) % 64)
        out_(o + 3) = jwt b64 code tbl (v % 64)
        jwt b64url enc loop bs n out tbl (i + 3) (o + 4)

fn :: jwt b64url enc tail1 Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc tail1 bs out tbl i o =
        b0 = bs_(i)
        out_(o) = jwt b64 code tbl (b0 / 4)
        out_(o + 1) = jwt b64 code tbl ((b0 % 4) * 16)
        out

fn :: jwt b64url enc tail2 Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc tail2 bs out tbl i o =
        v = (bs_(i) * 256) + bs_(i + 1)
        out_(o) = jwt b64 code tbl (v / 1024)
        out_(o + 1) = jwt b64 code tbl ((v / 16) % 64)
        out_(o + 2) = jwt b64 code tbl ((v % 16) * 4)
        out

fn :: jwt b64url encode String => String
      jwt b64url encode s = s tensor from str -> jwt b64url enc bytes

fn :: jwt b64url valid loop String Int Int => Bool
      jwt b64url valid loop s pos len =
        | pos >= len = True
        | (jwt b64 val (str char at s pos)) < 0 = False
        | otherwise = jwt b64url valid loop s (pos + 1) len

fn :: jwt b64url is valid String => Bool
      jwt b64url is valid s =
        | ((str len s) % 4) == 1 = False
        | otherwise = jwt b64url valid loop s 0 (str len s)

-- Decoded length of an unpadded Base64url text of len characters (a trailing single character is ignored).
fn :: jwt b64url dec len Int => Int
      jwt b64url dec len len =
        | (len % 4) == 2 = ((len / 4) * 3) + 1
        | (len % 4) == 3 = ((len / 4) * 3) + 2
        | otherwise = (len / 4) * 3

fn :: jwt b64 at String Int => Int
      jwt b64 at s pos = jwt b64 val (str char at s pos)

fn :: jwt b64url dec loop String Int Tensor[U8] Int => Tensor[U8]
      jwt b64url dec loop s len out o =
        | (len - ((o / 3) * 4)) >= 4 = jwt b64url dec4 s len out o
        | (len - ((o / 3) * 4)) == 3 = jwt b64url dec3 s out o
        | (len - ((o / 3) * 4)) == 2 = jwt b64url dec2 s out o
        | otherwise = out

fn :: jwt b64url dec4 String Int Tensor[U8] Int => Tensor[U8]
      jwt b64url dec4 s len out o =
        pos = (o / 3) * 4
        n = ((jwt b64 at s pos) * 262144) + ((jwt b64 at s (pos + 1)) * 4096) + ((jwt b64 at s (pos + 2)) * 64) + (jwt b64 at s (pos + 3))
        out_(o) = jwt u8 (n / 65536)
        out_(o + 1) = jwt u8 (n / 256)
        out_(o + 2) = jwt u8 n
        jwt b64url dec loop s len out (o + 3)

fn :: jwt b64url dec3 String Tensor[U8] Int => Tensor[U8]
      jwt b64url dec3 s out o =
        pos = (o / 3) * 4
        n = ((jwt b64 at s pos) * 1024) + ((jwt b64 at s (pos + 1)) * 16) + ((jwt b64 at s (pos + 2)) / 4)
        out_(o) = jwt u8 (n / 256)
        out_(o + 1) = jwt u8 n
        out

fn :: jwt b64url dec2 String Tensor[U8] Int => Tensor[U8]
      jwt b64url dec2 s out o =
        pos = (o / 3) * 4
        out_(o) = jwt u8 (((jwt b64 at s pos) * 4) + ((jwt b64 at s (pos + 1)) / 16))
        out

fn :: jwt b64url decode bytes String => Tensor[U8]
      jwt b64url decode bytes s =
        len = str len s
        out = Tensor[U8 * (jwt b64url dec len len)]
        jwt b64url dec loop s len out 0

fn :: jwt b64url decode String => String
      jwt b64url decode s = s jwt b64url decode bytes -> tensor to str
```

### 26.4.2. Barne-inplementazioa: Constant-Time Equality

Ikusi nola `jwt.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: jwt byte bxor Int Int => Int
      jwt byte bxor a b = (jwt u8 a) xor (jwt u8 b)

fn :: jwt ct diff String String Int Int Int => Int
      jwt ct diff a b idx len acc =
        | idx >= len = acc
        | otherwise = jwt ct diff a b (idx + 1) len (acc or (jwt byte bxor (str char at a idx) (str char at b idx)))

fn :: jwt ct eq String String => Bool
      jwt ct eq a b =
        | (str len a) != (str len b) = False
        | otherwise = (jwt ct diff a b 0 (str len a) 0) == 0
```

### 26.4.3. Barne-inplementazioa: HS256 (HMAC-SHA256) Signing & Verification

Ikusi nola `jwt.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
-- RFC 2104 HMAC-SHA256 (crypto lib, RFC 4231 vectors), as an unpadded Base64url tag.
fn :: jwt hmac sha256 b64url String String => String
      jwt hmac sha256 b64url secret signing_input =  hmac sha256 secret signing_input -> tensor from str -> jwt b64url enc bytes

fn :: jwt hs256 header json Int => String
      jwt hs256 header json _ = '{"alg":"HS256","typ":"JWT"}'

fn :: jwt sign hs256 String String => String
      jwt sign hs256 payload_json secret =
        jwt hs256 header json 0 -> jwt b64url encode -> hdr_b64
        payload_json jwt b64url encode -> pay_b64
        hdr_b64 + "." + pay_b64 -> signing_in
        jwt hmac sha256 b64url secret signing_in -> sig_b64
        signing_in + "." + sig_b64

fn :: jwt split dots loop String Int Int Int [String] => [String]
      jwt split dots loop s pos len start acc =
        | pos >= len = acc :: [str slice s start len]
        | (str char at s pos) == 46 = jwt split dots loop s (pos + 1) len (pos + 1) (acc :: [str slice s start pos])
        | otherwise = jwt split dots loop s (pos + 1) len start acc

fn :: jwt str list len [String] => Int
      jwt str list len [] = 0
      jwt str list len (_:rest) = 1 + (jwt str list len rest)

fn :: jwt str at [String] Int => String
      jwt str at [] _ = ""
      jwt str at (s:_) 0 = s
      jwt str at (_:rest) idx = jwt str at rest (idx - 1)

fn :: jwt decode payload String => JwtRes
      jwt decode payload token =
        jwt split dots loop token 0 (str len token) 0 [] -> parts
        jwt decode parts parts

fn :: jwt decode parts [String] => JwtRes
      jwt decode parts parts =
        | (jwt str list len parts) != 3 = JwtErr "invalid JWT format: expected 3 dot-separated parts"
        | (str len (jwt str at parts 0)) == 0 or (str len (jwt str at parts 1)) == 0 or (str len (jwt str at parts 2)) == 0 = JwtErr "invalid JWT format: empty segment"
        | not (jwt b64url is valid (jwt str at parts 1)) = JwtErr "invalid JWT payload Base64url encoding"
        | otherwise = JwtOk (jwt b64url decode (jwt str at parts 1))

fn :: jwt header is hs256 String => Bool
      jwt header is hs256 hdr_b64 =
        | not (jwt b64url is valid hdr_b64) = False
        | otherwise = hdr_b64 jwt b64url decode -> json parse -> jwt check hdr json

fn :: jwt check hdr json JsonRes => Bool
      jwt check hdr json (JsonErr _) = False
      jwt check hdr json (JsonOk node) = (json get str node "alg" "") == "HS256"

fn :: jwt verify hs256 String String => JwtRes
      jwt verify hs256 token secret =
        jwt split dots loop token 0 (str len token) 0 [] -> parts
        jwt verify parts parts secret

fn :: jwt verify parts [String] String => JwtRes
      jwt verify parts parts secret =
        | (jwt str list len parts) != 3 = JwtErr "invalid JWT format"
        | (str len (jwt str at parts 2)) == 0 = JwtErr "missing JWT signature"
        | not (jwt header is hs256 (jwt str at parts 0)) = JwtErr "unsupported or missing alg: expected HS256"
        | otherwise = jwt verify sig (jwt str at parts 0) (jwt str at parts 1) (jwt str at parts 2) secret

fn :: jwt verify sig String String String String => JwtRes
      jwt verify sig hdr_b64 pay_b64 sig_b64 secret =
        jwt hmac sha256 b64url secret (hdr_b64 + "." + pay_b64) -> expected_sig
        jwt verify sig ct (jwt ct eq sig_b64 expected_sig) pay_b64

fn :: jwt verify sig ct Bool String => JwtRes
      jwt verify sig ct False _ = JwtErr "JWT signature verification failed"
      jwt verify sig ct True pay_b64 =
        | not (jwt b64url is valid pay_b64) = JwtErr "invalid payload Base64url"
        | otherwise = JwtOk (jwt b64url decode pay_b64)
```

### 26.4.4. Barne-inplementazioa: Structured Claims Signing & Temporal Validation

Ikusi nola `jwt.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: jwt sign claims JwtClaims String => String
      jwt sign claims c secret =
        JsonObj [JsonField "iss" (JsonStr (issuer c)), JsonField "sub" (JsonStr (subject c)), JsonField "exp" (JsonInt (expires_at c)), JsonField "nbf" (JsonInt (not_before_at c)), JsonField "custom" (JsonStr (custom_json c))] -> base_obj
        jwt sign hs256 (json stringify base_obj) secret

fn :: jwt verify claims String String Int => JwtClaimsRes
      jwt verify claims token secret now =
        jwt verify hs256 token secret -> vres
        jwt validate verified payload vres now

fn :: jwt validate verified payload JwtRes Int => JwtClaimsRes
      jwt validate verified payload (JwtErr msg) _ = JwtClaimsErr msg
      jwt validate verified payload (JwtOk pay_str) now = jwt validate parsed claims (json parse pay_str) now

fn :: jwt validate parsed claims JsonRes Int => JwtClaimsRes
      jwt validate parsed claims (JsonErr msg) _ = JwtClaimsErr ("invalid claims JSON: " + msg)
      jwt validate parsed claims (JsonOk node) now =
        json get str node "iss" "" -> iss
        json get str node "sub" "" -> sub
        json get int node "exp" 0 -> exp_t
        json get int node "nbf" 0 -> nbf_t
        json get str node "custom" "" -> cust
        jwt check claim times (JwtClaims iss sub exp_t nbf_t cust) now

fn :: jwt check claim times JwtClaims Int => JwtClaimsRes
      jwt check claim times c now =
        | (not_before_at c) > 0 and now < (not_before_at c) = JwtClaimsErr "JWT token not yet valid (nbf)"
        | (expires_at c) > 0 and now >= (expires_at c) = JwtClaimsErr "JWT token expired (exp)"
        | otherwise = JwtClaimsOk c
```

---

## 26.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `jwt`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: `"alg":"none"` erasoaren aurkako immunitate osoa (`alg` zehazki `"HS256"` ez duen edozein goiburuk `JwtErr` itzultzen du) eta sinaduraren denbora konstanteko konparazioa.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/jwt.ridgun`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test jwt.ridgun` suite automatizatuaren bidez.

### `jwt`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import jwt` fitxategiaren hasieran** eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `jwt`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `jwt`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `jwt` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**27. kapituluan** **`socket`** lib-a sakonki esploratuko dugu (`socket` lib-a — TCP, UDP, AF_UNIX, Framing, RFC 1035 DNS eta Kernel Socketak (`RGF-001`)).
