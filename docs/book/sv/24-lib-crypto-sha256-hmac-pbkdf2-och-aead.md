# Kapitel 24: Lib:en `crypto` — SHA-256, HMAC, PBKDF2, Argon2id och ChaCha20-Poly1305 AEAD

## 24.1. Varför finns lib:en `crypto`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `crypto`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `crypto`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att jämföra en HMAC med `==` öppnar dörren för sidokanalsattacker (*timing attacks*), och att länka in `libssl.so` för att beräkna `SHA-256` eller kryptera med `ChaCha20-Poly1305` förstör binärens portabilitet.

Lib:en **`crypto`** implementerar i 100 % ren Ridgun över förallokerade `Tensor[Int]`: byte-/bitprimitiver (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, konstanttidslikhet (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256**, 5-arguments **Argon2id** samt autentiserad kryptering med **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`CRYPTO`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`crypto`** (`src/main/ridgun/lib/crypto.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import crypto` (eller `import crypto as alias`) överst i filen**: varje lib definierar sin `module :: crypto`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `crypto` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 24.2. Inbyggda artefakter, import och komplett API-katalog för `crypto`

I `ridgun-libs` är **`crypto`** en förstklassig **lib** placerad i `src/main/ridgun/lib/crypto.rg` (domän `CRYPTO`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/crypto.rglib` | Portabel distribution och direkt import med `import crypto` |
| **Kompilerat arkiv** | `target/crypto.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcrypto.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: crypto`: skriv bara `import crypto` (eller `import crypto as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 24.2.1. Översikt över funktionella familjer i `crypto`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `sha256 bytes / sha256 hex` | FIPS 180-4 SHA-256 som 32-bytes binär digest eller 64-teckens hex-sträng |
| `hmac sha256 / hmac sha256 hex / ct equal` | RFC 2104-nycklad MAC och ackumulatorjämförelse i konstant tid |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | RFC 8018-nyckelhärledning med förberäknade inre/yttre SHA-256-mellantillstånd |
| `argon2id hash / argon2id verify` | 5-arguments RFC 9106 PHC-lösenordshashning och konstanttidsverifiering |
| `aead seal / aead open` | RFC 8439 ChaCha20-Poly1305 autentiserad kryptering och taggverifierad dekryptering |
| `sha512 bytes / sha512 hex` | 64-byte rått binärt eller 128-teckens hexadecimalt FIPS 180-4 SHA-512-sammandrag |
| `ed25519 public key / ed25519 sign / ed25519 verify` | RFC 8032 §5.1 ren Ed25519 publik nyckel, konstanttidssignering och kanonisk verifiering |
| `minisign sign / minisign verify / minisign trusted comment` | Publika nycklar och `.minisig`-signaturer kompatibla med standardverktyget `minisign` |

### 24.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/crypto.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/crypto.rg` (`2` typer, `0` operatorer och `109` funktioner):

**Algebraiska datatyper och poster (`type`) i `crypto`:**

```ridgun
type CT16    = ct0: A, ct1: A, ct2: A, ct3: A, ct4: A, ct5: A, ct6: A, ct7: A, ct8: A, ct9: A, ct10: A, ct11: A, ct12: A, ct13: A, ct14: A, ct15: A
type CPbkCtx = cptbl: CT16, cpipad: String, cpopad: String
type CA2Ctx  = cr_pass: Int, cs_slice: Int, cl_lane: Int, cp_lanes: Int, cq_cols: Int, cseg_len: Int, ct_iters: Int
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: norm byte mod Int` | `Int` |
| `2` | `fn :: norm byte Int` | `Int` |
| `3` | `fn :: byte str norm Int` | `String` |
| `4` | `fn :: byte str Int` | `String` |
| `5` | `fn :: bytes from list [Int]` | `String` |
| `6` | `fn :: bytes to list loop String Int Int` | `[Int]` |
| `7` | `fn :: bytes to list String` | `[Int]` |
| `8` | `fn :: u32 mod Int` | `Int` |
| `9` | `fn :: u32 val Int` | `Int` |
| `10` | `fn :: byte band Int Int` | `Int` |
| `11` | `fn :: byte bor Int Int` | `Int` |
| `12` | `fn :: byte bxor Int Int` | `Int` |
| `13` | `fn :: band Int Int` | `Int` |
| `14` | `fn :: bor Int Int` | `Int` |
| `15` | `fn :: c u32 bxor Int Int` | `Int` |
| `16` | `fn :: bxor Int Int` | `Int` |
| `17` | `fn :: shl Int Int` | `Int` |
| `18` | `fn :: shr Int Int` | `Int` |
| `19` | `fn :: rotl32 Int Int` | `Int` |
| `20` | `fn :: hextable Int` | `String` |
| `21` | `fn :: crypto byte to hex Int` | `String` |
| `22` | `fn :: bytes to hex str String` | `String` |
| `23` | `fn :: bytes list to hex [Int]` | `String` |
| `24` | `fn :: crypto hex val Int` | `Int` |
| `25` | `fn :: hex str to bytes loop String Int Int` | `[Int]` |
| `26` | `fn :: hex to byte str String` | `String` |
| `27` | `fn :: c list len [Int]` | `Int` |
| `28` | `fn :: c nth int [Int] Int` | `Int` |
| `29` | `fn :: c take ints [Int] Int` | `[Int]` |
| `30` | `fn :: c drop ints [Int] Int` | `[Int]` |
| `31` | `fn :: byte slice String Int Int` | `String` |
| `32` | `fn :: sha256 hex String` | `String` |
| `33` | `fn :: sha256 bytes String` | `String` |
| `34` | `fn :: pad zeroes Int` | `[Int]` |
| `35` | `fn :: bitxor key pad [Int] Int` | `[Int]` |
| `36` | `fn :: raw hmac key bytes String` | `[Int]` |
| `37` | `fn :: normalize hmac key String` | `[Int]` |
| `38` | `fn :: hmac sha256 String String` | `String` |
| `39` | `fn :: ct diff str String String Int Int Int` | `Int` |
| `40` | `fn :: ct equal String String` | `Bool` |
| `41` | `fn :: bitxor byte lists [Int] [Int]` | `[Int]` |
| `42` | `fn :: bitxor byte strings String String` | `String` |
| `43` | `fn :: be32 bytes Int` | `String` |
| `44` | `fn :: c get16 CT16 Int` | `A` |
| `45` | `fn :: c set16 CT16 Int A` | `CT16` |
| `46` | `fn :: c build b16 Int` | `CT16` |
| `47` | `fn :: c build b256` | `CT16` |
| `48` | `fn :: c get b256 CT16 Int Int` | `String` |
| `49` | `fn :: c hex nib Int` | `Int` |
| `50` | `fn :: c hex pair CT16 String Int` | `String` |
| `51` | `fn :: c hex2raw4 CT16 String Int` | `String` |
| `52` | `fn :: c hex2raw32 CT16 String` | `String` |
| `53` | `fn :: c hex8 word String Int` | `U64` |
| `54` | `fn :: c bxor acc8 Tensor[U64 * 8] String` | `Tensor[U64 * 8]` |
| `55` | `fn :: c word32 to raw4 CT16 U64` | `String` |
| `56` | `fn :: c acc8 to raw CT16 Tensor[U64 * 8]` | `String` |
| `57` | `fn :: c list to raw CT16 [Int]` | `String` |
| `58` | `fn :: pbkdf2 iter loop CPbkCtx String Tensor[U64 * 8] Int` | `Tensor[U64 * 8]` |
| `59` | `fn :: pbkdf2 block CPbkCtx String Int Int` | `String` |
| `60` | `fn :: pbkdf2 blocks loop CPbkCtx String Int Int Int String` | `String` |
| `61` | `fn :: pbkdf2 hmac sha256 String String Int Int` | `String` |
| `62` | `fn :: f blamka U64 U64` | `U64` |
| `63` | `fn :: blamka g U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `64` | `fn :: blamka p16 Tensor[U64 * 16]` | `()` |
| `65` | `fn :: ca2 blamka col pair Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `66` | `fn :: ca2 blamka cols loop Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `67` | `fn :: compress block Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `68` | `fn :: ca2 take ints [Int] Int` | `[Int]` |
| `69` | `fn :: ca2 drop ints [Int] Int` | `[Int]` |
| `70` | `fn :: ca2 pad zeroes Int` | `[Int]` |
| `71` | `fn :: ca2 u64 lh Int Int` | `U64` |
| `72` | `fn :: ca2 u32 to le4 Int` | `[Int]` |
| `73` | `fn :: ca2 bytes to u32 le [Int] Int` | `Int` |
| `74` | `fn :: ca2 zero w16` | `Tensor[U64 * 16]` |
| `75` | `fn :: ca2 zero blk8` | `Tensor[U64 * 8 * 16]` |
| `76` | `fn :: ca2 b2b iv w16` | `Tensor[U64 * 16]` |
| `77` | `fn :: ca2 b2b g4 U64 U64 U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `78` | `fn :: ca2 b2b sigma Int` | `[Int]` |
| `79` | `fn :: ca2 b2b round Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `80` | `fn :: ca2 b2b rounds Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `81` | `fn :: ca2 b2b compress Tensor[U64 * 16] Tensor[U64 * 16] Int Bool` | `Tensor[U64 * 16]` |
| `82` | `fn :: ca2 bytes to u64 [Int] Int` | `U64` |
| `83` | `fn :: ca2 bytes to w16 [Int] Int` | `Tensor[U64 * 16]` |
| `84` | `fn :: ca2 u64 to le8 U64` | `[Int]` |
| `85` | `fn :: ca2 h8 to bytes Tensor[U64 * 16]` | `[Int]` |
| `86` | `fn :: ca2 b2b loop Tensor[U64 * 16] [Int] Int` | `Tensor[U64 * 16]` |
| `87` | `fn :: ca2 blake2b [Int] Int` | `[Int]` |
| `88` | `fn :: ca2 b2b long loop [Int] Int Int Int` | `[Int]` |
| `89` | `fn :: ca2 blake2b long [Int] Int` | `[Int]` |
| `90` | `fn :: ca2 bitxor blk8 Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `91` | `fn :: ca2 get blk8 Tensor[U64 * 8 * 16] Int` | `U64` |
| `92` | `fn :: ca2 bytes to blk8 row Tensor[U64 * 8 * 16] [Int] Int Int` | `Tensor[U64 * 8 * 16]` |
| `93` | `fn :: ca2 bytes to blk8 loop Tensor[U64 * 8 * 16] [Int] Int` | `Tensor[U64 * 8 * 16]` |
| `94` | `fn :: ca2 bytes to blk8 [Int]` | `Tensor[U64 * 8 * 16]` |
| `95` | `fn :: ca2 blk8 row to bytes Tensor[U64 * 8 * 16] Int Int` | `[Int]` |
| `96` | `fn :: ca2 blk8 to bytes loop Tensor[U64 * 8 * 16] Int` | `[Int]` |
| `97` | `fn :: ca2 blk8 to bytes Tensor[U64 * 8 * 16]` | `[Int]` |
| `98` | `fn :: ca2 zero mem` | `CT16` |
| `99` | `fn :: ca2 nth blk CT16 Int` | `Tensor[U64 * 8 * 16]` |
| `100` | `fn :: ca2 set blk CT16 Int Tensor[U64 * 8 * 16]` | `CT16` |
| `101` | `fn :: ca2 init all lanes loop CT16 [Int] Int Int Int` | `CT16` |
| `102` | `fn :: ca2 init all lanes [Int] Int Int Int` | `CT16` |
| `103` | `fn :: ca2 make addr blk CA2Ctx Int` | `Tensor[U64 * 8 * 16]` |
| `104` | `fn :: ca2 calc w size p0 CA2Ctx Int Bool` | `Int` |
| `105` | `fn :: ca2 calc w size pn CA2Ctx Int Bool` | `Int` |
| `106` | `fn :: ca2 calc w size CA2Ctx Int Bool` | `Int` |
| `107` | `fn :: ca2 step addr Bool CA2Ctx Int Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `108` | `fn :: ca2 step jpair Bool Tensor[U64 * 8 * 16] Int CT16 Int` | `U64` |
| `109` | `fn :: ca2 ref lane Int Int Int Int Int` | `Int` |
| `110` | `fn :: ca2 st pos Int Int Int` | `Int` |
| `111` | `fn :: ca2 fin blk Int Tensor[U64 * 8 * 16] CT16 Int` | `Tensor[U64 * 8 * 16]` |
| `112` | `fn :: ca2 fill segment CT16 CA2Ctx Int Tensor[U64 * 8 * 16]` | `CT16` |
| `113` | `fn :: ca2 start j CA2Ctx` | `Int` |
| `114` | `fn :: ca2 run lanes CT16 CA2Ctx Int` | `CT16` |
| `115` | `fn :: ca2 run slices CT16 CA2Ctx Int` | `CT16` |
| `116` | `fn :: ca2 run passes CT16 CA2Ctx Int` | `CT16` |
| `117` | `fn :: ca2 bitxor final lanes CT16 Int Int Int Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `118` | `fn :: ca2 derive raw tag [Int] [Int] Int Int Int Int` | `[Int]` |
| `119` | `fn :: ca2 b64 alphabet` | `String` |
| `120` | `fn :: ca2 b64 char Int` | `String` |
| `121` | `fn :: ca2 b64 encode [Int]` | `String` |
| `122` | `fn :: ca2 b64 char val Int` | `Int` |
| `123` | `fn :: ca2 valid b64 chars String Int Int` | `Bool` |
| `124` | `fn :: ca2 is valid b64 String` | `Bool` |
| `125` | `fn :: ca2 b64 decode rem String Int Int Int` | `[Int]` |
| `126` | `fn :: ca2 b64 decode loop String Int Int` | `[Int]` |
| `127` | `fn :: ca2 b64 decode String` | `[Int]` |
| `128` | `fn :: ca2 split str String Int Int Int Int` | `[String]` |
| `129` | `fn :: ca2 nth str [String] Int` | `String` |
| `130` | `fn :: ca2 str list len [String]` | `Int` |
| `131` | `fn :: ca2 is digits String Int Int` | `Bool` |
| `132` | `fn :: ca2 parse kv String String` | `Int` |
| `133` | `fn :: ca2 verify decoded String [Int] [Int] Int Int Int Int` | `Bool` |
| `134` | `fn :: ca2 verify kvs String [String] String String` | `Bool` |
| `135` | `fn :: ca2 verify parts String [String]` | `Bool` |
| `136` | `fn :: ca2 hash checked String [Int] Int Int Int` | `String` |
| `137` | `fn :: argon2id hash String String Int Int Int` | `String` |
| `138` | `fn :: argon2id hash phc String String Int Int Int` | `String` |
| `139` | `fn :: argon2id verify String String` | `Bool` |
| `140` | `fn :: le32 at [Int] Int` | `Int` |
| `141` | `fn :: u32 to le4 Int` | `[Int]` |
| `142` | `fn :: chacha qr Int Int Int Int` | `Int Int Int Int` |
| `143` | `fn :: chacha double round Tensor[Int * 16]` | `Tensor[Int * 16]` |
| `144` | `fn :: chacha rounds loop Tensor[Int * 16] Int` | `Tensor[Int * 16]` |
| `145` | `fn :: words16 tensor to bytes Tensor[Int * 16] Tensor[Int * 16] Int` | `[Int]` |
| `146` | `fn :: chacha20 init st [Int] [Int] Int` | `Tensor[Int * 16]` |
| `147` | `fn :: chacha20 block [Int] [Int] Int` | `[Int]` |
| `148` | `fn :: chacha20 bitxor loop [Int] [Int] Int [Int]` | `[Int]` |
| `149` | `fn :: poly1305 clamp r [Int]` | `[Int]` |
| `150` | `fn :: poly1305 r limbs [Int]` | `[Int]` |
| `151` | `fn :: poly1305 block limbs [Int]` | `[Int]` |
| `152` | `fn :: poly1305 step [Int] [Int] [Int]` | `[Int]` |
| `153` | `fn :: poly1305 blocks loop [Int] [Int] [Int]` | `[Int]` |
| `154` | `fn :: select reduced limbs Int [Int] [Int]` | `[Int]` |
| `155` | `fn :: poly1305 finalize [Int] [Int]` | `[Int]` |
| `156` | `fn :: pad16 zeroes Int` | `[Int]` |
| `157` | `fn :: u64 le8 Int` | `[Int]` |
| `158` | `fn :: poly1305 aead mac [Int] [Int] [Int]` | `[Int]` |
| `159` | `fn :: aead seal String String String String` | `String` |
| `160` | `fn :: decrypt verified aead Bool [Int] [Int] [Int]` | `Int String` |
| `161` | `fn :: aead open String String String String` | `Int String` |
| `162` | `fn :: sha512 bytes String` | `String` |
| `163` | `fn :: sha512 hex String` | `String` |
| `164` | `fn :: ed25519 public key String` | `String` |
| `165` | `fn :: ed25519 sign String String` | `String` |
| `166` | `fn :: ed25519 verify String String String` | `Bool` |
| `167` | `fn :: minisign encode pubkey String String` | `String` |
| `168` | `fn :: minisign decode pubkey String` | `String String` |
| `169` | `fn :: minisign sign String String String String String` | `String` |
| `170` | `fn :: minisign trusted comment String` | `String` |
| `171` | `fn :: minisign verify String String String` | `Bool` |

---

## 24.3. Djupdykning i `crypto`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `crypto` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test crypto.rg`.

### 24.3.1. Exempel 1: Huvudflöde i tabellform med `crypto`

Lägg märke till hur `=`-tecknen och transformationsstegen med `crypto` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import crypto

fn :: cifrar mensaje sesion String String => Int String
      cifrar mensaje sesion secreto texto =
        secreto sha256 raw -> key32
        "0123456789ab" -> nonce12
        "canal-autenticado" -> aad
        aead seal key32 nonce12 aad texto -> sellado
        aead open key32 nonce12 aad sellado
```

### 24.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `crypto` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook String String String => Bool
      verificar firma webhook clave cuerpo firma_hex =
        hmac sha256 clave cuerpo -> esperada
        ct equal esperada firma_hex
```

### 24.3.3. Exempel 3: Rå bytehantering `0..255` (`byte str`, `bytes from list`, `bytes to list`) och 32-bitars bitvisa operationer (`band`, `bor`, `bxor`, `shl`, `shr`)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test rgf019 bytes and bitops => ()
      test rgf019 bytes and bitops =
        -- 1. Raw byte str lengths, wraparound normalization, and full 0..255 round-trip
        assert int equals (str len (byte str 0)) 1 "len byte_str 0"
        assert int equals (str len (byte str 127)) 1 "len byte_str 127"
        assert int equals (str len (byte str 128)) 1 "len byte_str 128"
        assert int equals (str len (byte str 255)) 1 "len byte_str 255"
        assert str eq (byte str (0 - 1)) (byte str 255) "byte_str -1 wraps to 255"
        assert str eq (byte str 256) (byte str 0) "byte_str 256 wraps to 0"
        b5   = bytes from list [0, 1, 127, 128, 255]
        assert int equals (str len b5) 5 "len b5 == 5"
        rt   = bytes to list b5
        assert int equals (c nth int rt 0) 0 "rt 0"
        assert int equals (c nth int rt 1) 1 "rt 1"
        assert int equals (c nth int rt 2) 127 "rt 2"
        assert int equals (c nth int rt 3) 128 "rt 3"
        assert int equals (c nth int rt 4) 255 "rt 4"
        b256 = bytes from list (range bytes 0 255)
        assert int equals (str len b256) 256 "len b256 == 256"
        r256 = bytes to list b256
        assert int equals (c list len r256) 256 "r256 list len == 256"
        assert int equals (c nth int r256 0) 0 "r256[0] == 0"
        assert int equals (c nth int r256 128) 128 "r256[128] == 128"
        assert int equals (c nth int r256 255) 255 "r256[255] == 255"

        -- 2. RGF-019 32-bit unsigned bitwise operations and boundary shifts
        assert int equals (band 4294967295 255) 255 "band"
        assert int equals (band 305419896 0) 0 "band with 0"
        assert int equals (bor 240 15) 255 "bor"
        assert int equals (bor 305419896 0) 305419896 "bor with 0"
        assert int equals (bxor 305419896 4294967295) 3989547399 "bxor"
        assert int equals (bxor 305419896 305419896) 0 "bxor self == 0"
        assert int equals (shl 1 0) 1 "shl 0"
        assert int equals (shl 1 (0 - 1)) 0 "shl negative shift"
        assert int equals (shl 1 31) 2147483648 "shl 31"
        assert int equals (shl 1 32) 0 "shl 32"
        assert int equals (shr 2147483648 0) 2147483648 "shr 0"
        assert int equals (shr 2147483648 (0 - 1)) 0 "shr negative shift"
        assert int equals (shr 2147483648 31) 1 "shr 31"
        assert int equals (shr 2147483648 32) 0 "shr 32"
        ()
```

### 24.3.4. Exempel 4: Officiella testvektorer för SHA-256 (FIPS 180-4), HMAC-SHA-256 (RFC 4231), konstanttidslikhet (`ct equal`) och PBKDF2-HMAC-SHA-256 (RFC 6070)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test sha256 hmac and pbkdf2 => ()
      test sha256 hmac and pbkdf2 =
        -- 1. SHA-256 (empty string "" and "abc" -> FIPS 180-4 vectors)
        h_emp = sha256 hex ""
        assert str eq h_emp "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "sha256_hex empty"
        h_hex = sha256 hex "abc"
        assert str eq h_hex "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "sha256_hex abc"
        h_raw = sha256 bytes "abc"
        assert eq (str len h_raw) 32
        assert str eq (bytes to hex str h_raw) h_hex "sha256_bytes matches sha256_hex"

        -- 2. HMAC-SHA-256 (RFC 4231 Test Case 2 and >64-byte key reduction)
        mac   = hmac sha256 "Jefe" "what do ya want for nothing?"
        assert eq (str len mac) 32
        assert str eq (bytes to hex str mac) "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843" "RFC 4231 Test Case 2"
        long_k = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef_extra_key_bytes"
        mac_lk = hmac sha256 long_k "message"
        assert eq (str len mac_lk) 32
        assert true (ct equal mac_lk (hmac sha256 (sha256 bytes long_k) "message")) "HMAC >64B key hashed to 32B"

        -- 3. Constant-time comparison (`ct equal`)
        assert true (ct equal "" "") "ct_equal empty strings"
        assert true (ct equal mac mac) "ct_equal identical"
        assert false (ct equal mac (sha256 bytes "abc")) "ct_equal different 32B"
        assert false (ct equal "short" "longer") "ct_equal different lengths"

        -- 4. PBKDF2-HMAC-SHA-256 (RFC 6070 c=1, c=2, multi-block dk_len=64, sub-block dk_len=16, invalid args)
        dk1   = pbkdf2 hmac sha256 "password" "salt" 1 32
        assert eq (str len dk1) 32
        assert str eq (bytes to hex str dk1) "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b" "RFC 6070 PBKDF2 c=1"
        dk2   = pbkdf2 hmac sha256 "password" "salt" 2 32
        assert str eq (bytes to hex str dk2) "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43" "RFC 6070 PBKDF2 c=2"
        dk16  = pbkdf2 hmac sha256 "password" "salt" 1 16
        assert eq (str len dk16) 16
        assert str eq (bytes to hex str dk16) "120fb6cffcf8b32c43e7225256c4f837" "PBKDF2 16-byte prefix"
        dk64  = pbkdf2 hmac sha256 "password" "salt" 1 64
        assert eq (str len dk64) 64
        assert str eq (byte slice dk64 0 32) dk1 "PBKDF2 64-byte block 1 matches dk1"
        assert str eq (pbkdf2 hmac sha256 "password" "salt" 0 32) "" "PBKDF2 iterations=0 rejected"
        assert str eq (pbkdf2 hmac sha256 "password" "salt" 1 0) "" "PBKDF2 dk_len=0 rejected"
        ()
```

### 24.3.5. Exempel 5: 5-arguments Argon2id-lösenordshashning (`argon2id hash`, `argon2id verify`) och minneshård verifiering (RFC 9106)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test argon2id five arg and perf => ()
      test argon2id five arg and perf =
        phc = argon2id hash "correct horse battery staple" "0123456789abcdef" 64 2 1
        assert true (str starts with phc "$argon2id$v=19$m=64,t=2,p=1$") "PHC header format"
        assert true (argon2id verify "correct horse battery staple" phc) "argon2id_verify matching (pwd, phc)"
        assert false (argon2id verify "wrong password" phc) "argon2id_verify wrong password"
        assert false (argon2id verify "correct horse battery staple" "$argon2id$v=19$m=64,t=2,p=1$bad$bad") "argon2id_verify bad PHC"

        -- Negative parameter guards for 5-arg argon2id hash
        assert str eq (argon2id hash "password" "short" 64 2 1) "" "salt < 8 bytes rejected"
        assert str eq (argon2id hash "password" "0123456789abcdef" 4 2 1) "" "m_cost < 8*p rejected"
        assert str eq (argon2id hash "password" "0123456789abcdef" 64 0 1) "" "t_cost < 1 rejected"
        assert str eq (argon2id hash "password" "0123456789abcdef" 64 2 0) "" "p_cost < 1 rejected"

        -- RG-050 / RG-051: Verify 100% in-process pure-Ridgun Argon2id and PBKDF2-HMAC-SHA256
        -- (OpenSSL 3.5 / RFC 9106 vectors + 4096-iteration PBKDF2 vector)
        phc_s       = argon2id hash "correct horse" "saltsaltsaltsalt" 64 2 1
        argon_exact = phc_s == "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$5jdMIzWoFbzSOl6k3wai9uU3f8LD+HmGXQgo1uhHQPI"
        ok_s        = argon2id verify "correct horse" phc_s
        bad_s       = argon2id verify "wrong horse" phc_s
        bad_empty   = argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$"
        phc_ok      = str starts with phc_s "$argon2id$v=19$m=64,t=2,p=1$"
        pb4k        = bytes to hex str (pbkdf2 hmac sha256 "correct horse battery staple" "0123456789abcdef" 4096 32)
        assert true ok_s "Solstice RGF-015 argon_ok"
        assert false bad_s "Solstice RGF-015 argon_bad"
        assert false bad_empty "RG-051 reject PHC with empty tag"
        assert true phc_ok "Solstice RGF-015 phc prefix"
        assert true argon_exact "Solstice RGF-015 exact OpenSSL 3.5 / libsodium PHC"
        assert str eq pb4k "b87f4b27148d3b05ad7985e3df997f0d9afa6e768e6384555bab71ba10f0c1a5" "Solstice RGF-015 PBKDF2 4096"
        ()
```

### 24.3.6. Exempel 6: ChaCha20-strömchiffer, Poly1305-autentiserare och RFC 8439 ChaCha20-Poly1305 AEAD-försegling och öppning

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test rfc8439 chacha20 poly1305 aead => ()
      test rfc8439 chacha20 poly1305 aead =
        key   = bytes from list (range bytes 128 159)
        nonce = bytes from list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        aad   = bytes from list [80, 81, 82, 83, 192, 193, 194, 195, 196, 197, 198, 199]
        pt    = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

        sealed = aead seal key nonce aad pt
        assert eq (str len sealed) ((str len pt) + 16)

        -- Verify first 16 ciphertext bytes and 16-byte Poly1305 tag match RFC 8439 §2.8.2 bit-for-bit
        ct_prefix_hex = bytes to hex str (byte slice sealed 0 16)
        tag_hex       = bytes to hex str (byte slice sealed 114 130)
        assert str eq ct_prefix_hex "d31a8d34648e60db7b86afbc53ef7ec2" "RFC 8439 §2.8.2 ciphertext prefix"
        assert str eq tag_hex "1ae10b594f09e26a7e902ecbd0600691" "RFC 8439 §2.8.2 Poly1305 tag"

        -- Verify aead open succeeds with (0, pt)
        res_ok   = aead open key nonce aad sealed
        assert eq (aead rc res_ok) 0
        assert str eq (aead pt res_ok) pt "aead_open decrypted plaintext"

        -- Verify empty plaintext and empty AAD round-trip
        sealed_empty = aead seal key nonce "" ""
        assert eq (str len sealed_empty) 16
        res_empty    = aead open key nonce "" sealed_empty
        assert eq (aead rc res_empty) 0
        assert str eq (aead pt res_empty) "" "aead_open empty plaintext"

        -- Verify tamper detection (-12 AUTH_FAILED) on modified AAD, modified nonce, modified ciphertext, or modified tag
        res_aad  = aead open key nonce "tampered-aad" sealed
        assert eq (aead rc res_aad) (0 - 12)
        assert str eq (aead pt res_aad) "" "tampered AAD returns empty plaintext"

        bad_nonce = bytes from list [8, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        res_nonce = aead open key bad_nonce aad sealed
        assert eq (aead rc res_nonce) (0 - 12)
        assert str eq (aead pt res_nonce) "" "tampered nonce returns empty plaintext"

        bad_ct   = (byte str 0) + (byte slice sealed 1 130)
        res_ct   = aead open key nonce aad bad_ct
        assert eq (aead rc res_ct) (0 - 12)
        assert str eq (aead pt res_ct) "" "tampered ciphertext byte returns empty plaintext"

        bad_seal = (byte slice sealed 0 129) + (byte str 0)
        res_tag  = aead open key nonce aad bad_seal
        assert eq (aead rc res_tag) (0 - 12)
        assert str eq (aead pt res_tag) "" "tampered tag returns empty plaintext"

        -- Verify invalid key/nonce/ciphertext length returns (-7, "") or ""
        assert str eq (aead seal "short-key" nonce aad pt) "" "aead_seal invalid key length"
        assert str eq (aead seal key "short-nonce" aad pt) "" "aead_seal invalid nonce length"
        res_inv  = aead open "short-key" nonce aad sealed
        assert eq (aead rc res_inv) (0 - 7)
        res_ninv = aead open key "short-nonce" aad sealed
        assert eq (aead rc res_ninv) (0 - 7)
        res_tinv = aead open key nonce aad "short-tag"
        assert eq (aead rc res_tinv) (0 - 7)
        ()
```

### 24.3.7. Exempel 7: FIPS 180-4 SHA-512 (`sha512 bytes`, `sha512 hex`), RFC 8032 §5.1 Ed25519-signaturer (`ed25519 public key`, `ed25519 sign`, `ed25519 verify`) och Minisign-format (`minisign sign`, `minisign verify`)

I detta praktiska exempel verifierar vi officiella FIPS 180-4 SHA-512-testvektorer, konstanttidssignering med Ed25519 (med strikt avvisning av $S \ge L$-formbarhet och ogiltiga kurvpunkter) samt signering/verifiering av `.minisig`-releasemanifest:

```ridgun
import crypto
import test

fn :: verificar sha512 ed25519 y minisign => ()
      verificar sha512 ed25519 y minisign =
        "abc" sha512 hex -> h_abc
        assert str eq h_abc "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f" "SHA-512 abc"
        "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60" hex to byte str -> sk
        sk ed25519 public key -> pk
        ed25519 sign sk "" -> sig
        assert true (ed25519 verify pk "" sig) "RFC 8032 Test 1"
        assert false (ed25519 verify pk "manipulerad" sig) "Manipulerat meddelande avvisat"
        minisign encode pubkey "01234567" pk -> pub_txt
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ridgun-linux-x86_64.tar.gz\n" -> sums
        minisign sign sk "01234567" sums "ridgun release key" "timestamp:1761667200\tfile:SHA256SUMS" -> msig
        assert true (minisign verify pub_txt sums msig) "Giltig Minisign"
        assert str eq (minisign trusted comment msig) "timestamp:1761667200\tfile:SHA256SUMS" "Autentiserad kommentar" -> ()
```

---

## 24.4. Under huven: hur `crypto` är byggd i ren Ridgun (`src/main/ridgun/lib/crypto.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/crypto.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 24.4.1. Intern implementation: RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`)

Se hur `crypto.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: crypto

fn :: norm byte mod Int => Int
      norm byte mod m   =
        | m < 0     = m + 256
        | otherwise = m

fn :: norm byte Int => Int
      norm byte b   =  norm byte mod (b % 256)

fn :: byte str norm Int => String
      byte str norm ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | ub == 0 = str slice (sha256 raw "00679") 0 1
        | otherwise =
          idx = (ub - 128) * 5
          lut = "0056400101002080010000179000010024100109003430040100361007870009100353001870030400471000870020200071002360012501171004140236900275001810016001398004440080400017005250027000314001400024700004006350015700183005940027600207007720028400601003400038000839006850084900617003060113500277000320006900483000580019200151008700008500193000100057000070002880002600326006460038800018009190028900103006000043900073011700038900628007210077300074004740006000041001410019900066003680001900383001730005700558000670024500065002030031900000008250001100128001360034900030003750039600228002380008400618005900031800062001770087900076002570009600034002200001600161"
          str slice (sha256 raw (str slice lut idx (idx + 5))) 0 1

fn :: byte str Int => String
      byte str n   =
        byte str norm (norm byte n)

fn :: c sb append3 String String => String String String String
      c sb append3 n2 c3 =
        | (str len n2) < 65536 = ("", "", n2, c3)
        | otherwise            = ("", "", "", c3 + n2)

fn :: c sb append2 String String String => String String String String
      c sb append2 n1 c2 c3 =
        | (str len n1) < 8192 = ("", n1, c2, c3)
        | otherwise           = c sb append3 (c2 + n1) c3

fn :: c sb append1 String String String String => String String String String
      c sb append1 n0 c1 c2 c3 =
        | (str len n0) < 512 = (n0, c1, c2, c3)
        | otherwise          = c sb append2 (c1 + n0) c2 c3

fn :: c sb append String String String String String => String String String String
      c sb append chunk c0 c1 c2 c3 =
        c sb append1 (c0 + chunk) c1 c2 c3

fn :: c sb finish String String String String => String
      c sb finish c0 c1 c2 c3 =  ((c3 + c2) + c1) + c0

fn :: c lb append2 [Int] [Int] Int => [Int] [Int] [Int] Int
      c lb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: c lb append1 [Int] [Int] [Int] Int => [Int] [Int] [Int] Int
      c lb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = c lb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: c lb append Int [Int] [Int] [Int] Int => [Int] [Int] [Int] Int
      c lb append item l0 l1 l2 cnt =
        c lb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: c lb finish [Int] [Int] [Int] => [Int]
      c lb finish l0 l1 l2 =  l2 :: (l1 :: l0)

fn :: bytes from list loop CT16 [Int] String String String String => String
      bytes from list loop _   []       c0 c1 c2 c3 =  c sb finish c0 c1 c2 c3
      bytes from list loop tbl (b:rest) c0 c1 c2 c3 =
        ub = norm byte b
        ch = c get b256 tbl (ub / 16) (ub % 16)
        n0, n1, n2, n3 = c sb append ch c0 c1 c2 c3
        bytes from list loop tbl rest n0 n1 n2 n3

fn :: bytes from list [Int]    => String
      bytes from list []       =  ""
      bytes from list bs       =  bytes from list loop (c build b256) bs "" "" "" ""

fn :: bytes to list loop String Int Int [Int] [Int] [Int] Int => [Int]
      bytes to list loop s idx slen l0 l1 l2 cnt =
        | idx >= slen = c lb finish l0 l1 l2
        | otherwise   =
          n0, n1, n2, ncnt = c lb append (norm byte (str char at s idx)) l0 l1 l2 cnt
          bytes to list loop s (idx + 1) slen n0 n1 n2 ncnt

fn :: bytes to list String => [Int]
      bytes to list s      =
        bytes to list loop s 0 (str len s) [] [] [] 0
```

### 24.4.2. Intern implementation: Hex & List Utilities

Se hur `crypto.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: hextable Int => String
      hextable _   =  "0123456789abcdef"

fn :: crypto byte to hex Int => String
      crypto byte to hex b   =
        ub = norm byte b
        hi = (ub / 16) % 16
        lo = ub % 16
        (str slice (hextable 0) hi (hi + 1)) + (str slice (hextable 0) lo (lo + 1))

fn :: bytes list to hex loop [Int] String String String String => String
      bytes list to hex loop []       c0 c1 c2 c3 = c sb finish c0 c1 c2 c3
      bytes list to hex loop (b:rest) c0 c1 c2 c3 =
        n0, n1, n2, n3 = c sb append (crypto byte to hex b) c0 c1 c2 c3
        bytes list to hex loop rest n0 n1 n2 n3

fn :: bytes list to hex [Int] => String
      bytes list to hex bs    =  bytes list to hex loop bs "" "" "" ""

fn :: bytes to hex str String => String
      bytes to hex str raw    =
        bytes list to hex (bytes to list raw)

fn :: crypto hex val Int => Int
      crypto hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 97 and c <= 102 = (c - 97) + 10
        | c >= 65 and c <= 70  = (c - 65) + 10
        | otherwise            = 0

fn :: hex str to bytes loop String Int Int [Int] [Int] [Int] Int => [Int]
      hex str to bytes loop h idx hlen l0 l1 l2 cnt =
        | (idx + 1) >= hlen = c lb finish l0 l1 l2
        | otherwise         =
          hi = crypto hex val (str char at h idx)
          lo = crypto hex val (str char at h (idx + 1))
          n0, n1, n2, ncnt = c lb append ((hi * 16) + lo) l0 l1 l2 cnt
          hex str to bytes loop h (idx + 2) hlen n0 n1 n2 ncnt

fn :: hex to byte str String => String
      hex to byte str h      =
        bytes from list (hex str to bytes loop h 0 (str len h) [] [] [] 0)

fn :: c list len loop [Int] Int => Int
      c list len loop []       acc = acc
      c list len loop (_:rest) acc = c list len loop rest (acc + 1)

fn :: c list len [Int] => Int
      c list len xs    =  c list len loop xs 0

fn :: c nth int [Int]    Int => Int
      c nth int []       _   =  0
      c nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth int rest (idx - 1)

fn :: c take ints loop [Int] Int [Int] => [Int]
      c take ints loop []       _ acc = acc
      c take ints loop (x:rest) n acc =
        | n <= 0    = acc
        | otherwise = c take ints loop rest (n - 1) (acc :: [x])

fn :: c take ints [Int] Int => [Int]
      c take ints xs    n   =  c take ints loop xs n []

fn :: c drop ints [Int]    Int => [Int]
      c drop ints []       _   =  []
      c drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = c drop ints rest (n - 1)

fn :: c byte slice loop CT16 String Int Int String String String String => String
      c byte slice loop tbl s idx end_idx c0 c1 c2 c3 =
        | idx >= end_idx = c sb finish c0 c1 c2 c3
        | otherwise      =
          ub = norm byte (str char at s idx)
          n0, n1, n2, n3 = c sb append (c get b256 tbl (ub / 16) (ub % 16)) c0 c1 c2 c3
          c byte slice loop tbl s (idx + 1) end_idx n0 n1 n2 n3

fn :: byte slice String Int Int => String
      byte slice s start end_idx =
        slen = str len s
        st   =
          | start < 0 = 0
          | start > slen = slen
          | otherwise = start
        en   =
          | end_idx < st = st
          | end_idx > slen = slen
          | otherwise = end_idx
        c byte slice loop (c build b256) s st en "" "" "" ""
```

### 24.4.3. Intern implementation: RGF-015 Pure-Ridgun RFC 9106 Argon2id (`argon2id_hash`, `argon2id_verify`)

Se hur `crypto.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ca2 take ints [Int]    Int => [Int]
      ca2 take ints []       _   =  []
      ca2 take ints (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (ca2 take ints rest (n - 1))

fn :: ca2 drop ints [Int]    Int => [Int]
      ca2 drop ints []       _   =  []
      ca2 drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = ca2 drop ints rest (n - 1)

fn :: ca2 pad zeroes Int => [Int]
      ca2 pad zeroes n   =
        | n <= 0    = []
        | otherwise = [0] :: (ca2 pad zeroes (n - 1))

fn :: ca2 u64 lh Int Int => U64
      ca2 u64 lh lo  hi  =
        ((hi and 0xFFFFFFFF) shl 32) or (lo and 0xFFFFFFFF)

fn :: ca2 u32 to le4 Int => [Int]
      ca2 u32 to le4 w   =
        uw = u32 val w
        [uw % 256, (uw / 256) % 256, (uw / 65536) % 256, (uw / 16777216) % 256]

fn :: ca2 bytes to u32 le [Int] Int => Int
      ca2 bytes to u32 le bs off =
        (c nth int bs off) + ((c nth int bs (off + 1)) * 256) + ((c nth int bs (off + 2)) * 65536) + ((c nth int bs (off + 3)) * 16777216)

fn :: ca2 zero w16 => Tensor[U64 * 16]
      ca2 zero w16 =
        Tensor[U64 * 16]

fn :: ca2 zero blk8 => Tensor[U64 * 8 * 16]
      ca2 zero blk8 =
        Tensor[U64 * 8 * 16]

fn :: ca2 b2b iv w16 => Tensor[U64 * 16]
      ca2 b2b iv w16 =
        iv = Tensor[U64 * 16]
        iv_(0) = ca2 u64 lh 4089235720 1779033703
        iv_(1) = ca2 u64 lh 2227873595 3144134277
        iv_(2) = ca2 u64 lh 4271175723 1013904242
        iv_(3) = ca2 u64 lh 1595750129 2773480762
        iv_(4) = ca2 u64 lh 2917565137 1359893119
        iv_(5) = ca2 u64 lh 725511199  2600822924
        iv_(6) = ca2 u64 lh 4215389547 528734635
        iv_(7) = ca2 u64 lh 327033209  1541459225
        iv
```

### 24.4.4. Intern implementation: RFC 8439 Poly1305 One-Time Authenticator (5 x 26-bit limbs)

Se hur `crypto.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: poly1305 clamp r [Int] => [Int]
      poly1305 clamp r otk   =
        [c nth int otk 0, c nth int otk 1, c nth int otk 2, byte band (c nth int otk 3) 15, byte band (c nth int otk 4) 252, c nth int otk 5, c nth int otk 6, byte band (c nth int otk 7) 15, byte band (c nth int otk 8) 252, c nth int otk 9, c nth int otk 10, byte band (c nth int otk 11) 15, byte band (c nth int otk 12) 252, c nth int otk 13, c nth int otk 14, byte band (c nth int otk 15) 15]

fn :: poly1305 r limbs [Int] => [Int]
      poly1305 r limbs r_bs  =
        t0 = le32 at r_bs 0
        t1 = le32 at r_bs 4
        t2 = le32 at r_bs 8
        t3 = le32 at r_bs 12
        r0 = t0 % 67108864
        r1 = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        r2 = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        r3 = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        r4 = t3 / 256
        [r0, r1, r2, r3, r4]

fn :: poly1305 block limbs [Int] => [Int]
      poly1305 block limbs blk   =
        t0 = le32 at blk 0
        t1 = le32 at blk 4
        t2 = le32 at blk 8
        t3 = le32 at blk 12
        b0 = t0 % 67108864
        b1 = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        b2 = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        b3 = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        b4 = (t3 / 256) + 16777216
        [b0, b1, b2, b3, b4]

fn :: poly1305 step [Int] [Int] [Int] => [Int]
      poly1305 step h     r     blk   =
        b  = poly1305 block limbs blk
        h0 = (c nth int h 0) + (c nth int b 0)
        h1 = (c nth int h 1) + (c nth int b 1)
        h2 = (c nth int h 2) + (c nth int b 2)
        h3 = (c nth int h 3) + (c nth int b 3)
        h4 = (c nth int h 4) + (c nth int b 4)
        r0 = c nth int r 0
        r1 = c nth int r 1
        r2 = c nth int r 2
        r3 = c nth int r 3
        r4 = c nth int r 4
        s1 = r1 * 5
        s2 = r2 * 5
        s3 = r3 * 5
        s4 = r4 * 5
        d0 = (h0 * r0) + (h1 * s4) + (h2 * s3) + (h3 * s2) + (h4 * s1)
        d1 = (h0 * r1) + (h1 * r0) + (h2 * s4) + (h3 * s3) + (h4 * s2)
        d2 = (h0 * r2) + (h1 * r1) + (h2 * r0) + (h3 * s4) + (h4 * s3)
        d3 = (h0 * r3) + (h1 * r2) + (h2 * r1) + (h3 * r0) + (h4 * s4)
        d4 = (h0 * r4) + (h1 * r3) + (h2 * r2) + (h3 * r1) + (h4 * r0)
        c0 = d0 / 67108864
        n0 = d0 % 67108864
        e1 = d1 + c0
        c1 = e1 / 67108864
        n1 = e1 % 67108864
        e2 = d2 + c1
        c2 = e2 / 67108864
        n2 = e2 % 67108864
        e3 = d3 + c2
        c3 = e3 / 67108864
        n3 = e3 % 67108864
        e4 = d4 + c3
        c4 = e4 / 67108864
        n4 = e4 % 67108864
        f0 = n0 + (c4 * 5)
        cf = f0 / 67108864
        [f0 % 67108864, n1 + cf, n2, n3, n4]

fn :: poly1305 blocks loop [Int] [Int] [Int] => [Int]
      poly1305 blocks loop h _ [] = h
      poly1305 blocks loop h r msg =
        blk  = c take ints msg 16
        rest = c drop ints msg 16
        poly1305 blocks loop (poly1305 step h r blk) r rest

fn :: select reduced limbs Int [Int] [Int] => [Int]
      select reduced limbs g4 g_set h_set =
        | g4 >= 0   = g_set
        | otherwise = h_set

fn :: poly1305 finalize [Int] [Int] => [Int]
      poly1305 finalize h     otk   =
        c1   = (c nth int h 1) / 67108864
        h1   = (c nth int h 1) % 67108864
        t2   = (c nth int h 2) + c1
        c2   = t2 / 67108864
        h2   = t2 % 67108864
        t3   = (c nth int h 3) + c2
        c3   = t3 / 67108864
        h3   = t3 % 67108864
        t4   = (c nth int h 4) + c3
        c4   = t4 / 67108864
        h4   = t4 % 67108864
        t0   = (c nth int h 0) + (c4 * 5)
        c0   = t0 / 67108864
        h0   = t0 % 67108864
        h1_f = h1 + c0

        g0_t = h0 + 5
        gc0  = g0_t / 67108864
        g0   = g0_t % 67108864
        g1_t = h1_f + gc0
        gc1  = g1_t / 67108864
        g1   = g1_t % 67108864
        g2_t = h2 + gc1
        gc2  = g2_t / 67108864
        g2   = g2_t % 67108864
        g3_t = h3 + gc2
        gc3  = g3_t / 67108864
        g3   = g3_t % 67108864
        g4   = (h4 + gc3) - 67108864

        fin  = select reduced limbs g4 [g0, g1, g2, g3, g4] [h0, h1_f, h2, h3, h4]
        f0   = c nth int fin 0
        f1   = c nth int fin 1
        f2   = c nth int fin 2
        f3   = c nth int fin 3
        f4   = c nth int fin 4

        w0   = (f0 + ((f1 % 64) * 67108864)) % 4294967296
        w1   = ((f1 / 64) + ((f2 % 4096) * 1048576)) % 4294967296
        w2   = ((f2 / 4096) + ((f3 % 262144) * 16384)) % 4294967296
        w3   = ((f3 / 262144) + (f4 * 256)) % 4294967296

        s0   = le32 at otk 16
        s1   = le32 at otk 20
        s2   = le32 at otk 24
        s3   = le32 at otk 28

        sum0 = w0 + s0
        sum1 = w1 + s1 + (sum0 / 4294967296)
        sum2 = w2 + s2 + (sum1 / 4294967296)
        sum3 = w3 + s3 + (sum2 / 4294967296)
        (u32 to le4 (sum0 % 4294967296)) :: (u32 to le4 (sum1 % 4294967296)) :: (u32 to le4 (sum2 % 4294967296)) :: (u32 to le4 (sum3 % 4294967296))

fn :: pad16 zeroes Int => [Int]
      pad16 zeroes len =
        | (len % 16) == 0 = []
        | otherwise       = pad zeroes (16 - (len % 16))

fn :: u64 le8 Int => [Int]
      u64 le8 n   =
        (u32 to le4 (n % 4294967296)) :: (u32 to le4 (n / 4294967296))

fn :: poly1305 aead mac [Int] [Int] [Int] => [Int]
      poly1305 aead mac otk aad_b ct_b =
        aad_b c list len -> alen
        ct_b c list len -> clen
        aad_b :: (pad16 zeroes alen) :: ct_b :: (pad16 zeroes clen) :: (u64 le8 alen) :: (u64 le8 clen) -> msg
        otk poly1305 clamp r -> poly1305 r limbs -> r
        poly1305 blocks loop [0, 0, 0, 0, 0] r msg -> h_fin
        poly1305 finalize h_fin otk

fn :: aead seal String String String String => String
      aead seal key nonce aad plaintext =
        | (str len key) != 32 or (str len nonce) != 12 = ""
        | otherwise                                    =
          key_bs   = bytes to list key
          nonce_bs = bytes to list nonce
          aad_bs   = bytes to list aad
          pt_bs    = bytes to list plaintext
          otk      = c take ints (chacha20 block key_bs nonce_bs 0) 32
          ct_bs    = chacha20 bitxor loop key_bs nonce_bs 1 pt_bs [] [] [] 0
          tag_bs   = poly1305 aead mac otk aad_bs ct_bs
          bytes from list (ct_bs :: tag_bs)

fn :: decrypt verified aead Bool [Int] [Int] [Int] => Int String
      decrypt verified aead False _ _ _ = (0 - 12, "")
      decrypt verified aead True key_bs nonce_bs ct_bs =
        chacha20 bitxor loop key_bs nonce_bs 1 ct_bs [] [] [] 0 -> pt_bs
        (0, bytes from list pt_bs)

fn :: aead open String String String String => Int String
      aead open key nonce aad ciphertext_and_tag =
        | (str len key) != 32 or (str len nonce) != 12 or (str len ciphertext_and_tag) < 16 = (0 - 7, "")
        | otherwise =
          total_len = str len ciphertext_and_tag
          ct_len    = total_len - 16
          ct_str    = byte slice ciphertext_and_tag 0 ct_len
          tag_str   = byte slice ciphertext_and_tag ct_len total_len
          key_bs    = bytes to list key
          nonce_bs  = bytes to list nonce
          aad_bs    = bytes to list aad
          ct_bs     = bytes to list ct_str
          otk       = c take ints (chacha20 block key_bs nonce_bs 0) 32
          exp_tag   = bytes from list (poly1305 aead mac otk aad_bs ct_bs)
          decrypt verified aead (ct equal tag_str exp_tag) key_bs nonce_bs ct_bs
```

---

## 24.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `crypto`

- **Algoritmisk garanti och säkerhet**: `aead open` verifierar Poly1305-autentiseringstaggen på 16 byte i konstant tid innan en enda byte klartext lämnas ut (returnerar `(-1, "")` vid manipulering).
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/crypto.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test crypto.rg`.

### De 5 Gyllene Reglerna när du programmerar med `crypto`

1. **Deklarera `import crypto` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `crypto`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `crypto`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `crypto` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 25** går vi vidare och utforskar lib:en **`argon2id`** på djupet (Lib:en `argon2id` — RFC 9106 Argon2id över `Tensor[U64 * 8 * 16]`, Blake2b och OWASP-profiler).
