# Kapitel 24: Lib:en `crypto` — Hashar, HMAC, HKDF, PBKDF2, AEAD-chiffer, X25519, Ed25519, ECDSA, RSA och X.509

## 24.1. Varför finns lib:en `crypto`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `crypto`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `crypto`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att jämföra en HMAC med `==` öppnar dörren för sidokanalsattacker (*timing attacks*), och att länka in `libssl.so` för att beräkna `SHA-256` eller kryptera med `ChaCha20-Poly1305` förstör binärens portabilitet.

Lib:en **`crypto`** implementerar i 100 % ren Ridgun, på tensorer: råa byte- och bitprimitiver (`RGF-019`), hasharna **SHA-256**, **SHA-384**, **SHA-512**, **SHA-1** och **MD5**, **HMAC** och **HKDF**, konstanttidslikhet (`ct equal`), **PBKDF2-HMAC-SHA-256**, AEAD-chiffren **ChaCha20-Poly1305** (RFC 8439) och **AES-128-GCM** (NIST SP 800-38D), nyckelöverenskommelse med **X25519**, signaturer med **Ed25519** och Minisign, **ECDH** och **ECDSA** på P-256 och P-384, verifiering av **RSA** PKCS#1 v1.5 och PSS samt tolkning av **X.509**-certifikat. Den erbjuder också lib:en `argon2id` (`import argon2id` plus `export argon2id`), så `argon2id hash` och `argon2id verify` är tillgängliga med enbart `import crypto`. Chiffren, Poly1305, GHASH och aritmetiken för stora tal körs på kompilatorns operationer över hela tensorer: att försegla 1 MiB med `aead seal` tar ungefär 3 ms.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`CRYPTO`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`crypto`** (`src/main/ridgun/lib/crypto.ridgun`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import crypto` (eller `import crypto as alias`) överst i filen**: varje lib definierar sin `module :: crypto`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `crypto` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 24.2. Inbyggda artefakter, import och komplett API-katalog för `crypto`

I `ridgun-libs` är **`crypto`** en förstklassig **lib** placerad i `src/main/ridgun/lib/crypto.ridgun` (domän `CRYPTO`). När du bygger med `stable bundle` paketeras den i ett inbyggt format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/crypto.ridgunlib` | Portabel distribution och direkt import med `import crypto` |

> Varje lib deklarerar sin egen namnrymd med `module :: crypto`: skriv bara `import crypto` (eller `import crypto as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 24.2.1. Översikt över funktionella familjer i `crypto`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `sha256 bytes / sha256 hex` | FIPS 180-4 SHA-256 som 32-bytes binär digest eller 64-teckens hex-sträng |
| `hmac sha256 / ct equal` | RFC 2104-nycklad MAC och ackumulatorjämförelse i konstant tid |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | RFC 8018-nyckelhärledning med förberäknade inre/yttre SHA-256-mellantillstånd |
| `argon2id hash / argon2id verify` | 5-arguments RFC 9106 PHC-lösenordshashning och konstanttidsverifiering |
| `aead seal / aead open` | RFC 8439 ChaCha20-Poly1305 autentiserad kryptering och taggverifierad dekryptering |
| `sha512 bytes / sha512 hex` | 64-byte rått binärt eller 128-teckens hexadecimalt FIPS 180-4 SHA-512-sammandrag |
| `ed25519 public key / ed25519 sign / ed25519 verify` | RFC 8032 §5.1 ren Ed25519 publik nyckel, konstanttidssignering och kanonisk verifiering |
| `minisign sign / minisign verify / minisign trusted comment` | Publika nycklar och `.minisig`-signaturer kompatibla med standardverktyget `minisign` |
| `sha1 bytes / sha1 hex / md5 bytes / md5 hex` | SHA-1 och MD5 för protokoll som fortfarande anger dem (WebSocket-handskakning, PostgreSQL:s `md5`-autentisering); inte för nya konstruktioner |
| `sha384 bytes / hmac sha384 / hkdf extract / hkdf expand / hkdf expand label` | SHA-384, HMAC-SHA-384 och RFC 5869 HKDF, med etikettformen från TLS 1.3 |
| `x25519 / x25519 public key` | RFC 7748 Diffie-Hellman-nyckelöverenskommelse i konstant tid |
| `aes128 gcm seal / aes128 gcm open` | AES-128-GCM autentiserad kryptering och taggverifierad dekryptering (NIST SP 800-38D) |
| `p256 public key / p256 ecdh / ecdsa p256 verify / ecdsa p384 verify / rsa verify pkcs1 / rsa verify pss` | ECDH på P-256, ECDSA-verifiering på P-256 och P-384 samt verifiering av RSA-signaturer för nycklar på 2048 bitar eller mer |
| `x509 parse cert / x509 match hostname / x509 verify cert sig` | Tolkning av X.509-certifikat, RFC 6125-värdnamnsmatchning och verifiering av utfärdarens signatur |

### 24.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/crypto.ridgun`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/crypto.ridgun` (`6` typer, `0` operatorer och `455` funktioner):

**Algebraiska datatyper och poster (`type`) i `crypto`:**

```ridgun
type CT16     = ct0: A, ct1: A, ct2: A, ct3: A, ct4: A, ct5: A, ct6: A, ct7: A, ct8: A, ct9: A, ct10: A, ct11: A, ct12: A, ct13: A, ct14: A, ct15: A
type CPbkCtx  = cptbl: CT16, cpipad: String, cpopad: String
type EcPoint  = ecx: Tensor[U64 * 260], ecy: Tensor[U64 * 260], ecz: Tensor[U64 * 260], ec_inf: Bool
type BnMont = bm_m: Tensor[U64 * 260], bm_lim: Int, bm_minv: Int, bm_one: Tensor[U64 * 260], bm_r2: Tensor[U64 * 260], bm_unit: Tensor[U64 * 260], bm_sh: Tensor[U64 * n], bm_nx: Tensor[U64 * n], bm_zr: Tensor[U64 * n], bm_e0: Tensor[U64 * n]
type EcCurve  = ecp: Tensor[U64 * 260], ecn: Tensor[U64 * 260], ecb: Tensor[U64 * 260], ecgx: Tensor[U64 * 260], ecgy: Tensor[U64 * 260], eclimbs: Int, ecm: BnMont
type X509Cert = tbs_der: String, issuer_der: String, subject_der: String, issuer_cn: String, subject_cn: String, not_before_at: Int, not_after_at: Int, key_alg: String, pubkey_bytes: String, rsa_exp_bytes: String, sig_alg: String, sig_bytes: String, san_dns: [String], is_ca: Bool, key_usage_bits: Int, has_server_auth: Bool
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: norm byte mod Int` | `Int` |
| `2` | `fn :: norm byte Int` | `Int` |
| `3` | `fn :: byte str norm Int` | `String` |
| `4` | `fn :: byte str Int` | `String` |
| `5` | `fn :: c sb append3 String String` | `String String String String` |
| `6` | `fn :: c sb append2 String String String` | `String String String String` |
| `7` | `fn :: c sb append1 String String String String` | `String String String String` |
| `8` | `fn :: c sb append String String String String String` | `String String String String` |
| `9` | `fn :: c sb finish String String String String` | `String` |
| `10` | `fn :: c u8 len Tensor[U8]` | `Int` |
| `11` | `fn :: c copy loop Tensor[U8] Int Tensor[U8] Int Int Int` | `Int` |
| `12` | `fn :: c copy bytes Tensor[U8] Int Tensor[U8] Int Int` | `Int` |
| `13` | `fn :: c put le32 Tensor[U8] Int Int` | `Int` |
| `14` | `fn :: bytes from list loop Tensor[U8] [Int] Int` | `Tensor[U8]` |
| `15` | `fn :: bytes from list [Int]` | `String` |
| `16` | `fn :: bytes to list String` | `[Int]` |
| `17` | `fn :: u32 mod Int` | `Int` |
| `18` | `fn :: u32 val Int` | `Int` |
| `19` | `fn :: byte band Int Int` | `Int` |
| `20` | `fn :: byte bor Int Int` | `Int` |
| `21` | `fn :: byte bxor Int Int` | `Int` |
| `22` | `fn :: band Int Int` | `Int` |
| `23` | `fn :: bor Int Int` | `Int` |
| `24` | `fn :: c u32 bxor Int Int` | `Int` |
| `25` | `fn :: bxor Int Int` | `Int` |
| `26` | `fn :: shl Int Int` | `Int` |
| `27` | `fn :: shr Int Int` | `Int` |
| `28` | `fn :: rotl32 Int Int` | `Int` |
| `29` | `fn :: bytes list to hex Tensor[U8]` | `String` |
| `30` | `fn :: bytes to hex str String` | `String` |
| `31` | `fn :: crypto hex val Int` | `Int` |
| `32` | `fn :: hex str to bytes loop String Tensor[U8] Int Int` | `Tensor[U8]` |
| `33` | `fn :: hex str to bytes String` | `Tensor[U8]` |
| `34` | `fn :: hex to byte str String` | `String` |
| `35` | `fn :: c list len loop [Int] Int` | `Int` |
| `36` | `fn :: c list len [Int]` | `Int` |
| `37` | `fn :: byte slice String Int Int` | `String` |
| `38` | `fn :: sha1 copy loop String Tensor[U8] Int Int` | `Tensor[U8]` |
| `39` | `fn :: sha1 padded String` | `Tensor[U8]` |
| `40` | `fn :: sha1 put len Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `41` | `fn :: sha1 be32 at Tensor[U8] Int` | `Int` |
| `42` | `fn :: sha1 load w Tensor[U8] Int Tensor[Int] Int` | `Tensor[Int]` |
| `43` | `fn :: sha1 expand w Tensor[Int] Int` | `Tensor[Int]` |
| `44` | `fn :: sha1 f Int Int Int Int` | `Int` |
| `45` | `fn :: sha1 k Int` | `Int` |
| `46` | `fn :: sha1 rounds Tensor[Int] Int Int Int Int Int Int` | `Int Int Int Int Int` |
| `47` | `fn :: sha1 add Tensor[Int] (Int Int Int Int Int)` | `Tensor[Int]` |
| `48` | `fn :: sha1 blocks Tensor[U8] Tensor[Int] Tensor[Int] Int Int` | `Tensor[Int]` |
| `49` | `fn :: sha1 out Tensor[Int] Tensor[U8] Int` | `Tensor[U8]` |
| `50` | `fn :: sha1 bytes String` | `String` |
| `51` | `fn :: sha1 hex String` | `String` |
| `52` | `fn :: md5 k` | `Tensor[Int]` |
| `53` | `fn :: md5 s` | `Tensor[Int]` |
| `54` | `fn :: md5 padded String` | `Tensor[U8]` |
| `55` | `fn :: md5 put len Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `56` | `fn :: md5 load w Tensor[U8] Int Tensor[Int] Int` | `Tensor[Int]` |
| `57` | `fn :: md5 f Int Int Int Int` | `Int` |
| `58` | `fn :: md5 g Int` | `Int` |
| `59` | `fn :: md5 rounds Tensor[Int] Tensor[Int] Tensor[Int] Int Int Int Int Int` | `Int Int Int Int` |
| `60` | `fn :: md5 add Tensor[Int] (Int Int Int Int)` | `Tensor[Int]` |
| `61` | `fn :: md5 blocks Tensor[U8] Tensor[Int] Tensor[Int] Tensor[Int] Tensor[Int] Int Int` | `Tensor[Int]` |
| `62` | `fn :: md5 out Tensor[Int] Tensor[U8] Int` | `Tensor[U8]` |
| `63` | `fn :: md5 bytes String` | `String` |
| `64` | `fn :: md5 hex String` | `String` |
| `65` | `fn :: sha256 hex String` | `String` |
| `66` | `fn :: sha256 bytes String` | `String` |
| `67` | `fn :: bitxor key pad loop Tensor[U8] Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `68` | `fn :: bitxor key pad Tensor[U8] Int` | `Tensor[U8]` |
| `69` | `fn :: c hmac key block String Int` | `Tensor[U8]` |
| `70` | `fn :: normalize hmac key String` | `Tensor[U8]` |
| `71` | `fn :: hmac sha256 String String` | `String` |
| `72` | `fn :: ct diff str String String Int Int Int` | `Int` |
| `73` | `fn :: ct equal String String` | `Bool` |
| `74` | `fn :: bitxor byte lists loop Tensor[U8] Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `75` | `fn :: bitxor byte lists Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `76` | `fn :: bitxor byte strings String String` | `String` |
| `77` | `fn :: be32 bytes Int` | `String` |
| `78` | `fn :: c get16 CT16 Int` | `A` |
| `79` | `fn :: c set16 CT16 Int A` | `CT16` |
| `80` | `fn :: c build b16 Int` | `CT16` |
| `81` | `fn :: c build b256` | `CT16` |
| `82` | `fn :: c get b256 CT16 Int Int` | `String` |
| `83` | `fn :: c hex nib Int` | `Int` |
| `84` | `fn :: c hex pair CT16 String Int` | `String` |
| `85` | `fn :: c hex2raw4 CT16 String Int` | `String` |
| `86` | `fn :: c hex2raw32 CT16 String` | `String` |
| `87` | `fn :: c hex8 word String Int` | `U64` |
| `88` | `fn :: c bxor acc8 Tensor[U64 * 8] String` | `Tensor[U64 * 8]` |
| `89` | `fn :: c word32 to raw4 CT16 U64` | `String` |
| `90` | `fn :: c acc8 to raw CT16 Tensor[U64 * 8]` | `String` |
| `91` | `fn :: c init acc32 String` | `Tensor[U64 * 32]` |
| `92` | `fn :: c bxor1 acc32 Tensor[U64 * 32] String` | `Tensor[U64 * 32]` |
| `93` | `fn :: c bxor8 lo Tensor[U64 * 32] String String String String String String String String` | `Tensor[U64 * 32]` |
| `94` | `fn :: c bxor8 hi Tensor[U64 * 32] String String String String String String String String` | `Tensor[U64 * 32]` |
| `95` | `fn :: c acc32 quad CT16 Tensor[U64 * 32] Int` | `String` |
| `96` | `fn :: c acc32 to raw CT16 Tensor[U64 * 32]` | `String` |
| `97` | `fn :: pbkdf2 iter loop Int String String String Tensor[U64 * 32]` | `Tensor[U64 * 32]` |
| `98` | `fn :: pbkdf2 block CPbkCtx String Int Int` | `String` |
| `99` | `fn :: pbkdf2 blocks loop CPbkCtx String Int Int Int String` | `String` |
| `100` | `fn :: pbkdf2 hmac sha256 String String Int Int` | `String` |
| `101` | `fn :: f blamka U64 U64` | `U64` |
| `102` | `fn :: blamka g U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `103` | `fn :: blamka p16 Tensor[U64 * 16]` | `()` |
| `104` | `fn :: ca2 blamka col pair Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `105` | `fn :: ca2 blamka cols loop Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `106` | `fn :: compress block Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `107` | `fn :: le32 at Tensor[U8] Int` | `Int` |
| `108` | `fn :: chacha rounds Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Int` | `Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n]` |
| `109` | `fn :: chacha fill counter Tensor[U32 * n] Int Int Int` | `Tensor[U32 * n]` |
| `110` | `fn :: chacha page Tensor[U8] Tensor[U8] Int Int` | `Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n]` |
| `111` | `fn :: c first bytes Tensor[U8] Int Int` | `Tensor[U8]` |
| `112` | `fn :: chacha20 key stream chunk Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `113` | `fn :: chacha20 key stream Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `114` | `fn :: chacha20 block Tensor[U8] Tensor[U8] Int` | `Tensor[U8]` |
| `115` | `fn :: c bitxor bytes Tensor[U8 * n] Tensor[U8 * n]` | `Tensor[U8 * n]` |
| `116` | `fn :: chacha20 bitxor Tensor[U8] Tensor[U8] Int Tensor[U8]` | `Tensor[U8]` |
| `117` | `fn :: poly1305 r limbs Tensor[U8]` | `Tensor[Int * 5]` |
| `118` | `fn :: poly1305 step Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int` | `Tensor[Int * 5]` |
| `119` | `fn :: poly1305 blocks loop Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int Int` | `Tensor[Int * 5]` |
| `120` | `fn :: poly1305 lanes loop Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U8] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Int Int` | `Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n]` |
| `121` | `fn :: poly1305 mul into Tensor[Int * m] Int Tensor[Int * k] Int Tensor[Int * j] Int` | `Int` |
| `122` | `fn :: poly1305 carry into Int Int Int Int Int Tensor[Int * j] Int` | `Int` |
| `123` | `fn :: poly1305 powers Tensor[Int * m] Tensor[Int * 5] Int Int` | `Tensor[Int * m]` |
| `124` | `fn :: poly1305 lane starts Tensor[U64 * n] Int Int Int` | `Tensor[U64 * n]` |
| `125` | `fn :: poly1305 lane powers Tensor[U64 * n] Tensor[Int * m] Int Int Int Int` | `Tensor[U64 * n]` |
| `126` | `fn :: poly1305 lanes Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int Int` | `Tensor[Int * 5]` |
| `127` | `fn :: c pick Bool Int Int` | `Int` |
| `128` | `fn :: poly1305 finalize Tensor[Int * 5] Tensor[U8]` | `Tensor[U8]` |
| `129` | `fn :: pad16 len Int` | `Int` |
| `130` | `fn :: c put le64 Tensor[U8] Int Int` | `Int` |
| `131` | `fn :: poly1305 aead mac Tensor[U8] Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `132` | `fn :: aead seal String String String String` | `String` |
| `133` | `fn :: decrypt verified aead Bool Tensor[U8] Tensor[U8] Tensor[U8]` | `Int String` |
| `134` | `fn :: aead open String String String String` | `Int String` |
| `135` | `fn :: sha512 k hex0` | `String` |
| `136` | `fn :: sha512 k hex1` | `String` |
| `137` | `fn :: sha512 fill hex words Tensor[U64 * 160] String Int Int` | `Tensor[U64 * 160]` |
| `138` | `fn :: sha512 init k` | `Tensor[U64 * 160]` |
| `139` | `fn :: sha512 init h loop Tensor[U64 * 16] String Int` | `Tensor[U64 * 16]` |
| `140` | `fn :: sha512 init h` | `Tensor[U64 * 16]` |
| `141` | `fn :: sha512 rrot lt32 U64 U64 Int` | `U64 U64` |
| `142` | `fn :: sha512 rshift lt32 U64 U64 Int` | `U64 U64` |
| `143` | `fn :: sha512 big sigma0 U64 U64` | `U64 U64` |
| `144` | `fn :: sha512 big sigma1 U64 U64` | `U64 U64` |
| `145` | `fn :: sha512 small sigma0 U64 U64` | `U64 U64` |
| `146` | `fn :: sha512 small sigma1 U64 U64` | `U64 U64` |
| `147` | `fn :: sha512 vbyte String Int Int Int` | `U64` |
| `148` | `fn :: sha512 load w fast Tensor[U64 * 160] String Int Int` | `Tensor[U64 * 160]` |
| `149` | `fn :: sha512 load w pad Tensor[U64 * 160] String Int Int Int Int` | `Tensor[U64 * 160]` |
| `150` | `fn :: sha512 expand w Tensor[U64 * 160] Int` | `Tensor[U64 * 160]` |
| `151` | `fn :: sha512 copy state Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `152` | `fn :: sha512 add state Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `153` | `fn :: sha512 rounds loop Tensor[U64 * 16] Tensor[U64 * 160] Tensor[U64 * 160] Int` | `Tensor[U64 * 16]` |
| `154` | `fn :: sha512 blocks loop Tensor[U64 * 16] Tensor[U64 * 16] Tensor[U64 * 160] Tensor[U64 * 160] String Int Int Int` | `Tensor[U64 * 16]` |
| `155` | `fn :: sha512 state to raw CT16 Tensor[U64 * 16] Int` | `String` |
| `156` | `fn :: sha512 bytes String` | `String` |
| `157` | `fn :: sha512 hex String` | `String` |
| `158` | `fn :: fe lit U64 U64 U64 U64 U64 U64 U64 U64 U64 U64` | `Tensor[U64 * 10]` |
| `159` | `fn :: fe zero` | `Tensor[U64 * 10]` |
| `160` | `fn :: fe one` | `Tensor[U64 * 10]` |
| `161` | `fn :: fe d` | `Tensor[U64 * 10]` |
| `162` | `fn :: fe d2` | `Tensor[U64 * 10]` |
| `163` | `fn :: fe sqrt m1` | `Tensor[U64 * 10]` |
| `164` | `fn :: fe bx` | `Tensor[U64 * 10]` |
| `165` | `fn :: fe by` | `Tensor[U64 * 10]` |
| `166` | `fn :: fe bt` | `Tensor[U64 * 10]` |
| `167` | `fn :: fe carry pass Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `168` | `fn :: fe carry Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `169` | `fn :: fe add Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `170` | `fn :: fe sub Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `171` | `fn :: fe mul Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `172` | `fn :: fe sq Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `173` | `fn :: fe sq n Tensor[U64 * 10] Int` | `Tensor[U64 * 10]` |
| `174` | `fn :: fe freeze Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `175` | `fn :: fe eq Tensor[U64 * 10] Tensor[U64 * 10]` | `Bool` |
| `176` | `fn :: fe pow22523 Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `177` | `fn :: fe invert Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `178` | `fn :: fe to words8 Tensor[U64 * 10]` | `Tensor[U64 * 8]` |
| `179` | `fn :: words8 to raw32 loop CT16 Tensor[U64 * 8] Int` | `String` |
| `180` | `fn :: raw32 to words8 String` | `Tensor[U64 * 8]` |
| `181` | `fn :: fe from raw32 String` | `Bool U64 Tensor[U64 * 10]` |
| `182` | `fn :: ge pack Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 40]` |
| `183` | `fn :: ge coord Tensor[U64 * 40] Int` | `Tensor[U64 * 10]` |
| `184` | `fn :: ge zero` | `Tensor[U64 * 40]` |
| `185` | `fn :: ge base` | `Tensor[U64 * 40]` |
| `186` | `fn :: ge add Tensor[U64 * 40] Tensor[U64 * 40]` | `Tensor[U64 * 40]` |
| `187` | `fn :: ge dbl Tensor[U64 * 40]` | `Tensor[U64 * 40]` |
| `188` | `fn :: ge cselect loop Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 40] U64 Int` | `Tensor[U64 * 40]` |
| `189` | `fn :: ge cselect Tensor[U64 * 40] Tensor[U64 * 40] U64` | `Tensor[U64 * 40]` |
| `190` | `fn :: ge scalarmult loop Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 8] Int` | `Tensor[U64 * 40]` |
| `191` | `fn :: ge scalarmult ct Tensor[U64 * 40] Tensor[U64 * 8]` | `Tensor[U64 * 40]` |
| `192` | `fn :: ge to bytes Tensor[U64 * 40]` | `String` |
| `193` | `fn :: ge finish sign Bool Bool Tensor[U64 * 10] Tensor[U64 * 10]` | `Bool Tensor[U64 * 40]` |
| `194` | `fn :: ge decompress step2 Tensor[U64 * 10] Tensor[U64 * 10] U64` | `Bool Tensor[U64 * 40]` |
| `195` | `fn :: ge check root Bool Bool Tensor[U64 * 10] Tensor[U64 * 10] U64` | `Bool Tensor[U64 * 40]` |
| `196` | `fn :: ge decompress y Bool U64 Tensor[U64 * 10]` | `Bool Tensor[U64 * 40]` |
| `197` | `fn :: ge from bytes String` | `Bool Tensor[U64 * 40]` |
| `198` | `fn :: sc l words` | `Tensor[U64 * 8]` |
| `199` | `fn :: sc lt l loop Tensor[U64 * 8] Tensor[U64 * 8] Int` | `Bool` |
| `200` | `fn :: sc lt l Tensor[U64 * 8]` | `Bool` |
| `201` | `fn :: sc sub word U64 U64` | `U64 U64` |
| `202` | `fn :: sc sub l loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int U64` | `Tensor[U64 * 8]` |
| `203` | `fn :: sc sub l Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `204` | `fn :: sc norm l Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `205` | `fn :: sc add raw loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int U64` | `Tensor[U64 * 8]` |
| `206` | `fn :: sc add mod l Tensor[U64 * 8] Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `207` | `fn :: sc zero` | `Tensor[U64 * 8]` |
| `208` | `fn :: sc one` | `Tensor[U64 * 8]` |
| `209` | `fn :: sc cond add bit Bool Tensor[U64 * 8] Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `210` | `fn :: sc reduce byte bits Tensor[U64 * 8] Tensor[U64 * 8] U64 Int` | `Tensor[U64 * 8]` |
| `211` | `fn :: sc reduce le64 loop Tensor[U64 * 8] Tensor[U64 * 8] String Int` | `Tensor[U64 * 8]` |
| `212` | `fn :: sc reduce le64 String` | `Tensor[U64 * 8]` |
| `213` | `fn :: sc mul word bits Tensor[U64 * 8] Tensor[U64 * 8] U64 Int` | `Tensor[U64 * 8]` |
| `214` | `fn :: sc mul mod l loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int` | `Tensor[U64 * 8]` |
| `215` | `fn :: sc muladd mod l Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `216` | `fn :: ed25519 clamp scalar String` | `Tensor[U64 * 8]` |
| `217` | `fn :: ed25519 public key String` | `String` |
| `218` | `fn :: ed25519 sign String String` | `String` |
| `219` | `fn :: ed25519 verify points Bool Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 8] String String String` | `Bool` |
| `220` | `fn :: ed25519 verify scalar Bool String String String Tensor[U64 * 8]` | `Bool` |
| `221` | `fn :: ed25519 verify String String String` | `Bool` |
| `222` | `fn :: c is ws Int` | `Bool` |
| `223` | `fn :: c trim start String Int Int` | `Int` |
| `224` | `fn :: c trim end String Int Int` | `Int` |
| `225` | `fn :: c trim String` | `String` |
| `226` | `fn :: c starts with String String` | `Bool` |
| `227` | `fn :: c split lines loop String Int Int Int [String]` | `[String]` |
| `228` | `fn :: c split lines trimmed String Int` | `[String]` |
| `229` | `fn :: c split lines String` | `[String]` |
| `230` | `fn :: c b64 table` | `String` |
| `231` | `fn :: c b64 ch Int` | `String` |
| `232` | `fn :: c b64 encode loop String Int Int` | `String` |
| `233` | `fn :: c b64 encode String` | `String` |
| `234` | `fn :: c b64 val Int` | `Int` |
| `235` | `fn :: c b64 quad CT16 String Int Int String Int Int Int Int` | `Bool String` |
| `236` | `fn :: c b64 decode loop CT16 String Int Int String` | `Bool String` |
| `237` | `fn :: c b64 decode trimmed String Int` | `Bool String` |
| `238` | `fn :: c b64 decode String` | `Bool String` |
| `239` | `fn :: c nth str [String] Int` | `String` |
| `240` | `fn :: c str list len [String] Int` | `Int` |
| `241` | `fn :: minisign encode pubkey String String` | `String` |
| `242` | `fn :: minisign select pubkey line [String] Int` | `String` |
| `243` | `fn :: minisign unpack pubkey Bool String` | `String String` |
| `244` | `fn :: minisign decode pubkey String` | `String String` |
| `245` | `fn :: minisign sign String String String String String` | `String` |
| `246` | `fn :: minisign extract tc line String` | `String` |
| `247` | `fn :: minisign extract tc lines [String] Int` | `String` |
| `248` | `fn :: minisign trusted comment String` | `String` |
| `249` | `fn :: minisign payload for alg String String` | `Bool String` |
| `250` | `fn :: minisign check sigs Bool String String String String String String` | `Bool` |
| `251` | `fn :: minisign verify decoded Bool String String String String String` | `Bool` |
| `252` | `fn :: minisign verify body Bool String String String String String String` | `Bool` |
| `253` | `fn :: minisign verify lines Bool String String String [String]` | `Bool` |
| `254` | `fn :: minisign verify String String String` | `Bool` |
| `255` | `fn :: sha384 init h` | `Tensor[U64 * 16]` |
| `256` | `fn :: sha384 state to raw CT16 Tensor[U64 * 16] Int` | `String` |
| `257` | `fn :: sha384 bytes String` | `String` |
| `258` | `fn :: sha384 hex String` | `String` |
| `259` | `fn :: normalize hmac384 key String` | `Tensor[U8]` |
| `260` | `fn :: hmac sha384 String String` | `String` |
| `261` | `fn :: c repeat byte Int Int` | `String` |
| `262` | `fn :: hkdf extract String String` | `String` |
| `263` | `fn :: hkdf expand loop String String Int Int String String` | `String` |
| `264` | `fn :: hkdf expand String String Int` | `String` |
| `265` | `fn :: hkdf extract sha384 String String` | `String` |
| `266` | `fn :: hkdf expand sha384 loop String String Int Int String String` | `String` |
| `267` | `fn :: hkdf expand sha384 String String Int` | `String` |
| `268` | `fn :: hkdf expand label String String String Int` | `String` |
| `269` | `fn :: derive secret String String String` | `String` |
| `270` | `fn :: fe a24` | `Tensor[U64 * 10]` |
| `271` | `fn :: fe cswap loop Tensor[U64 * 10] Tensor[U64 * 10] U64 Int` | `Tensor[U64 * 10] Tensor[U64 * 10]` |
| `272` | `fn :: fe cswap Tensor[U64 * 10] Tensor[U64 * 10] U64` | `Tensor[U64 * 10] Tensor[U64 * 10]` |
| `273` | `fn :: x25519 clamp scalar String` | `Tensor[U64 * 8]` |
| `274` | `fn :: x25519 decode u String` | `Tensor[U64 * 10]` |
| `275` | `fn :: x25519 ladder loop Tensor[U64 * 8] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] U64 Int` | `Tensor[U64 * 10] Tensor[U64 * 10]` |
| `276` | `fn :: x25519 check non zero String` | `String` |
| `277` | `fn :: x25519 String String` | `String` |
| `278` | `fn :: x25519 public key String` | `String` |
| `279` | `fn :: aes sbox hex` | `String` |
| `280` | `fn :: aes init sbox loop Tensor[U64 * 256] String Int` | `Tensor[U64 * 256]` |
| `281` | `fn :: aes init sbox` | `Tensor[U64 * 256]` |
| `282` | `fn :: aes rcon Int` | `U64` |
| `283` | `fn :: aes copy key init Tensor[U64 * 176] String Int` | `Tensor[U64 * 176]` |
| `284` | `fn :: aes expand key loop Tensor[U64 * 256] Tensor[U64 * 176] Int` | `Tensor[U64 * 176]` |
| `285` | `fn :: aes expand key Tensor[U64 * 256] String` | `Tensor[U64 * 176]` |
| `286` | `fn :: aes xtime U64` | `U64` |
| `287` | `fn :: aes mix col Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `288` | `fn :: aes sub shift Tensor[U64 * 256] Tensor[U64 * 16]` | `Tensor[U64 * 16]` |
| `289` | `fn :: aes add rk loop Tensor[U64 * 16] Tensor[U64 * 176] Int Int` | `Tensor[U64 * 16]` |
| `290` | `fn :: aes rounds loop Tensor[U64 * 256] Tensor[U64 * 176] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `291` | `fn :: aes load st Tensor[U64 * 16] Tensor[U64 * 176] String Int` | `Tensor[U64 * 16]` |
| `292` | `fn :: aes st to str CT16 Tensor[U64 * 16] Int` | `String` |
| `293` | `fn :: aes encrypt with rk CT16 Tensor[U64 * 256] Tensor[U64 * 176] String` | `String` |
| `294` | `fn :: aes128 block String String` | `String` |
| `295` | `fn :: aes sbox u8 loop Tensor[U64 * 256] Tensor[U8 * 256] Int` | `Tensor[U8 * 256]` |
| `296` | `fn :: aes ctr round Tensor[U8 * 256] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int` | `Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n]` |
| `297` | `fn :: aes ctr last round Tensor[U8 * 256] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int` | `Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n]` |
| `298` | `fn :: aes ctr fill Tensor[U8 * n] Int Int Int Int Int` | `Tensor[U8 * n]` |
| `299` | `fn :: aes ctr page Tensor[U8 * 256] Tensor[U64 * 176] Tensor[U8] Int Int` | `Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n]` |
| `300` | `fn :: aes ctr key stream chunk Tensor[U8 * 256] Tensor[U64 * 176] Tensor[U8] Int Int` | `Tensor[U8]` |
| `301` | `fn :: aes ctr key stream loop Tensor[U8 * 256] Tensor[U64 * 176] Tensor[U8] Int Int` | `Tensor[U8]` |
| `302` | `fn :: aes ctr key stream Tensor[U64 * 256] Tensor[U64 * 176] Tensor[U8] Int Int` | `Tensor[U8]` |
| `303` | `fn :: ghash mul Int Int Int Int` | `Int Int` |
| `304` | `fn :: ghash be64 Tensor[U8] Int Int` | `Int` |
| `305` | `fn :: ghash be64 tail Tensor[U8] Int Int Int Int` | `Int` |
| `306` | `fn :: ghash absorb Int Int Int Int Tensor[U8] Int Int` | `Int Int` |
| `307` | `fn :: ghash put be64 Tensor[U8] Int Int` | `Int` |
| `308` | `fn :: ghash compute Tensor[U8] Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `309` | `fn :: aes128 gcm seal String String String String` | `String` |
| `310` | `fn :: aes128 gcm open verified Bool Tensor[U64 * 256] Tensor[U64 * 176] String Tensor[U8]` | `Int String` |
| `311` | `fn :: aes128 gcm open String String String String` | `Int String` |
| `312` | `fn :: bn zero loop Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `313` | `fn :: bn zero Int` | `Tensor[U64 * 260]` |
| `314` | `fn :: bn zero520 loop Tensor[U64 * 520] Int Int` | `Tensor[U64 * 520]` |
| `315` | `fn :: bn zero520 Int` | `Tensor[U64 * 520]` |
| `316` | `fn :: bn clone loop Tensor[U64 * 260] Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `317` | `fn :: bn clone Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `318` | `fn :: bn strip leading zeroes String Int Int` | `String` |
| `319` | `fn :: bn from be loop Tensor[U64 * 260] String Int Int Int` | `Tensor[U64 * 260]` |
| `320` | `fn :: bn from be String Int` | `Tensor[U64 * 260]` |
| `321` | `fn :: bn from hex String Int` | `Tensor[U64 * 260]` |
| `322` | `fn :: bn to be loop CT16 Tensor[U64 * 260] Int String String String String` | `String` |
| `323` | `fn :: bn to be Tensor[U64 * 260] Int` | `String` |
| `324` | `fn :: bn is zero loop Tensor[U64 * 260] Int Int` | `Bool` |
| `325` | `fn :: bn is zero Tensor[U64 * 260] Int` | `Bool` |
| `326` | `fn :: bn cmp loop Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Int` |
| `327` | `fn :: bn cmp Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Int` |
| `328` | `fn :: bn add raw loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int U64` | `U64` |
| `329` | `fn :: bn sub raw loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int U64` | `U64` |
| `330` | `fn :: bn add mod finish Bool Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `331` | `fn :: bn add mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `332` | `fn :: bn sub mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `333` | `fn :: bn mul row loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int U64` | `Tensor[U64 * 520]` |
| `334` | `fn :: bn mul full loop Tensor[U64 * 520] Tensor[U64 * 260] Tensor[U64 * 260] Int Int` | `Tensor[U64 * 520]` |
| `335` | `fn :: bn sub qm loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int U64` | `Tensor[U64 * 520]` |
| `336` | `fn :: bn cmp520 offset loop Tensor[U64 * 520] Int Tensor[U64 * 260] Int` | `Int` |
| `337` | `fn :: bn ge520 offset Tensor[U64 * 520] Int Tensor[U64 * 260] Int` | `Bool` |
| `338` | `fn :: bn sub m while ge Tensor[U64 * 520] Int Tensor[U64 * 260] Int` | `Tensor[U64 * 520]` |
| `339` | `fn :: bn reduce step q Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int` | `Tensor[U64 * 520]` |
| `340` | `fn :: bn reduce loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int` | `Tensor[U64 * 520]` |
| `341` | `fn :: bn copy520 to out Tensor[U64 * 260] Tensor[U64 * 520] Int Int` | `Tensor[U64 * 260]` |
| `342` | `fn :: bn reduce520 Tensor[U64 * 520] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `343` | `fn :: bn mul mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `344` | `fn :: bn sq mod Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `345` | `fn :: bn mod from be String Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `346` | `fn :: bn mont loop Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Int Int` | `Tensor[U64 * n] Tensor[U64 * n]` |
| `347` | `fn :: bn mont carry Tensor[U64 * n] Tensor[U64 * 260] Int Int Int` | `Int` |
| `348` | `fn :: bn mont mul BnMont Tensor[U64 * 260] Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `349` | `fn :: bn mont ix Tensor[U64 * n] Int Int Int` | `Tensor[U64 * n]` |
| `350` | `fn :: bn mont minv Int` | `Int` |
| `351` | `fn :: bn mont pow2 BnMont Tensor[U64 * 260] Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `352` | `fn :: bn mont ctx Tensor[U64 * 260] Int` | `BnMont` |
| `353` | `fn :: bn mont mul mod BnMont Tensor[U64 * 260] Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `354` | `fn :: bn mont sq BnMont Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `355` | `fn :: bn mont in BnMont Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `356` | `fn :: bn mont out BnMont Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `357` | `fn :: bn mont pow bits Tensor[U64 * 260] BnMont Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `358` | `fn :: bn mont pow bytes Tensor[U64 * 260] BnMont Tensor[U64 * 260] String Int Int` | `Tensor[U64 * 260]` |
| `359` | `fn :: bn mont pow BnMont Tensor[U64 * 260] String` | `Tensor[U64 * 260]` |
| `360` | `fn :: bn mod exp bits loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int Int` | `Tensor[U64 * 260]` |
| `361` | `fn :: bn mod exp bytes loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int String Int Int` | `Tensor[U64 * 260]` |
| `362` | `fn :: bn mod exp plain Tensor[U64 * 260] String Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `363` | `fn :: bn mod exp mont Tensor[U64 * 260] String BnMont` | `Tensor[U64 * 260]` |
| `364` | `fn :: bn mod exp Tensor[U64 * 260] String Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `365` | `fn :: bn mod inv Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `366` | `fn :: p256 curve` | `EcCurve` |
| `367` | `fn :: p384 curve` | `EcCurve` |
| `368` | `fn :: ec inf point Int` | `EcPoint` |
| `369` | `fn :: ec affine point EcCurve Tensor[U64 * 260] Tensor[U64 * 260]` | `EcPoint` |
| `370` | `fn :: ec point on curve EcCurve Tensor[U64 * 260] Tensor[U64 * 260]` | `Bool` |
| `371` | `fn :: ec dbl EcCurve EcPoint` | `EcPoint` |
| `372` | `fn :: ec add diff EcCurve EcPoint Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260]` | `EcPoint` |
| `373` | `fn :: ec add EcCurve EcPoint EcPoint` | `EcPoint` |
| `374` | `fn :: ec to affine EcCurve EcPoint` | `Bool Tensor[U64 * 260] Tensor[U64 * 260]` |
| `375` | `fn :: ec cselect bn loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] U64 Int Int` | `Tensor[U64 * 260]` |
| `376` | `fn :: ec cselect point EcPoint EcPoint U64 Int` | `EcPoint` |
| `377` | `fn :: ec scalar mul loop EcCurve EcPoint EcPoint Tensor[U64 * 260] Int` | `EcPoint` |
| `378` | `fn :: ec scalar mul EcCurve EcPoint Tensor[U64 * 260]` | `EcPoint` |
| `379` | `fn :: ec shamir loop EcCurve EcPoint EcPoint EcPoint EcPoint Tensor[U64 * 260] Tensor[U64 * 260] Int` | `EcPoint` |
| `380` | `fn :: p256 public key inner EcCurve Tensor[U64 * 260]` | `String` |
| `381` | `fn :: p256 public key String` | `String` |
| `382` | `fn :: p256 ecdh inner EcCurve Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260]` | `String` |
| `383` | `fn :: p256 ecdh String String` | `String` |
| `384` | `fn :: ecdsa unpack der rs Bool Int Int Int Int Bool Int Int Int String Int` | `Bool String String` |
| `385` | `fn :: ecdsa unpack der seq Bool Int Int String Int` | `Bool String String` |
| `386` | `fn :: ecdsa unpack sig String Int` | `Bool String String` |
| `387` | `fn :: ecdsa verify shamir EcCurve Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] String Int` | `Bool` |
| `388` | `fn :: ecdsa verify curve EcCurve String String String` | `Bool` |
| `389` | `fn :: ecdsa p256 verify String String String` | `Bool` |
| `390` | `fn :: ecdsa p256 verify sha256 String String String` | `Bool` |
| `391` | `fn :: ecdsa p384 verify String String String` | `Bool` |
| `392` | `fn :: ecdsa p384 verify sha384 String String String` | `Bool` |
| `393` | `fn :: rsa mod exp inner String String String Int` | `String` |
| `394` | `fn :: rsa mod exp String String String` | `String` |
| `395` | `fn :: rsa hash msg String String` | `String` |
| `396` | `fn :: rsa digest info prefix String` | `String` |
| `397` | `fn :: rsa verify pkcs1 inner String String String String String Int` | `Bool` |
| `398` | `fn :: rsa verify pkcs1 String String String String String` | `Bool` |
| `399` | `fn :: rsa mgf1 loop String String Int Int String` | `String` |
| `400` | `fn :: rsa pss check db zeroes String Int Int` | `Bool` |
| `401` | `fn :: rsa pss unmask db CT16 String String Int Int String` | `String` |
| `402` | `fn :: rsa verify pss em String String String Int Int` | `Bool` |
| `403` | `fn :: rsa verify pss inner String String String String String Int` | `Bool` |
| `404` | `fn :: rsa verify pss String String String String String` | `Bool` |
| `405` | `fn :: pem strip ws step Bool CT16 Int String Int Int String String String String` | `String` |
| `406` | `fn :: pem strip ws loop CT16 String Int Int String String String String` | `String` |
| `407` | `fn :: pem decode b64 block CT16 String` | `Bool String` |
| `408` | `fn :: pem find sub from String String Int Int Int` | `Int` |
| `409` | `fn :: pem decode blocks step CT16 String String String Int Int Int [String]` | `[String]` |
| `410` | `fn :: pem decode blocks loop CT16 String String String Int Int [String]` | `[String]` |
| `411` | `fn :: pem decode blocks String String` | `[String]` |
| `412` | `fn :: asn1 read len bytes String Int Int Int` | `Int` |
| `413` | `fn :: asn1 finish tlv Bool Int Int Int Int Int` | `Bool Int Int Int Int` |
| `414` | `fn :: asn1 parse long len String Int Int Int Int` | `Bool Int Int Int Int` |
| `415` | `fn :: asn1 parse len dispatch String Int Int Int Int` | `Bool Int Int Int Int` |
| `416` | `fn :: asn1 parse tlv String Int` | `Bool Int Int Int Int` |
| `417` | `fn :: x509 parse dec2 String Int` | `Int` |
| `418` | `fn :: x509 days from civil Int Int Int` | `Int` |
| `419` | `fn :: x509 parse time tag Int String` | `Int` |
| `420` | `fn :: x509 parse validity inner Bool Int Int Int Int Int Int String` | `Int Int` |
| `421` | `fn :: x509 parse validity String Int Int` | `Int Int` |
| `422` | `fn :: x509 check cn attr Bool String Int Int Int` | `String` |
| `423` | `fn :: x509 find cn in rdn String Int Int` | `String` |
| `424` | `fn :: x509 parse sig alg oid String String` | `String` |
| `425` | `fn :: x509 parse sig alg String Int Int` | `String` |
| `426` | `fn :: x509 parse rsa spki String` | `String String String` |
| `427` | `fn :: x509 parse ec spki String Int String` | `String String String` |
| `428` | `fn :: x509 dispatch spki oid String String Int String` | `String String String` |
| `429` | `fn :: x509 parse spki inner Bool String Int Int Int` | `String String String` |
| `430` | `fn :: x509 parse spki String Int Int` | `String String String` |
| `431` | `fn :: x509 parse san entry Bool Int Int Int Int String Int [String]` | `[String]` |
| `432` | `fn :: x509 parse san loop String Int Int [String]` | `[String]` |
| `433` | `fn :: x509 ext octet span String Bool Int Int Int Int` | `Int Int` |
| `434` | `fn :: x509 dispatch ext oid String String Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `435` | `fn :: x509 parse single ext inner Bool String Int Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `436` | `fn :: x509 parse single ext String Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `437` | `fn :: x509 parse exts step Bool String Int Int Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `438` | `fn :: x509 parse exts loop String Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `439` | `fn :: x509 find exts step Bool Int Int Int String Int` | `[String] Bool Int Bool` |
| `440` | `fn :: x509 find exts in tbs String Int Int` | `[String] Bool Int Bool` |
| `441` | `fn :: x509 empty cert` | `X509Cert` |
| `442` | `fn :: x509 parse cert tbs Bool String Int Int Int Int Int Int Int` | `Bool X509Cert` |
| `443` | `fn :: x509 parse cert outer Bool String Int` | `Bool X509Cert` |
| `444` | `fn :: x509 parse cert String` | `Bool X509Cert` |
| `445` | `fn :: x509 ascii lower char Int` | `String` |
| `446` | `fn :: x509 to lower loop String Int Int String` | `String` |
| `447` | `fn :: x509 to lower String` | `String` |
| `448` | `fn :: x509 count dots loop String Int Int Int` | `Int` |
| `449` | `fn :: x509 first dot String Int Int` | `Int` |
| `450` | `fn :: x509 match single san inner String String` | `Bool` |
| `451` | `fn :: x509 match single san String String` | `Bool` |
| `452` | `fn :: x509 match san list [String] String` | `Bool` |
| `453` | `fn :: x509 match hostname X509Cert String` | `Bool` |
| `454` | `fn :: x509 verify signature String String String String String String` | `Bool` |
| `455` | `fn :: x509 verify cert sig X509Cert X509Cert` | `Bool` |

---

## 24.3. Djupdykning i `crypto`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `crypto` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test crypto.ridgun`.

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

Varje funktion i lib:en `crypto` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 38 libs i `ridgun-libs`:

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
        -- 1. Raw byte_str lengths, wraparound normalization, and full 0..255 round-trip
        str len (byte str 0) -> assert int equals 1 "len byte_str 0"
        str len (byte str 127) -> assert int equals 1 "len byte_str 127"
        str len (byte str 128) -> assert int equals 1 "len byte_str 128"
        str len (byte str 255) -> assert int equals 1 "len byte_str 255"
        byte str (0 - 1) -> assert str eq (byte str 255) "byte_str -1 wraps to 255"
        byte str 256 -> assert str eq (byte str 0) "byte_str 256 wraps to 0"
        b5   = bytes from list [0, 1, 127, 128, 255]
        str len b5 -> assert int equals 5 "len b5 == 5"
        rt   = bytes to list b5
        nth of rt 0 -> assert int equals 0 "rt 0"
        nth of rt 1 -> assert int equals 1 "rt 1"
        nth of rt 2 -> assert int equals 127 "rt 2"
        nth of rt 3 -> assert int equals 128 "rt 3"
        nth of rt 4 -> assert int equals 255 "rt 4"
        b256 = bytes from list (range bytes 0 255)
        str len b256 -> assert int equals 256 "len b256 == 256"
        r256 = bytes to list b256
        int count r256 -> assert int equals 256 "r256 list len == 256"
        nth of r256 0 -> assert int equals 0 "r256[0] == 0"
        nth of r256 128 -> assert int equals 128 "r256[128] == 128"
        nth of r256 255 -> assert int equals 255 "r256[255] == 255"
        same ints r256 (range bytes 0 255) -> assert true "bytes to list (bytes from list 0..255) == 0..255"

        -- ADR-0010: bytes are built on Tensor[U8]; values outside 0..255 are taken modulo 256
        hi7  = [0, 7, 128, 200, 255, 192, 245]
        b7   = bytes from list hi7
        str len b7 -> assert int equals 7 "len bytes from list hi7 == 7"
        same ints (bytes to list b7) hi7 -> assert true "bytes from list [0, 7, 128, 200, 255, 192, 245] round-trips"
        all byte str len one 0 -> assert true "str len (byte str n) == 1 for all n in 0..255"
        bytes from list [256, 0 - 1, 300, 0 - 256] -> assert str eq (bytes from list [0, 255, 44, 0]) "bytes from list wraps modulo 256"
        bytes from list [] -> assert str eq "" "bytes from list [] is empty"
        bytes to hex str (bytes from list hi7) -> assert str eq "000780c8ffc0f5" "bytes to hex str"
        bytes list to hex (hex str to bytes "000780c8ffc0f5") -> assert str eq "000780c8ffc0f5" "hex str to bytes Tensor[U8] round-trip"
        bytes to hex str (bitxor byte strings (hex to byte str "ff00f0") (hex to byte str "0f0fff")) -> assert str eq "f00f0f" "bitxor byte strings"
        bytes to hex str (byte slice b7 2 5) -> assert str eq "80c8ff" "byte slice keeps high bytes"

        -- 2. RGF-019 32-bit unsigned bitwise operations and boundary shifts
        band 4294967295 255 -> assert int equals 255 "band"
        band 305419896 0 -> assert int equals 0 "band with 0"
        bor 240 15 -> assert int equals 255 "bor"
        bor 305419896 0 -> assert int equals 305419896 "bor with 0"
        bxor 305419896 4294967295 -> assert int equals 3989547399 "bxor"
        bxor 305419896 305419896 -> assert int equals 0 "bxor self == 0"
        shl 1 0 -> assert int equals 1 "shl 0"
        shl 1 (0 - 1) -> assert int equals 0 "shl negative shift"
        shl 1 31 -> assert int equals 2147483648 "shl 31"
        shl 1 32 -> assert int equals 0 "shl 32"
        shr 2147483648 0 -> assert int equals 2147483648 "shr 0"
        shr 2147483648 (0 - 1) -> assert int equals 0 "shr negative shift"
        shr 2147483648 31 -> assert int equals 1 "shr 31"
        shr 2147483648 32 -> assert int equals 0 "shr 32"
        ()
```

### 24.3.4. Exempel 4: Officiella testvektorer för SHA-256 (FIPS 180-4), HMAC-SHA-256 (RFC 4231), konstanttidslikhet (`ct equal`) och PBKDF2-HMAC-SHA-256 (RFC 6070)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test sha256 hmac and pbkdf2 => ()
      test sha256 hmac and pbkdf2 =
        -- 1. SHA-256 (empty string "" and "abc" -> FIPS 180-4 vectors)
        h_emp = sha256 hex ""
        h_emp -> assert str eq "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "sha256_hex empty"
        h_hex = sha256 hex "abc"
        h_hex -> assert str eq "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "sha256_hex abc"
        h_raw = sha256 bytes "abc"
        str len h_raw -> assert eq 32
        bytes to hex str h_raw -> assert str eq h_hex "sha256_bytes matches sha256_hex"

        -- 2. HMAC-SHA-256 (RFC 4231 Test Case 2 and >64-byte key reduction)
        mac   = hmac sha256 "Jefe" "what do ya want for nothing?"
        str len mac -> assert eq 32
        bytes to hex str mac -> assert str eq "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843" "RFC 4231 Test Case 2"
        long_k = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef_extra_key_bytes"
        mac_lk = hmac sha256 long_k "message"
        str len mac_lk -> assert eq 32
        ct equal mac_lk (hmac sha256 (sha256 bytes long_k) "message") -> assert true "HMAC >64B key hashed to 32B"

        -- 3. Constant-time comparison (`ct_equal`)
        ct equal "" "" -> assert true "ct_equal empty strings"
        ct equal mac mac -> assert true "ct_equal identical"
        ct equal mac (sha256 bytes "abc") -> assert false "ct_equal different 32B"
        ct equal "short" "longer" -> assert false "ct_equal different lengths"

        -- 4. PBKDF2-HMAC-SHA-256 (RFC 6070 c=1, c=2, multi-block dk_len=64, sub-block dk_len=16, invalid args)
        dk1   = pbkdf2 hmac sha256 "password" "salt" 1 32
        str len dk1 -> assert eq 32
        bytes to hex str dk1 -> assert str eq "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b" "RFC 6070 PBKDF2 c=1"
        dk2   = pbkdf2 hmac sha256 "password" "salt" 2 32
        bytes to hex str dk2 -> assert str eq "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43" "RFC 6070 PBKDF2 c=2"
        dk16  = pbkdf2 hmac sha256 "password" "salt" 1 16
        str len dk16 -> assert eq 16
        bytes to hex str dk16 -> assert str eq "120fb6cffcf8b32c43e7225256c4f837" "PBKDF2 16-byte prefix"
        dk64  = pbkdf2 hmac sha256 "password" "salt" 1 64
        str len dk64 -> assert eq 64
        byte slice dk64 0 32 -> assert str eq dk1 "PBKDF2 64-byte block 1 matches dk1"
        pbkdf2 hmac sha256 "password" "salt" 0 32 -> assert str eq "" "PBKDF2 iterations=0 rejected"
        pbkdf2 hmac sha256 "password" "salt" 1 0 -> assert str eq "" "PBKDF2 dk_len=0 rejected"
        ()
```

### 24.3.5. Exempel 5: 5-arguments Argon2id-lösenordshashning (`argon2id hash`, `argon2id verify`) och minneshård verifiering (RFC 9106)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test argon2id five arg and perf => ()
      test argon2id five arg and perf =
        phc = argon2id hash "correct horse battery staple" "0123456789abcdef" 64 2 1
        str starts with phc "$argon2id$v=19$m=64,t=2,p=1$" -> assert true "PHC header format"
        argon2id verify "correct horse battery staple" phc -> assert true "argon2id_verify matching (pwd, phc)"
        argon2id verify "wrong password" phc -> assert false "argon2id_verify wrong password"
        argon2id verify "correct horse battery staple" "$argon2id$v=19$m=64,t=2,p=1$bad$bad" -> assert false "argon2id_verify bad PHC"

        -- Negative parameter guards for 5-arg argon2id_hash
        argon2id hash "password" "short" 64 2 1 -> assert str eq "" "salt < 8 bytes rejected"
        argon2id hash "password" "0123456789abcdef" 4 2 1 -> assert str eq "" "m_cost < 8*p rejected"
        argon2id hash "password" "0123456789abcdef" 64 0 1 -> assert str eq "" "t_cost < 1 rejected"
        argon2id hash "password" "0123456789abcdef" 64 2 0 -> assert str eq "" "p_cost < 1 rejected"

        -- RG-050 / RG-051: Verify 100% in-process pure-Ridgun Argon2id and PBKDF2-HMAC-SHA256
        -- (OpenSSL 3.5 / RFC 9106 vectors + 4096-iteration PBKDF2 vector)
        phc_s       = argon2id hash "correct horse" "saltsaltsaltsalt" 64 2 1
        argon_exact = phc_s == "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$5jdMIzWoFbzSOl6k3wai9uU3f8LD+HmGXQgo1uhHQPI"
        ok_s        = argon2id verify "correct horse" phc_s
        bad_s       = argon2id verify "wrong horse" phc_s
        bad_empty   = argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$"
        phc_ok      = str starts with phc_s "$argon2id$v=19$m=64,t=2,p=1$"
        pb4k        = bytes to hex str (pbkdf2 hmac sha256 "correct horse battery staple" "0123456789abcdef" 4096 32)
        ok_s -> assert true "Solstice RGF-015 argon_ok"
        bad_s -> assert false "Solstice RGF-015 argon_bad"
        bad_empty -> assert false "RG-051 reject PHC with empty tag"
        phc_ok -> assert true "Solstice RGF-015 phc prefix"
        argon_exact -> assert true "Solstice RGF-015 exact OpenSSL 3.5 / libsodium PHC"
        pb4k -> assert str eq "b87f4b27148d3b05ad7985e3df997f0d9afa6e768e6384555bab71ba10f0c1a5" "Solstice RGF-015 PBKDF2 4096"

        -- RG-043: PBKDF2-HMAC-SHA256 600,000 iterations must match Python hashlib and run in < 3500 ms on one core (down from 32,600 ms)
        t_pbk0      = sys monotonic ms
        pb600k      = bytes to hex str (pbkdf2 hmac sha256 "correct horse battery staple" "0123456789abcdef" 600000 32)
        dt_pbk      = (sys monotonic ms) - t_pbk0
        echo ("  [BENCH] PBKDF2 600,000 iterations: " + (int to str dt_pbk) + " ms")
        pb600k -> assert str eq "6c4a646aad10d067add5fb79d9078a16da83d50f81670a8e7593b249e6d94936" "RG-043: PBKDF2 600,000 iterations matches Python hashlib"
        dt_pbk < 3500 -> assert true ("RG-043: PBKDF2 600,000 iterations must complete in < 3500 ms (took " + (int to str dt_pbk) + " ms)")

        -- RG-060: Argon2id OWASP m=19456 KiB, t=2, p=1 must match OpenSSL 3.5.7 and run in < 14500 ms on one core
        t_a20       = sys monotonic ms
        phc_19m     = argon2id hash "correct horse battery staple" "0123456789abcdef" 19456 2 1
        dt_a2       = (sys monotonic ms) - t_a20
        echo ("  [BENCH] Argon2id m=19456, t=2, p=1: " + (int to str dt_a2) + " ms")
        phc_19m -> assert str eq "$argon2id$v=19$m=19456,t=2,p=1$MDEyMzQ1Njc4OWFiY2RlZg$gy5SuVm5Z7Vw7keB9se9p87QGcomaseB/S2U1OhTsM0" "RG-060: Argon2id m=19456,t=2,p=1 matches OpenSSL 3.5.7"
        dt_a2 < 14500 -> assert true ("RG-060: Argon2id m=19456, t=2, p=1 must complete in < 14500 ms (took " + (int to str dt_a2) + " ms)")
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
        str len sealed -> assert eq ((str len pt) + 16)

        -- Verify first 16 ciphertext bytes and 16-byte Poly1305 tag match RFC 8439 §2.8.2 bit-for-bit
        ct_prefix_hex = bytes to hex str (byte slice sealed 0 16)
        tag_hex       = bytes to hex str (byte slice sealed 114 130)
        ct_prefix_hex -> assert str eq "d31a8d34648e60db7b86afbc53ef7ec2" "RFC 8439 §2.8.2 ciphertext prefix"
        tag_hex -> assert str eq "1ae10b594f09e26a7e902ecbd0600691" "RFC 8439 §2.8.2 Poly1305 tag"

        -- Verify aead_open succeeds with (0, pt)
        res_ok   = aead open key nonce aad sealed
        aead rc res_ok -> assert eq 0
        aead pt res_ok -> assert str eq pt "aead_open decrypted plaintext"

        -- Verify empty plaintext and empty AAD round-trip
        sealed_empty = aead seal key nonce "" ""
        str len sealed_empty -> assert eq 16
        res_empty    = aead open key nonce "" sealed_empty
        aead rc res_empty -> assert eq 0
        aead pt res_empty -> assert str eq "" "aead_open empty plaintext"

        -- Verify tamper detection (-12 AUTH_FAILED) on modified AAD, modified nonce, modified ciphertext, or modified tag
        res_aad  = aead open key nonce "tampered-aad" sealed
        aead rc res_aad -> assert eq (0 - 12)
        aead pt res_aad -> assert str eq "" "tampered AAD returns empty plaintext"

        bad_nonce = bytes from list [8, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        res_nonce = aead open key bad_nonce aad sealed
        aead rc res_nonce -> assert eq (0 - 12)
        aead pt res_nonce -> assert str eq "" "tampered nonce returns empty plaintext"

        bad_ct   = (byte str 0) + (byte slice sealed 1 130)
        res_ct   = aead open key nonce aad bad_ct
        aead rc res_ct -> assert eq (0 - 12)
        aead pt res_ct -> assert str eq "" "tampered ciphertext byte returns empty plaintext"

        bad_seal = (byte slice sealed 0 129) + (byte str 0)
        res_tag  = aead open key nonce aad bad_seal
        aead rc res_tag -> assert eq (0 - 12)
        aead pt res_tag -> assert str eq "" "tampered tag returns empty plaintext"

        -- Verify invalid key/nonce/ciphertext length returns (-7, "") or ""
        aead seal "short-key" nonce aad pt -> assert str eq "" "aead_seal invalid key length"
        aead seal key "short-nonce" aad pt -> assert str eq "" "aead_seal invalid nonce length"
        res_inv  = aead open "short-key" nonce aad sealed
        aead rc res_inv -> assert eq (0 - 7)
        res_ninv = aead open key "short-nonce" aad sealed
        aead rc res_ninv -> assert eq (0 - 7)
        res_tinv = aead open key nonce aad "short-tag"
        aead rc res_tinv -> assert eq (0 - 7)
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

### 24.3.8. Exempel 8: FIPS 180-4 SHA-1-testvektorer och utfyllnadsgränser (`sha1 bytes`, `sha1 hex`)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test sha1 fips vectors => ()
      test sha1 fips vectors =
        -- FIPS 180-4 examples
        assert str eq (sha1 hex "") "da39a3ee5e6b4b0d3255bfef95601890afd80709" "SHA-1 empty" -> ()
        assert str eq (sha1 hex "abc") "a9993e364706816aba3e25717850c26c9cd0d89d" "SHA-1 abc" -> ()
        assert eq (str len (sha1 bytes "abc")) 20 -> ()
        assert str eq (bytes to hex str (sha1 bytes "abc")) (sha1 hex "abc") "sha1 bytes matches sha1 hex" -> ()
        assert str eq (sha1 hex "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") "84983e441c3bd26ebaae4aa1f95129e5e54670f1" "SHA-1 448-bit" -> ()
        assert str eq (sha1 hex "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") "a49b2446a02c645bf419f995b67091253a04a259" "SHA-1 896-bit" -> ()

        -- Padding boundaries: 55 bytes fit one block, 56 and 64 need two
        assert str eq (sha1 hex (a times 55 "")) "c1c8bbdc22796e28c0e15163d20899b65621d65a" "SHA-1 55 bytes" -> ()
        assert str eq (sha1 hex (a times 56 "")) "c2db330f6083854c99d4b5bfb6e8f29f201be699" "SHA-1 56 bytes" -> ()
        assert str eq (sha1 hex (a times 64 "")) "0098ba824b5c16427bd7a1122a5a442a25ec644d" "SHA-1 64 bytes" -> ()

        -- Every byte value, including NUL and bytes above 127
        assert str eq (sha1 hex (all bytes)) "4916d6bdb7f78e6803698cab32d1586ea457dfc8" "SHA-1 bytes 0..255" -> ()
        assert str eq (sha1 hex "The quick brown fox jumps over the lazy dog") "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12" "SHA-1 quick brown fox" -> ()

        -- One million "a" characters
        t0   = sys monotonic ms
        h1m  = sha1 hex (make a1m)
        dt1m = (sys monotonic ms) - t0
        echo ("  [BENCH] SHA-1 1,000,000 x 'a': " + (int to str dt1m) + " ms") -> ()
        assert str eq h1m "34aa973cd4c4daa4f61eeb2bdbad27316534016f" "SHA-1 1,000,000 'a'" -> ()
```

### 24.3.9. Exempel 9: FIPS 180-4 SHA-512-testvektorer (`sha512 bytes`, `sha512 hex`)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test sha512 fips vectors => ()
      test sha512 fips vectors =
        -- 1. Empty string ""
        h_emp = sha512 hex ""
        assert str eq h_emp "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" "SHA-512 empty" -> ()
        assert eq (str len (sha512 bytes "")) 64 -> ()

        -- 2. "abc"
        h_abc = sha512 hex "abc"
        assert str eq h_abc "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f" "SHA-512 abc" -> ()
        assert str eq (bytes to hex str (sha512 bytes "abc")) h_abc "sha512 bytes matches sha512 hex" -> ()

        -- 3. 448-bit message (56 bytes)
        m448  = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        assert str eq (sha512 hex m448) "204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445" "SHA-512 448-bit" -> ()

        -- 4. 896-bit message (112 bytes, spans two 1024-bit blocks with padding)
        m896  = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
        assert str eq (sha512 hex m896) "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909" "SHA-512 896-bit" -> ()

        -- 5. One million "a" characters
        t0    = sys monotonic ms
        h1m   = sha512 hex (make a1m)
        dt1m  = (sys monotonic ms) - t0
        echo ("  [BENCH] SHA-512 1,000,000 x 'a': " + (int to str dt1m) + " ms") -> ()
        assert str eq h1m "e718483d0ce769644e2e42c7bc15b4638e1f98b13b2044285632a803afa973ebde0ff244877ea60a4cb0432ce577c31beb009c5c2c49aa2e4eadb217ad8cc09b" "SHA-512 1,000,000 'a'" -> ()
```

### 24.3.10. Exempel 10: RFC 8032 Ed25519-testvektorer och avvisning av formbara eller ogiltiga signaturer

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test ed25519 rfc8032 vectors and negatives => ()
      test ed25519 rfc8032 vectors and negatives =
        -- RFC 8032 §7.1 TEST 1 (empty message "")
        t_ed0  = sys monotonic ms
        sk1    = hex to byte str "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"
        pk1    = ed25519 public key sk1
        sig1   = ed25519 sign sk1 ""
        ok1    = ed25519 verify pk1 "" sig1
        dt_ed  = (sys monotonic ms) - t_ed0
        echo ("  [BENCH] Ed25519 pubkey + sign + verify: " + (int to str dt_ed) + " ms") -> ()
        assert str eq (bytes to hex str pk1) "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a" "RFC 8032 Test 1 pubkey" -> ()
        assert str eq (bytes to hex str sig1) "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b" "RFC 8032 Test 1 sig" -> ()
        assert true ok1 "RFC 8032 Test 1 verify" -> ()
        assert true (dt_ed < 1000) "Ed25519 sign+verify under 1000 ms" -> ()

        -- RFC 8032 §7.1 TEST 2 (1-byte message 0x72)
        sk2    = hex to byte str "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb"
        pk2    = ed25519 public key sk2
        m2     = hex to byte str "72"
        sig2   = ed25519 sign sk2 m2
        assert str eq (bytes to hex str pk2) "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c" "RFC 8032 Test 2 pubkey" -> ()
        assert str eq (bytes to hex str sig2) "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00" "RFC 8032 Test 2 sig" -> ()
        assert true (ed25519 verify pk2 m2 sig2) "RFC 8032 Test 2 verify" -> ()

        -- RFC 8032 §7.1 TEST 3 (2-byte message 0xaf82)
        sk3    = hex to byte str "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7"
        pk3    = ed25519 public key sk3
        m3     = hex to byte str "af82"
        sig3   = ed25519 sign sk3 m3
        assert str eq (bytes to hex str pk3) "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025" "RFC 8032 Test 3 pubkey" -> ()
        assert str eq (bytes to hex str sig3) "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a" "RFC 8032 Test 3 sig" -> ()
        assert true (ed25519 verify pk3 m3 sig3) "RFC 8032 Test 3 verify" -> ()

        -- RFC 8032 §7.1 TEST 1024 (1023-byte message)
        sk4    = hex to byte str "f5e5767cf153319517630f226876b86c8160cc583bc013744c6bf255f5cc0ee5"
        pk4    = ed25519 public key sk4
        m4     = hex to byte str (t4 msg hex)
        sig4   = ed25519 sign sk4 m4
        assert eq (str len m4) 1023 -> ()
        assert str eq (bytes to hex str pk4) "278117fc144c72340f67d0f2316e8386ceffbf2b2428c9c51fef7c597f1d426e" "RFC 8032 Test 1024 pubkey" -> ()
        assert str eq (bytes to hex str sig4) "0aab4c900501b3e24d7cdf4663326a3a87df5e4843b2cbdb67cbf6e460fec350aa5371b1508f9f4528ecea23c436d94b5e8fcd4f681e30a6ac00a9704a188a03" "RFC 8032 Test 1024 sig" -> ()
        assert true (ed25519 verify pk4 m4 sig4) "RFC 8032 Test 1024 verify" -> ()

        -- RFC 8032 §7.1 TEST SHA(abc) (64-byte SHA-512("abc") message)
        sk5    = hex to byte str "833fe62409237b9d62ec77587520911e9a759cec1d19755b7da901b96dca3d42"
        pk5    = ed25519 public key sk5
        m5     = sha512 bytes "abc"
        sig5   = ed25519 sign sk5 m5
        assert str eq (bytes to hex str pk5) "ec172b93ad5e563bf4932c70e1245034c35467ef2efd4d64ebf819683467e2bf" "RFC 8032 Test SHA(abc) pubkey" -> ()
        assert str eq (bytes to hex str sig5) "dc2a4459e7369633a52b1bf277839a00201009a3efbf3ecb69bea2186c26b58909351fc9ac90b3ecfdfbc7c66431e0303dca179c138ac17ad9bef1177331a704" "RFC 8032 Test SHA(abc) sig" -> ()
        assert true (ed25519 verify pk5 m5 sig5) "RFC 8032 Test SHA(abc) verify" -> ()

        -- Negative cases: flipped bits in message, R, S, and public key
        assert false (ed25519 verify pk3 (hex to byte str "ae82") sig3) "Flipped bit in message rejected" -> ()
        bad_r  = (byte str (byte bxor (norm byte (str char at sig3 0)) 1)) + (byte slice sig3 1 64)
        assert false (ed25519 verify pk3 m3 bad_r) "Flipped bit in R rejected" -> ()
        bad_s  = (byte slice sig3 0 32) + (byte str (byte bxor (norm byte (str char at sig3 32)) 1)) + (byte slice sig3 33 64)
        assert false (ed25519 verify pk3 m3 bad_s) "Flipped bit in S rejected" -> ()
        bad_pk = (byte str (byte bxor (norm byte (str char at pk3 0)) 1)) + (byte slice pk3 1 32)
        assert false (ed25519 verify bad_pk m3 sig3) "Flipped bit in pubkey rejected" -> ()

        -- Negative cases: S = L and S = L + 1 (malleability check S >= L)
        l_le   = hex to byte str "edd3f55c1a631258d69cf7a2def9de1400000000000000000000000000000010"
        lp1_le = hex to byte str "eed3f55c1a631258d69cf7a2def9de1400000000000000000000000000000010"
        assert false (ed25519 verify pk1 "" ((byte slice sig1 0 32) + l_le)) "S == L rejected" -> ()
        assert false (ed25519 verify pk1 "" ((byte slice sig1 0 32) + lp1_le)) "S == L + 1 rejected" -> ()

        -- Negative cases: non-canonical y = p (2^255 - 19) and non-curve point (y = 2)
        y_eq_p = hex to byte str "edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
        y_eq_2 = hex to byte str "0200000000000000000000000000000000000000000000000000000000000000"
        assert false (ed25519 verify y_eq_p "" sig1) "Non-canonical y == p pubkey rejected" -> ()
        assert false (ed25519 verify y_eq_2 "" sig1) "Non-curve point y == 2 pubkey rejected" -> ()
        assert false (ed25519 verify pk1 "" (y_eq_2 + (byte slice sig1 32 64))) "Non-curve point R rejected" -> ()

        -- Negative cases: invalid lengths
        assert str eq (ed25519 public key "short") "" "short seed pubkey returns empty" -> ()
        assert str eq (ed25519 sign "short" "msg") "" "short seed sign returns empty" -> ()
        assert false (ed25519 verify "short" "" sig1) "short pubkey verify returns False" -> ()
        assert false (ed25519 verify pk1 "" "short") "short sig verify returns False" -> ()
```

### 24.3.11. Exempel 11: Publika nycklar och signaturer för Minisign: rundresa och upptäckt av manipulering

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test minisign roundtrip and tamper => ()
      test minisign roundtrip and tamper =
        seed   = hex to byte str "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"
        pk     = ed25519 public key seed
        kid    = "01234567"
        pk_b64 = minisign encode pubkey kid pk
        assert true ((str len pk_b64) == 56) "minisign encoded pubkey is 56 chars" -> ()

        dec1   = minisign decode pubkey pk_b64
        assert str eq (ms kid dec1) kid "minisign decode 1-line key_id" -> ()
        assert str eq (ms pk dec1) pk "minisign decode 1-line pubkey" -> ()

        pub_2l = "untrusted comment: ridgun release key\n" + pk_b64 + "\n"
        dec2   = minisign decode pubkey pub_2l
        assert str eq (ms kid dec2) kid "minisign decode 2-line key_id" -> ()
        assert str eq (ms pk dec2) pk "minisign decode 2-line pubkey" -> ()

        msg    = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ridgun-v0.9.21-linux-x86_64.tar.gz\n"
        tc     = "timestamp:1761667200\tfile:SHA256SUMS"
        msig   = minisign sign seed kid msg "signature from ridgun secret key" tc
        assert str eq (minisign trusted comment msig) tc "minisign trusted comment extracted" -> ()
        assert true (minisign verify pub_2l msg msig) "minisign verify valid signature" -> ()
        assert true (minisign verify pk_b64 msg msig) "minisign verify valid with 1-line pubkey" -> ()

        -- Tampered payload rejected
        assert false (minisign verify pub_2l (msg + "x") msig) "minisign verify rejects tampered payload" -> ()

        -- Tampered trusted comment rejected even though payload signature is intact
        msig_bad_tc = minisign sign seed kid msg "signature from ridgun secret key" "timestamp:9999999999\tfile:EVIL"
        lines_good  = c split lines msig
        lines_bad   = c split lines msig_bad_tc
        forged_msig = (c nth str lines_good 0) + "\n" + (c nth str lines_good 1) + "\n" + (c nth str lines_bad 2) + "\n" + (c nth str lines_good 3) + "\n"
        assert false (minisign verify pub_2l msg forged_msig) "minisign verify rejects tampered trusted comment" -> ()

        -- Wrong key_id rejected
        other_pub = minisign encode pubkey "76543210" pk
        assert false (minisign verify other_pub msg msig) "minisign verify rejects mismatched key_id" -> ()
```

### 24.3.12. Exempel 12: HMAC-SHA-384, HKDF (RFC 5869), X25519 (RFC 7748) och AES-128-GCM (NIST SP 800-38D)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test sha384 hkdf x25519 aes128gcm => ()
      test sha384 hkdf x25519 aes128gcm =
        -- 1. SHA-384 & HMAC-SHA-384 (FIPS 180-4 & RFC 4231 TC2)
        h384_emp = sha384 hex ""
        assert str eq h384_emp "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b" "SHA-384 empty" -> ()
        h384_abc = sha384 hex "abc"
        assert str eq h384_abc "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7" "SHA-384 abc" -> ()
        assert eq (str len (sha384 bytes "abc")) 48 -> ()
        mac384   = hmac sha384 "Jefe" "what do ya want for nothing?"
        assert str eq (bytes to hex str mac384) "af45d2e376484031617f78d2b58a6b1b9c7ef464f5a01b47e42ec3736322445e8e2240ca5e69e2c78b3239ecfab21649" "RFC 4231 TC2 HMAC-SHA-384" -> ()

        -- 2. HKDF-SHA-256 (RFC 5869 Appendix A Test Case 1) & TLS 1.3 Derive-Secret (RFC 8448 §3)
        ikm1 = hex to byte str "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"
        slt1 = hex to byte str "000102030405060708090a0b0c"
        inf1 = hex to byte str "f0f1f2f3f4f5f6f7f8f9"
        prk1 = hkdf extract slt1 ikm1
        okm1 = hkdf expand prk1 inf1 42
        assert str eq (bytes to hex str prk1) "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5" "RFC 5869 TC1 PRK" -> ()
        assert str eq (bytes to hex str okm1) "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865" "RFC 5869 TC1 OKM" -> ()
        early_sec = hkdf extract "" (c repeat byte 0 32)
        assert str eq (bytes to hex str early_sec) "33ad0a1c607ec03b09e6cd9893680ce210adf300aa1f2660e1b22e10f170f92a" "RFC 8448 Early Secret" -> ()
        derived_s = derive secret early_sec "derived" ""
        assert str eq (bytes to hex str derived_s) "6f2615a108c702c5678f54fc9dbab69716c076189c48250cebeac3576c3611ba" "RFC 8448 Derived Secret" -> ()

        -- 3. RFC 7748 X25519 Test Vectors (§5.2 and §6.1 Alice/Bob DH)
        x_sc1  = hex to byte str "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4"
        x_u1   = hex to byte str "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c"
        x_out1 = x25519 x_sc1 x_u1
        assert str eq (bytes to hex str x_out1) "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552" "RFC 7748 §5.2 vector 1" -> ()
        a_priv = hex to byte str "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
        a_pub  = x25519 public key a_priv
        b_priv = hex to byte str "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"
        b_pub  = x25519 public key b_priv
        assert str eq (bytes to hex str a_pub) "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a" "RFC 7748 §6.1 Alice pubkey" -> ()
        assert str eq (bytes to hex str b_pub) "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f" "RFC 7748 §6.1 Bob pubkey" -> ()
        sh_ab  = x25519 a_priv b_pub
        sh_ba  = x25519 b_priv a_pub
        assert str eq (bytes to hex str sh_ab) "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742" "RFC 7748 §6.1 shared secret" -> ()
        assert str eq sh_ab sh_ba "X25519 Alice == Bob" -> ()
        assert str eq (x25519 a_priv (c repeat byte 0 32)) "" "X25519 rejects all-zero low-order point" -> ()

        -- 4. FIPS 197 AES-128 & NIST SP 800-38D AES-128-GCM
        aes_k   = hex to byte str "2b7e151628aed2a6abf7158809cf4f3c"
        aes_pt  = hex to byte str "3243f6a8885a308d313198a2e0370734"
        aes_ct  = aes128 block aes_k aes_pt
        assert str eq (bytes to hex str aes_ct) "3925841d02dc09fbdc118597196a0b32" "FIPS 197 Appendix B AES-128 block" -> ()

        gk1     = c repeat byte 0 16
        gn1     = c repeat byte 0 12
        g_seal1 = aes128 gcm seal gk1 gn1 "" ""
        assert str eq (bytes to hex str g_seal1) "58e2fccefa7e3061367f1d57a4e7455a" "NIST GCM Test Case 1 empty PT/AAD" -> ()
        g_seal2 = aes128 gcm seal gk1 gn1 "" (c repeat byte 0 16)
        assert str eq (bytes to hex str g_seal2) "0388dace60b6a392f328c2b971b2fe78ab6e47d42cec13bdf53a67b21257bddf" "NIST GCM Test Case 2 16B zero PT" -> ()
        g_open2 = aes128 gcm open gk1 gn1 "" g_seal2
        assert eq (aead rc g_open2) 0 -> ()
        assert str eq (aead pt g_open2) (c repeat byte 0 16) "AES-128-GCM open TC2" -> ()

        -- Tampered tag / AAD rejected with (-12, "")
        g_bad_aad = aes128 gcm open gk1 gn1 "wrong-aad" g_seal2
        assert eq (aead rc g_bad_aad) (0 - 12) -> ()
        assert str eq (aead pt g_bad_aad) "" "AES-128-GCM tampered AAD returns empty" -> ()
        g_bad_tag = aes128 gcm open gk1 gn1 "" ((byte slice g_seal2 0 31) + (byte str 0))
        assert eq (aead rc g_bad_tag) (0 - 12) -> ()
```

### 24.3.13. Exempel 13: ECDSA på P-256 och P-384, verifiering av RSA-signaturer och matchning av X.509-värdnamn (RFC 6125)

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test p256 p384 rsa and x509 => ()
      test p256 p384 rsa and x509 =
        -- 1. P-256 ECDHE & ECDSA P-256 / P-384 Verification
        sk256 = hex to byte str "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
        pk256 = p256 public key sk256
        assert str eq (bytes to hex str pk256) "0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299" "RFC 6979 P-256 pubkey" -> ()
        sk256_b = hex to byte str "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
        pk256_b = p256 public key sk256_b
        ecdh_ab = p256 ecdh sk256 pk256_b
        ecdh_ba = p256 ecdh sk256_b pk256
        assert eq (str len ecdh_ab) 32 -> ()
        assert str eq ecdh_ab ecdh_ba "P-256 ECDH Alice == Bob" -> ()
        assert str eq (p256 ecdh sk256 ((byte str 4) + (c repeat byte 0 64))) "" "P-256 ECDH rejects off-curve point" -> ()

        sig256 = hex to byte str "3045022057d754539de74a3c6ce2a8744b91c3f73001c733f3e20179f196819bab767e58022100dcd06a946d1b7e568d3ff29a46698e3fe49746f86811588354a4d2d43102d665"
        assert true (ecdsa p256 verify sha256 pk256 "sample" sig256) "ECDSA P-256 verify valid" -> ()
        assert false (ecdsa p256 verify sha256 pk256 "tampered" sig256) "ECDSA P-256 rejects tampered msg" -> ()

        pk384  = hex to byte str "04ec3a4e415b4e19a4568618029f427fa5da9a8bc4ae92e02e06aae5286b300c64def8f0ea9055866064a254515480bc138015d9b72d7d57244ea8ef9ac0c621896708a59367f9dfb9f54ca84b3f1c9db1288b231c3ae0d4fe7344fd2533264720"
        sig384 = hex to byte str "306502307cb9078a9a1ee3685d0eede601238685b0e0bb514de400f799b582a0455be88141853a4cb0284f9d7ed980ea4795126a023100a88ce84cce196de0d329328b915d442bb4f64f8020fc0c6d8337d9887dfabc787cca7eecd1a5661e6f6839df126e92f1"
        assert true (ecdsa p384 verify sha384 pk384 "sample" sig384) "ECDSA P-384 verify valid" -> ()
        assert false (ecdsa p384 verify sha384 pk384 "tampered" sig384) "ECDSA P-384 rejects tampered msg" -> ()

        -- 2. RSA-2048 PKCS#1 v1.5 and RSA-PSS Verification + < 2048-bit rejection
        rsa_n     = hex to byte str ("af2e53e5eec127b0965a32813c253b4513c21de33c05ddb775ae20c53a8cea9743c06a65b9bede2bdba5fb1d307bb91d6822d3750d0b0a7a55189a51c897912e" + "550bd4d6d0ee3a561cf4171b0e8229e346754fe9315b1ca397109a8973f3ad0c3474bbd78e62f745f1530a6a97d2d787fe42def67734aed9b19e05348805d74c" + "68583858b0a477af413a9f39c7f61b6a21b3dd53db9b7025ee4519813ec95e6f60cd35cdd67bc27f874558e55b9eb88008d424be1e92bb60e4fe582907b975b6" + "1a18f5ed1332746aeaf01023ab676cbf0f424783b9c4769a69f33c829a194cdb8313a16a768ef2b2b4a90dcc597fe2764783e4b24906f856eaf81b1fe9a0efbb")
        rsa_e     = hex to byte str "010001"
        rsa_pkcs1 = hex to byte str ("6bef0571302c2a2b4c82c4641140cc21823f643127c7fa60ba699901fe23032a7631276ac204314fde6f48586a417967cea5cbfe4d4b02b90acdfc611d5bba7e" + "b1625c3dfec8bb897c73bebf154f1dd79f236e1b62e6ae277d6ad7da32b9e470daa0acbed7b2ae3e247dc97e0cc8ebffd1ba16453fb2879401daf9fc12f766c0" + "9efec85dbcd778cad083d980d40bf8a3aeba6a5cd01b4d6334dbb25128abc6b04166c1307a82be8a327718cb3601d7bb79bc2e407fc0b43db3fe4545b5b503db" + "20aef99e875544301ac564ee95275ad19522d2344316da5ce082dbf1b70516a43e6f0be568d0de055e4ffa5ab13c3ab6feab85a00ce7af459324317078ccfc1c")
        rsa_pss   = hex to byte str ("5a2ab42312f8554944f88a34e57488750221776acf9b700f48b7e125dfae6f971f7650e18e47065d1c4c494df233fd4d80505fac99110eabee67fc9e9ca7b9e8" + "f4a26f5b677f4d9a05aea41a82301f649e635b63e7b8d944d3fd41c491d7c985ccc933715308b601e6006e6b7486b7c252bf5bafe2570469f51f3cbcfe332a96" + "8e4fd94f2b4d88b64aa994305bbf8fc039506b9efc9fe4791dcebc2d7c64776dfc64fe860f1cae8b4b962a371c6299fa79df3868666df62868e31e3bacf777b1" + "ee7b134e5ceb05ba70f2d260fe54e591bcecce083af82026da8ca9a64bc088ade262610bd9f7a19cff3e1f9bba3558811629a5163b775947a58fe3405ca2e1d2")
        assert true (rsa verify pkcs1 rsa_n rsa_e "sha256" "hello tls 1.3" rsa_pkcs1) "RSA-2048 PKCS#1 v1.5 valid" -> ()
        assert false (rsa verify pkcs1 rsa_n rsa_e "sha256" "wrong msg" rsa_pkcs1) "RSA-2048 PKCS#1 v1.5 rejects wrong msg" -> ()
        assert true (rsa verify pss rsa_n rsa_e "sha256" "hello tls 1.3" rsa_pss) "RSA-2048 PSS valid" -> ()
        assert false (rsa verify pss rsa_n rsa_e "sha256" "wrong msg" rsa_pss) "RSA-2048 PSS rejects wrong msg" -> ()
        assert false (rsa verify pkcs1 (byte slice rsa_n 0 128) rsa_e "sha256" "hello tls 1.3" (byte slice rsa_pkcs1 0 128)) "RSA < 2048 bits rejected" -> ()

        -- 3. PEM, ASN.1 DER, X.509 v3 Certificate Parsing, RFC 6125 SAN Matching & Signature Verification
        cert_pem = "-----BEGIN CERTIFICATE-----\n" + "MIIBezCCASGgAwIBAgICA+kwCgYIKoZIzj0EAwIwFjEUMBIGA1UEAwwLZXhhbXBs\n" + "ZS5jb20wHhcNMjUwMTAxMDAwMDAwWhcNMzAwMTAxMDAwMDAwWjAWMRQwEgYDVQQD\n" + "DAtleGFtcGxlLmNvbTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABGD+1LolWp0x\n" + "yWHrdMY1bWjASbiSO2H6bOZpYi5g8p+2eQP+EAi4vJmkGunpVii8ZPLxsgwtfp9R\n" + "d6PClNRGIpmjXzBdMCUGA1UdEQQeMByCDSouZXhhbXBsZS5jb22CC2V4YW1wbGUu\n" + "b3JnMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgKEMBMGA1UdJQQMMAoG\n" + "CCsGAQUFBwMBMAoGCCqGSM49BAMCA0gAMEUCIQCVhHPDc7KdyWWTnxAvfq/cVF1z\n" + "uCcPqO/wDbrwbY72awIgPq5F1Ab9+6ax8pFdr0ryT/h+n6znJEDCfjtZvnzE2wI=\n" + "-----END CERTIFICATE-----\n"
        ders     = pem decode blocks cert_pem "CERTIFICATE"
        assert eq (c str list len ders 0) 1 -> ()
        ok_c, cert = x509 parse cert (c nth str ders 0)
        assert true ok_c "x509 parse cert succeeds" -> ()
        assert str eq (subject_cn cert) "example.com" "X.509 subject CN" -> ()
        assert str eq (key_alg cert) "ec_p256" "X.509 SPKI key_alg" -> ()
        assert str eq (sig_alg cert) "ecdsa_sha256" "X.509 sig_alg" -> ()
        assert true (is_ca cert) "X.509 basicConstraints CA=TRUE" -> ()
        assert true (has_server_auth cert) "X.509 EKU serverAuth" -> ()
        assert eq (not_before_at cert) 1735689600 -> ()
        assert eq (not_after_at cert) 1893456000 -> ()
        assert true (x509 match hostname cert "api.example.com") "RFC 6125 wildcard matches leftmost label" -> ()
        assert true (x509 match hostname cert "example.org") "RFC 6125 exact SAN match" -> ()
        assert false (x509 match hostname cert "sub.api.example.com") "RFC 6125 wildcard rejects multi-label prefix" -> ()
        assert false (x509 match hostname cert "example.com") "RFC 6125 wildcard does not match bare apex" -> ()
        assert false (x509 match single san "a.*.example.com" "a.b.example.com") "RFC 6125 rejects non-leftmost wildcard" -> ()
        assert false (x509 match single san "*.com" "example.com") "RFC 6125 rejects top-level wildcard" -> ()
        assert true (x509 verify cert sig cert cert) "X.509 self-signed signature verified" -> ()
```

### 24.3.14. Exempel 14: Gränsfall: felaktiga nyckellängder, manipulerade taggar, RSA PKCS#1 v1.5 och PSS samt riktiga certifikat

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test crypto006 edge cases and certs => ()
      test crypto006 edge cases and certs =
        -- 1. X25519 rejects wrong input lengths (AC2)
        x_k = hex to byte str "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
        assert str eq (x25519 (byte slice x_k 0 31) (c repeat byte 9 32)) "" "X25519 rejects 31-byte scalar" -> ()
        assert str eq (x25519 x_k (c repeat byte 9 33)) "" "X25519 rejects 33-byte u-coordinate" -> ()
        assert str eq (x25519 public key (byte slice x_k 0 16)) "" "X25519 public key rejects 16-byte scalar" -> ()

        -- 2. NIST SP 800-38D AES-128-GCM Test Cases 3 and 4 (AC3)
        gk3  = hex to byte str "feffe9928665731c6d6a8f9467308308"
        gn3  = hex to byte str "cafebabefacedbaddecaf888"
        gp3  = hex to byte str ("d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72" + "1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255")
        gs3  = aes128 gcm seal gk3 gn3 "" gp3
        assert str eq (bytes to hex str gs3) ("42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e" + "21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985" + "4d5c2af327cd64a62cf35abd2ba6fab4") "NIST GCM Test Case 3" -> ()
        gp4  = byte slice gp3 0 60
        ga4  = hex to byte str "feedfacedeadbeeffeedfacedeadbeefabaddad2"
        gs4  = aes128 gcm seal gk3 gn3 ga4 gp4
        assert str eq (bytes to hex str gs4) ("42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e" + "21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091" + "5bc94fbc3221a5db94fae95ae7121a47") "NIST GCM Test Case 4 with AAD" -> ()
        go4  = aes128 gcm open gk3 gn3 ga4 gs4
        assert eq (aead rc go4) 0 -> ()
        assert str eq (aead pt go4) gp4 "AES-128-GCM open TC4" -> ()
        gbad = (byte str 1) + (byte slice gs4 1 (str len gs4))
        assert eq (aead rc (aes128 gcm open gk3 gn3 ga4 gbad)) (0 - 12) -> ()
        assert eq (aead rc (aes128 gcm open (byte slice gk3 0 15) gn3 ga4 gs4)) (0 - 7) -> ()

        -- 3. ECDSA P-256 raw r || s signature and tampered signature (AC4)
        sk_e  = hex to byte str "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
        pk_e  = p256 public key sk_e
        raw_e = hex to byte str ("57d754539de74a3c6ce2a8744b91c3f73001c733f3e20179f196819bab767e58" + "dcd06a946d1b7e568d3ff29a46698e3fe49746f86811588354a4d2d43102d665")
        assert true (ecdsa p256 verify sha256 pk_e "sample" raw_e) "ECDSA P-256 raw r||s valid" -> ()
        bad_e = (byte slice raw_e 0 63) + (byte str 0)
        assert false (ecdsa p256 verify sha256 pk_e "sample" bad_e) "ECDSA P-256 rejects tampered signature" -> ()

        -- 4. RSA-2048 PKCS#1 v1.5 SHA-384/SHA-512 and RSA-PSS SHA-384 (AC5)
        rk_n = hex to byte str ("c602350d97a36b3342f59b62741c4657de7edb6e7095733a548eeef5c3e99244df3ae1712743860e457eaf4e3bbccdab5b75713b49cdba1927010da595809151" + "0f9f2ff87c0e01868b51dfb47a08fda7df71f4917870444e7485368d202824d76668e50e55fe43135f681ab7a41cc84eef2dee276997ef324b9267bfb1a83f8f" + "a8f209bb42928d74435073e9f5a3eb27925aa7306744bc3b8a3f34a6b78b5f945c3aa5e0d5907f60666fdeca9524f3be2a9963128e92bff579953b6b6acfeeb5" + "fc361b64a46fe8310731d69d531899744ef905024030c860793440c7e6a8f4ad5da70508d90b1505b3b30e27f77cabfe47794909bd44cf0af57358fbe280f9d1")
        rk_e = hex to byte str "010001"
        s512 = hex to byte str ("5af14292d1d30acb0104b64ea57b31266c8f58307b92d2a3abb80ef66696cd29b59654b72de41e2559f58fcf033ec070246655fdfb339bb61a5e99b76789ed56" + "297fbbfe0285920d57a5f74f500000698e6a9f75a8e7cdc7544ac2e333daf8783246b8f54a3cb87f20847770987719f9eb4a2c46e7afd1da8a69524e80dfb984" + "8e8547d4e356a16821e80f88a3ebd48e78d96a29a7f06de6f8884d24d8a24c9601aeb421493c97a1605f05b32fd351c378b51e8ed38defbd50e1c0020d2aa340" + "7c13db18ebc2422096e4063c111e6a082b7175e26fd9fbc238a67af8e01c1803bcd8cf7294e916031f64e68ea5f6b05e88b3c576ec6a341229e39b0c053e7ccd")
        s384 = hex to byte str ("2d7b014c1227bb49f5bb69495278e6829f44cb2364170ee2b0975c65d59674cd31121bb4a096a99567e01af26c6add5783dff2e0c6b9d6c05b4a6f643c6b3f0a" + "9f3f82bd7ba1eb4757dbe53359006dfeb4a65346ce6ee10bd62ed3a75c04b59f325efe322896246b49e3b38ab6b0a72930682e0f9f556c037a9cc6df1cfed339" + "518bb33ffa00a5f4569a0493c1e9060b7ffb1c570641428f690eecaa959fddfdfb0e53ba6d18a7a124047063a60d462e48f16a19724d3c866476ef9005259375" + "aded472bf9e0ed6107f7d34cd45ceeb78371b0dc17c1d3bcf147f2f85d1a48ac1dc489fe2ce7e5c07680cfa56d760171fc5c19fd9b13f1a1fb5e14e51abb49b9")
        p384s = hex to byte str ("56377f9c6a7e58606912df904da1fba3a8c40e263bb2fde3c303210e5c0e5426e9e70d5c593ecdef343d33b92eedb736e3c6c6461c0fbca4708a104d60c942d1" + "cf62eb69ec6d03bbf051b97e7d517af04f7b53b431e244abd5350a3e76bad74dd90b762ca20ad66e62b1e26b3ce2b77eb32b2d770fd5521eb0148664e420b2f9" + "588619f7d998c32221bc64b95b2e3c23022488600682d41392487fb6439779bf3f5ece2a8bc08d4414a843c703578bbdebad1efd72afe7f102e4025abeadfd73" + "8cf987392f123933d7fb1ac0a4723818d570aa1296e9dd36f9aeea56adbf72978cf886b6c2ee6c99829cde03f9f8f4d78dc146abdda631bb4555094289e1833e")
        assert true (rsa verify pkcs1 rk_n rk_e "sha512" "hello tls 1.2" s512) "RSA PKCS#1 v1.5 SHA-512 valid" -> ()
        assert true (rsa verify pkcs1 rk_n rk_e "sha384" "hello tls 1.2" s384) "RSA PKCS#1 v1.5 SHA-384 valid" -> ()
        assert false (rsa verify pkcs1 rk_n rk_e "sha384" "hello tls 1.2" s512) "RSA PKCS#1 v1.5 rejects hash mismatch" -> ()
        assert true (rsa verify pss rk_n rk_e "sha384" "hello tls 1.2" p384s) "RSA-PSS SHA-384 valid" -> ()
        bad_r = (byte slice s512 0 255) + (byte str 0)
        assert false (rsa verify pkcs1 rk_n rk_e "sha512" "hello tls 1.2" bad_r) "RSA PKCS#1 v1.5 rejects tampered signature" -> ()

        -- 5. X.509: RSA CA, P-384 and Ed25519 self-signed certs, CA-signed leaf (AC6)
        ca_pem = "-----BEGIN CERTIFICATE-----\n" + "MIICwDCCAaigAwIBAgIBATANBgkqhkiG9w0BAQwFADAZMRcwFQYDVQQDDA5SaWRn\n" + "dW4gVGVzdCBDQTAeFw0yNTAxMDEwMDAwMDBaFw0zMDAxMDEwMDAwMDBaMBkxFzAV\n" + "BgNVBAMMDlJpZGd1biBUZXN0IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB\n" + "CgKCAQEAxgI1DZejazNC9ZtidBxGV95+225wlXM6VI7u9cPpkkTfOuFxJ0OGDkV+\n" + "r047vM2rW3VxO0nNuhknAQ2llYCRUQ+fL/h8DgGGi1HftHoI/affcfSReHBETnSF\n" + "No0gKCTXZmjlDlX+QxNfaBq3pBzITu8t7idpl+8yS5Jnv7GoP4+o8gm7QpKNdENQ\n" + "c+n1o+snklqnMGdEvDuKPzSmt4tflFw6peDVkH9gZm/eypUk874qmWMSjpK/9XmV\n" + "O2tqz+61/DYbZKRv6DEHMdadUxiZdE75BQJAMMhgeTRAx+ao9K1dpwUI2QsVBbOz\n" + "Dif3fKv+R3lJCb1Ezwr1c1j74oD50QIDAQABoxMwETAPBgNVHRMBAf8EBTADAQH/\n" + "MA0GCSqGSIb3DQEBDAUAA4IBAQAGiAYEZCsQ72QJ5EvS1o8w5LZ4SoATUmaLnLSo\n" + "nWMzrsFjuLnB8mFIvM8Bd7n8Y8cC84fPFuaFWVntNmB+UdWr1eQCYsX0bFslgron\n" + "K5U9xKbF8nNjAzlQMKUYPceh/OOAyb20uTOMz4423q4hqpZG0Hmyn9UEgGTTyxOe\n" + "UYnFQ5l7ih6CJlb2wgsh2cvdESs0E5B3O6c+P9E3wp1n+8C+KxUSuxTeDLtnMswV\n" + "0aqP1FXVJ+C6NDGq9pXnD4BIRBiCK8bpp5YqM96htw5FBN7FMCtcJtBh1Lm06d/W\n" + "Tghqly2jDVSNwOlHWLUix/QKQ0AfOsIoOGmivs9wtFc4BIHP\n" + "-----END CERTIFICATE-----\n"
        p384_pem = "-----BEGIN CERTIFICATE-----\n" + "MIIBjzCCARWgAwIBAgIBAjAKBggqhkjOPQQDAzAUMRIwEAYDVQQDDAlwMzg0LnRl\n" + "c3QwHhcNMjUwMTAxMDAwMDAwWhcNMzAwMTAxMDAwMDAwWjAUMRIwEAYDVQQDDAlw\n" + "Mzg0LnRlc3QwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAQN7YsHxPPMDkG+FJ/BoQFZ\n" + "iM0A3NY5RbJbIXX/0iOyequPyOqu8Mly/SNQTHu9zUFezlNxroKowLvipPcCBqX0\n" + "Fh/dEuzKdIS3JYa+IZi7B8c9X08zDsYu9K6w4+tsQf+jOzA5MAwGA1UdEwEB/wQC\n" + "MAAwFAYDVR0RBA0wC4IJcDM4NC50ZXN0MBMGA1UdJQQMMAoGCCsGAQUFBwMBMAoG\n" + "CCqGSM49BAMDA2gAMGUCMQCzuFGZ+otJVilqEid6Cp2qm09R8/XAggZKv/BWdIkx\n" + "cytCxMqMgVMjLJai/L145HICMCTL6kr17XVpxIFgZJYVIW5gvHUH2/L/5qGirtxX\n" + "Mw5JE45iq16UnChyMmQoxYD9XA==\n" + "-----END CERTIFICATE-----\n"
        ed_pem = "-----BEGIN CERTIFICATE-----\n" + "MIIBCzCBvqADAgECAgEDMAUGAytlcDASMRAwDgYDVQQDDAdlZC50ZXN0MB4XDTI1\n" + "MDEwMTAwMDAwMFoXDTMwMDEwMTAwMDAwMFowEjEQMA4GA1UEAwwHZWQudGVzdDAq\n" + "MAUGAytlcAMhADwgYcwt5uAE05LKMMZaxPUqcfDkcYQrJSjFzrCAOQwaozkwNzAM\n" + "BgNVHRMBAf8EAjAAMBIGA1UdEQQLMAmCB2VkLnRlc3QwEwYDVR0lBAwwCgYIKwYB\n" + "BQUHAwEwBQYDK2VwA0EAt7s0zYTktgQRJv5qOSfzFieWxjGcTw8yV6vRfcaESdpa\n" + "ZhEnvm5qwFVC7LgK/rs0GLSccgBKGNPNV1hLFLxTBQ==\n" + "-----END CERTIFICATE-----\n"
        leaf_pem = "-----BEGIN CERTIFICATE-----\n" + "MIICQjCCASqgAwIBAgIBBDANBgkqhkiG9w0BAQsFADAZMRcwFQYDVQQDDA5SaWRn\n" + "dW4gVGVzdCBDQTAeFw0yNTAxMDEwMDAwMDBaFw0zMDAxMDEwMDAwMDBaMBQxEjAQ\n" + "BgNVBAMMCWxlYWYudGVzdDB2MBAGByqGSM49AgEGBSuBBAAiA2IABA3tiwfE88wO\n" + "Qb4Un8GhAVmIzQDc1jlFslshdf/SI7J6q4/I6q7wyXL9I1BMe73NQV7OU3GugqjA\n" + "u+Kk9wIGpfQWH90S7Mp0hLclhr4hmLsHxz1fTzMOxi70rrDj62xB/6NIMEYwDAYD\n" + "VR0TAQH/BAIwADAhBgNVHREEGjAYgglsZWFmLnRlc3SCCyoubGVhZi50ZXN0MBMG\n" + "A1UdJQQMMAoGCCsGAQUFBwMBMA0GCSqGSIb3DQEBCwUAA4IBAQBxD/RWuxNKchIB\n" + "j/IBryFHERjKQjUHOGbf/L+AWMgwbMsPSQPpLTZFNQa8222Dm0Jx958JJZ4vufSu\n" + "wNRvh2nFSQ9xg8KGWbdV6gmaI7eMz7kluu8RcHayhObhPyQccCHKGCgSjeIsndjD\n" + "Ezp/OqdfFpmNMDB1WyGNLzuNVupb62x3Q+9EXD4se/1w9sfePqZzRyyJ2duJ+Rc2\n" + "gbUueCot7UGAq7/z9wzg4ouIiXvW7SP+/p9NCtuEjN9X5+qybKTb+f8eKmkthywd\n" + "iPtPwwS1q+rGiPev69clnhkB03RLxQbDYWorYbOrqNy8/qVtAvTgMry8guQHRCnf\n" + "wZSHzFQS\n" + "-----END CERTIFICATE-----\n"
        ok_ca, ca_c = x509 parse cert (c nth str (pem decode blocks ca_pem "CERTIFICATE") 0)
        assert true ok_ca "x509 parse RSA CA" -> ()
        assert str eq (key_alg ca_c) "rsa" "RSA SPKI key_alg" -> ()
        assert str eq (bytes to hex str (pubkey_bytes ca_c)) "c602350d97a36b3342f59b62741c4657de7edb6e7095733a548eeef5c3e99244df3ae1712743860e457eaf4e3bbccdab5b75713b49cdba1927010da5958091510f9f2ff87c0e01868b51dfb47a08fda7df71f4917870444e7485368d202824d76668e50e55fe43135f681ab7a41cc84eef2dee276997ef324b9267bfb1a83f8fa8f209bb42928d74435073e9f5a3eb27925aa7306744bc3b8a3f34a6b78b5f945c3aa5e0d5907f60666fdeca9524f3be2a9963128e92bff579953b6b6acfeeb5fc361b64a46fe8310731d69d531899744ef905024030c860793440c7e6a8f4ad5da70508d90b1505b3b30e27f77cabfe47794909bd44cf0af57358fbe280f9d1" "RSA SPKI modulus" -> ()
        assert str eq (bytes to hex str (rsa_exp_bytes ca_c)) "010001" "RSA SPKI exponent" -> ()
        assert str eq (sig_alg ca_c) "rsa_pkcs1_sha384" "RSA CA sig_alg" -> ()
        assert true (is_ca ca_c) "RSA CA basicConstraints" -> ()
        assert true (x509 verify cert sig ca_c ca_c) "RSA CA self-signature" -> ()
        ok_p, p_c = x509 parse cert (c nth str (pem decode blocks p384_pem "CERTIFICATE") 0)
        assert true ok_p "x509 parse P-384 cert" -> ()
        assert str eq (key_alg p_c) "ec_p384" "P-384 SPKI key_alg" -> ()
        assert str eq (sig_alg p_c) "ecdsa_sha384" "P-384 sig_alg" -> ()
        assert false (is_ca p_c) "P-384 leaf is not CA" -> ()
        assert true (x509 verify cert sig p_c p_c) "P-384 self-signature" -> ()
        ok_d, d_c = x509 parse cert (c nth str (pem decode blocks ed_pem "CERTIFICATE") 0)
        assert true ok_d "x509 parse Ed25519 cert" -> ()
        assert str eq (key_alg d_c) "ed25519" "Ed25519 SPKI key_alg" -> ()
        assert eq (str len (pubkey_bytes d_c)) 32 -> ()
        assert true (x509 verify cert sig d_c d_c) "Ed25519 self-signature" -> ()
        ok_l, l_c = x509 parse cert (c nth str (pem decode blocks leaf_pem "CERTIFICATE") 0)
        assert true ok_l "x509 parse CA-signed leaf" -> ()
        assert str eq (issuer_cn l_c) "Ridgun Test CA" "leaf issuer CN" -> ()
        assert str eq (issuer_der l_c) (subject_der ca_c) "leaf issuer == CA subject" -> ()
        assert true (x509 verify cert sig l_c ca_c) "leaf signed by RSA CA" -> ()
        assert false (x509 verify cert sig l_c p_c) "leaf signature rejected with wrong issuer key" -> ()
        assert true (x509 match hostname l_c "www.leaf.test") "leaf wildcard SAN" -> ()
        assert false (x509 match hostname l_c "other.test") "leaf rejects unrelated host" -> ()
        assert eq (not_after_at l_c) 1893456000 -> ()
        two = pem decode blocks (ca_pem + leaf_pem) "CERTIFICATE"
        assert eq (c str list len two 0) 2 -> ()
```

### 24.3.15. Exempel 15: RFC 1321 MD5-testvektorer (`md5 bytes`, `md5 hex`) för protokoll som fortfarande anger den

I detta praktiska exempel undersöker vi grundligt hur `crypto` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test md5 rfc1321 vectors => ()
      test md5 rfc1321 vectors =
        md5 hex "" -> assert str eq "d41d8cd98f00b204e9800998ecf8427e" "MD5 empty"
        md5 hex "a" -> assert str eq "0cc175b9c0f1b6a831c399e269772661" "MD5 a"
        md5 hex "abc" -> assert str eq "900150983cd24fb0d6963f7d28e17f72" "MD5 abc"
        md5 hex "message digest" -> assert str eq "f96b697d7cb7938d525a2f31aaf161d0" "MD5 message digest"
        md5 hex "abcdefghijklmnopqrstuvwxyz" -> assert str eq "c3fcd3d76192e4007dfb496cca67e13b" "MD5 alphabet"
        md5 hex "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" -> assert str eq "d174ab98d277d9f5a5611c2c9f419d9f" "MD5 62 characters (two blocks)"
        md5 hex "12345678901234567890123456789012345678901234567890123456789012345678901234567890" -> assert str eq "57edf4a22be3c955ac49da2e2107b67a" "MD5 80 digits"
        bytes to hex str (md5 bytes "abc") -> assert str eq (md5 hex "abc") "md5 bytes matches md5 hex"
```

---

## 24.4. Under huven: hur `crypto` är byggd i ren Ridgun (`src/main/ridgun/lib/crypto.ridgun`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/crypto.ridgun` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 24.4.1. Intern implementation: RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`)

Se hur `crypto.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
        t     = Tensor[U8 * 1]
        t_(0) = ub and 255
        tensor to str t

fn :: byte str Int => String
      byte str n   =
        byte str norm (norm byte n)

fn :: c sb append3 String String => String String String String
      c sb append3 n2     c3     =
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
      c sb finish c0 c1 c2 c3 = ((c3 + c2) + c1) + c0

-- The tensor is bound to a name: with `_` ridgunc 0.9.49 binds a wrong `n`.
fn :: c u8 len Tensor[U8]          => Int
      c u8 len (Tensor[U8 * n] bs) =  n

fn :: c copy loop Tensor[U8] Int Tensor[U8] Int Int Int => Int
      c copy loop dst doff src soff i n =
        | i >= n    = doff + n
        | otherwise =
          dst_(doff + i) = src_(soff + i)
          c copy loop dst doff src soff (i + 1) n

-- Copies `n` bytes of `src` from `soff` into `dst` at `doff`; returns `doff + n`.
fn :: c copy bytes Tensor[U8] Int Tensor[U8] Int Int => Int
      c copy bytes dst doff src soff n =  c copy loop dst doff src soff 0 n

-- Writes `w` as 4 little-endian bytes at `off`; returns `off + 4`.
fn :: c put le32 Tensor[U8] Int Int => Int
      c put le32 t          off w   =
        uw          = w and 0xFFFFFFFF
        t_(off)     = uw and 255
        t_(off + 1) = (uw shr 8) and 255
        t_(off + 2) = (uw shr 16) and 255
        t_(off + 3) = (uw shr 24) and 255
        off + 4

fn :: bytes from list loop Tensor[U8] [Int]    Int => Tensor[U8]
      bytes from list loop t          []       _   =  t
      bytes from list loop t          (b:rest) i   =
        t_(i) = b and 255
        bytes from list loop t rest (i + 1)

-- Values outside 0..255 are taken modulo 256 (`norm byte`).
fn :: bytes from list [Int] => String
      bytes from list []    =  ""
      bytes from list bs    =
        n = c list len bs
        t = Tensor[U8 * n]
        tensor to str (bytes from list loop t bs 0)

fn :: bytes to list String => [Int]
      bytes to list s      =
        tensor to list (tensor from str s)
```

### 24.4.2. Intern implementation: RFC 8439 ChaCha20 Stream Cipher (`chacha20_block`, `chacha20_xor`)

Se hur `crypto.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: le32 at Tensor[U8] Int => Int
      le32 at bs         off =
        bs_(off) + (bs_(off + 1) * 256) + (bs_(off + 2) * 65536) + (bs_(off + 3) * 16777216)

-- Ten double rounds on n blocks at once: one tensor per state word (RFC 8439 §2.3).
-- Consecutive element-wise statements run as one loop, and the self call repeats it (FR-COMP-031).
fn :: chacha rounds Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Int => Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n]
      chacha rounds s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 k =
        | k <= 0 = (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15)
        | otherwise =
          s0v1 = s0_i + s4_i
          s12v1 = (s12_i xor s0v1_i) rotl 16
          s8v1 = s8_i + s12v1_i
          s4v1 = (s4_i xor s8v1_i) rotl 12
          s0v2 = s0v1_i + s4v1_i
          s12v2 = (s12v1_i xor s0v2_i) rotl 8
          s8v2 = s8v1_i + s12v2_i
          s4v2 = (s4v1_i xor s8v2_i) rotl 7
          s1v1 = s1_i + s5_i
          s13v1 = (s13_i xor s1v1_i) rotl 16
          s9v1 = s9_i + s13v1_i
          s5v1 = (s5_i xor s9v1_i) rotl 12
          s1v2 = s1v1_i + s5v1_i
          s13v2 = (s13v1_i xor s1v2_i) rotl 8
          s9v2 = s9v1_i + s13v2_i
          s5v2 = (s5v1_i xor s9v2_i) rotl 7
          s2v1 = s2_i + s6_i
          s14v1 = (s14_i xor s2v1_i) rotl 16
          s10v1 = s10_i + s14v1_i
          s6v1 = (s6_i xor s10v1_i) rotl 12
          s2v2 = s2v1_i + s6v1_i
          s14v2 = (s14v1_i xor s2v2_i) rotl 8
          s10v2 = s10v1_i + s14v2_i
          s6v2 = (s6v1_i xor s10v2_i) rotl 7
          s3v1 = s3_i + s7_i
          s15v1 = (s15_i xor s3v1_i) rotl 16
          s11v1 = s11_i + s15v1_i
          s7v1 = (s7_i xor s11v1_i) rotl 12
          s3v2 = s3v1_i + s7v1_i
          s15v2 = (s15v1_i xor s3v2_i) rotl 8
          s11v2 = s11v1_i + s15v2_i
          s7v2 = (s7v1_i xor s11v2_i) rotl 7
          s0v3 = s0v2_i + s5v2_i
          s15v3 = (s15v2_i xor s0v3_i) rotl 16
          s10v3 = s10v2_i + s15v3_i
          s5v3 = (s5v2_i xor s10v3_i) rotl 12
          s0v4 = s0v3_i + s5v3_i
          s15v4 = (s15v3_i xor s0v4_i) rotl 8
          s10v4 = s10v3_i + s15v4_i
          s5v4 = (s5v3_i xor s10v4_i) rotl 7
          s1v3 = s1v2_i + s6v2_i
          s12v3 = (s12v2_i xor s1v3_i) rotl 16
          s11v3 = s11v2_i + s12v3_i
          s6v3 = (s6v2_i xor s11v3_i) rotl 12
          s1v4 = s1v3_i + s6v3_i
          s12v4 = (s12v3_i xor s1v4_i) rotl 8
          s11v4 = s11v3_i + s12v4_i
          s6v4 = (s6v3_i xor s11v4_i) rotl 7
          s2v3 = s2v2_i + s7v2_i
          s13v3 = (s13v2_i xor s2v3_i) rotl 16
          s8v3 = s8v2_i + s13v3_i
          s7v3 = (s7v2_i xor s8v3_i) rotl 12
          s2v4 = s2v3_i + s7v3_i
          s13v4 = (s13v3_i xor s2v4_i) rotl 8
          s8v4 = s8v3_i + s13v4_i
          s7v4 = (s7v3_i xor s8v4_i) rotl 7
          s3v3 = s3v2_i + s4v2_i
          s14v3 = (s14v2_i xor s3v3_i) rotl 16
          s9v3 = s9v2_i + s14v3_i
          s4v3 = (s4v2_i xor s9v3_i) rotl 12
          s3v4 = s3v3_i + s4v3_i
          s14v4 = (s14v3_i xor s3v4_i) rotl 8
          s9v4 = s9v3_i + s14v4_i
          s4v4 = (s4v3_i xor s9v4_i) rotl 7
          chacha rounds s0v4 s1v4 s2v4 s3v4 s4v4 s5v4 s6v4 s7v4 s8v4 s9v4 s10v4 s11v4 s12v4 s13v4 s14v4 s15v4 (k - 1)

fn :: chacha fill counter Tensor[U32 * n] Int Int Int => Tensor[U32 * n]
      chacha fill counter t first i n =
        | i >= n    = t
        | otherwise =
          t_(i) = (first + i) and 0xFFFFFFFF
          chacha fill counter t first (i + 1) n

-- The key stream of `nb` blocks from block `ctr` on, as 16 tensors of `nb` words (word w of block b is o<w>_(b)).
fn :: chacha page Tensor[U8] Tensor[U8] Int Int => Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n]
      chacha page key_bs nonce_bs ctr nb =
        s0 = Tensor[U32 * nb] with 1634760805
        s1 = Tensor[U32 * nb] with 857760878
        s2 = Tensor[U32 * nb] with 2036477234
        s3 = Tensor[U32 * nb] with 1797285236
        s4 = Tensor[U32 * nb] with (le32 at key_bs 0)
        s5 = Tensor[U32 * nb] with (le32 at key_bs 4)
        s6 = Tensor[U32 * nb] with (le32 at key_bs 8)
        s7 = Tensor[U32 * nb] with (le32 at key_bs 12)
        s8 = Tensor[U32 * nb] with (le32 at key_bs 16)
        s9 = Tensor[U32 * nb] with (le32 at key_bs 20)
        s10 = Tensor[U32 * nb] with (le32 at key_bs 24)
        s11 = Tensor[U32 * nb] with (le32 at key_bs 28)
        s12 = chacha fill counter (Tensor[U32 * nb]) ctr 0 nb
        s13 = Tensor[U32 * nb] with (le32 at nonce_bs 0)
        s14 = Tensor[U32 * nb] with (le32 at nonce_bs 4)
        s15 = Tensor[U32 * nb] with (le32 at nonce_bs 8)
        w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15 = chacha rounds s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 10
        o0 = w0_i + s0_i
        o1 = w1_i + s1_i
        o2 = w2_i + s2_i
        o3 = w3_i + s3_i
        o4 = w4_i + s4_i
        o5 = w5_i + s5_i
        o6 = w6_i + s6_i
        o7 = w7_i + s7_i
        o8 = w8_i + s8_i
        o9 = w9_i + s9_i
        o10 = w10_i + s10_i
        o11 = w11_i + s11_i
        o12 = w12_i + s12_i
        o13 = w13_i + s13_i
        o14 = w14_i + s14_i
        o15 = w15_i + s15_i
        (o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15)

-- The first `n` bytes of `stream` (the key stream is made in whole blocks).
fn :: c first bytes Tensor[U8] Int Int => Tensor[U8]
      c first bytes stream have n =
        | have == n = stream
        | otherwise = tensor from str (byte slice (tensor to str stream) 0 n)

-- The first `n` bytes (at most 1 MiB) of the key stream from block `ctr` on: all the blocks at once,
-- then the 16 word tensors side by side and their bytes (ridgunc 1.0.40).
fn :: chacha20 key stream chunk Tensor[U8] Tensor[U8] Int Int => Tensor[U8]
      chacha20 key stream chunk key_bs nonce_bs ctr n =
        nb = (n + 63) / 64
        o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15 = chacha page key_bs nonce_bs ctr nb
        c first bytes (tensor bytes (tensor interleave [o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15])) (64 * nb) n

-- The first `n` bytes of the key stream from block `ctr` on, 1 MiB at a time.
fn :: chacha20 key stream Tensor[U8] Tensor[U8] Int Int => Tensor[U8]
      chacha20 key stream key_bs nonce_bs ctr n =
        | n <= 0       = Tensor[U8 * 0]
        | n <= 1048576 = chacha20 key stream chunk key_bs nonce_bs ctr n
        | otherwise    = tensor from str ((tensor to str (chacha20 key stream chunk key_bs nonce_bs ctr 1048576)) + (tensor to str (chacha20 key stream key_bs nonce_bs (ctr + 16384) (n - 1048576))))

-- The 64-byte keystream block `counter` (RFC 8439 §2.3).
fn :: chacha20 block Tensor[U8] Tensor[U8] Int => Tensor[U8]
      chacha20 block key_bs nonce_bs counter =  chacha20 key stream key_bs nonce_bs counter 64

fn :: c bitxor bytes Tensor[U8 * n] Tensor[U8 * n] => Tensor[U8 * n]
      c bitxor bytes a b =  a_i xor b_i

-- RFC 8439 §2.4 encryption: `msg` XOR the keystream from block `ctr` on.
fn :: chacha20 bitxor Tensor[U8] Tensor[U8] Int Tensor[U8] => Tensor[U8]
      chacha20 bitxor key_bs nonce_bs ctr msg =
        c bitxor bytes msg (chacha20 key stream key_bs nonce_bs ctr (c u8 len msg))
```

### 24.4.3. Intern implementation: RFC 8439 Poly1305 One-Time Authenticator (5 x 26-bit limbs)

Se hur `crypto.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
-- r = clamp(otk[0..16)) as 5 x 26-bit limbs (RFC 8439 §2.5.1 clamp as word masks).
fn :: poly1305 r limbs Tensor[U8] => Tensor[Int * 5]
      poly1305 r limbs otk        =
        t0    = (le32 at otk 0) and 0x0FFFFFFF
        t1    = (le32 at otk 4) and 0x0FFFFFFC
        t2    = (le32 at otk 8) and 0x0FFFFFFC
        t3    = (le32 at otk 12) and 0x0FFFFFFC
        r     = Tensor[Int * 5]
        r_(0) = t0 % 67108864
        r_(1) = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        r_(2) = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        r_(3) = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        r_(4) = t3 / 256
        r

-- h = (h + block) * r mod 2^130 - 5 for the full 16-byte block at `off`; updates `h` in place.
fn :: poly1305 step Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int => Tensor[Int * 5]
      poly1305 step h                r                msg        off =
        t0 = le32 at msg off
        t1 = le32 at msg (off + 4)
        t2 = le32 at msg (off + 8)
        t3 = le32 at msg (off + 12)
        h0 = h_(0) + (t0 % 67108864)
        h1 = h_(1) + (((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864)
        h2 = h_(2) + (((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864)
        h3 = h_(3) + (((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864)
        h4 = h_(4) + ((t3 / 256) + 16777216)
        r0 = r_(0)
        r1 = r_(1)
        r2 = r_(2)
        r3 = r_(3)
        r4 = r_(4)
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
        h_(0) = f0 % 67108864
        h_(1) = n1 + cf
        h_(2) = n2
        h_(3) = n3
        h_(4) = n4
        h

fn :: poly1305 blocks loop Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int Int => Tensor[Int * 5]
      poly1305 blocks loop h r msg off n =
        | off >= n  = h
        | otherwise = poly1305 blocks loop (poly1305 step h r msg off) r msg (off + 16) n

-- Poly1305 on n lanes, `k` steps in one loop: h = (h + block) * p, with the block of lane l read at byte lx_(l) + at of `msg`.
-- h and p are 5 limbs of 26 bits (one tensor per limb); s1..s4 = 5 * p1..p4. `at` moves 16 n bytes on at each step.
fn :: poly1305 lanes loop Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U8] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Int Int => Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n]
      poly1305 lanes loop h0 h1 h2 h3 h4 msg lx p0 p1 p2 p3 p4 s1 s2 s3 s4 at k =
        | k <= 0 = (h0, h1, h2, h3, h4)
        | otherwise =
          t0 = (((msg_(lx_i + at) as U64) + ((msg_((lx_i + at) + 1) as U64) shl 8)) + ((msg_((lx_i + at) + 2) as U64) shl 16)) + ((msg_((lx_i + at) + 3) as U64) shl 24)
          t1 = (((msg_((lx_i + at) + 4) as U64) + ((msg_((lx_i + at) + 5) as U64) shl 8)) + ((msg_((lx_i + at) + 6) as U64) shl 16)) + ((msg_((lx_i + at) + 7) as U64) shl 24)
          t2 = (((msg_((lx_i + at) + 8) as U64) + ((msg_((lx_i + at) + 9) as U64) shl 8)) + ((msg_((lx_i + at) + 10) as U64) shl 16)) + ((msg_((lx_i + at) + 11) as U64) shl 24)
          t3 = (((msg_((lx_i + at) + 12) as U64) + ((msg_((lx_i + at) + 13) as U64) shl 8)) + ((msg_((lx_i + at) + 14) as U64) shl 16)) + ((msg_((lx_i + at) + 15) as U64) shl 24)
          a0 = h0_i + (t0_i and 0x3FFFFFF)
          a1 = h1_i + (((t0_i shr 26) or (t1_i shl 6)) and 0x3FFFFFF)
          a2 = h2_i + (((t1_i shr 20) or (t2_i shl 12)) and 0x3FFFFFF)
          a3 = h3_i + (((t2_i shr 14) or (t3_i shl 18)) and 0x3FFFFFF)
          a4 = h4_i + ((t3_i shr 8) + 16777216)
          d0 = ((((a0_i * p0_i) + (a1_i * s4_i)) + (a2_i * s3_i)) + (a3_i * s2_i)) + (a4_i * s1_i)
          d1 = ((((a0_i * p1_i) + (a1_i * p0_i)) + (a2_i * s4_i)) + (a3_i * s3_i)) + (a4_i * s2_i)
          d2 = ((((a0_i * p2_i) + (a1_i * p1_i)) + (a2_i * p0_i)) + (a3_i * s4_i)) + (a4_i * s3_i)
          d3 = ((((a0_i * p3_i) + (a1_i * p2_i)) + (a2_i * p1_i)) + (a3_i * p0_i)) + (a4_i * s4_i)
          d4 = ((((a0_i * p4_i) + (a1_i * p3_i)) + (a2_i * p2_i)) + (a3_i * p1_i)) + (a4_i * p0_i)
          e1 = d1_i + (d0_i shr 26)
          e2 = d2_i + (e1_i shr 26)
          e3 = d3_i + (e2_i shr 26)
          e4 = d4_i + (e3_i shr 26)
          f0 = (d0_i and 0x3FFFFFF) + ((e4_i shr 26) * 5)
          g0 = f0_i and 0x3FFFFFF
          g1 = (e1_i and 0x3FFFFFF) + (f0_i shr 26)
          g2 = e2_i and 0x3FFFFFF
          g3 = e3_i and 0x3FFFFFF
          g4 = e4_i and 0x3FFFFFF
          poly1305 lanes loop g0 g1 g2 g3 g4 msg lx p0 p1 p2 p3 p4 s1 s2 s3 s4 (at + 512) (k - 1)

-- a * b mod 2^130 - 5 on 5 limbs of 26 bits; the result goes to `out` at limb `o`.
fn :: poly1305 mul into Tensor[Int * m] Int Tensor[Int * k] Int Tensor[Int * j] Int => Int
      poly1305 mul into a ao b bo out o =
        a0 = a_(ao)
        a1 = a_(ao + 1)
        a2 = a_(ao + 2)
        a3 = a_(ao + 3)
        a4 = a_(ao + 4)
        b0 = b_(bo)
        b1 = b_(bo + 1)
        b2 = b_(bo + 2)
        b3 = b_(bo + 3)
        b4 = b_(bo + 4)
        d0 = (a0 * b0) + (5 * ((a1 * b4) + (a2 * b3) + (a3 * b2) + (a4 * b1)))
        d1 = (a0 * b1) + (a1 * b0) + (5 * ((a2 * b4) + (a3 * b3) + (a4 * b2)))
        d2 = (a0 * b2) + (a1 * b1) + (a2 * b0) + (5 * ((a3 * b4) + (a4 * b3)))
        d3 = (a0 * b3) + (a1 * b2) + (a2 * b1) + (a3 * b0) + (5 * (a4 * b4))
        d4 = (a0 * b4) + (a1 * b3) + (a2 * b2) + (a3 * b1) + (a4 * b0)
        poly1305 carry into d0 d1 d2 d3 d4 out o

-- Carries 5 wide limbs down to 26 bits each (the top carry comes back times 5) and stores them at `out_(o..o+4)`.
fn :: poly1305 carry into Int Int Int Int Int Tensor[Int * j] Int => Int
      poly1305 carry into d0 d1 d2 d3 d4 out o =
        e1 = d1 + (d0 shr 26)
        e2 = d2 + (e1 shr 26)
        e3 = d3 + (e2 shr 26)
        e4 = d4 + (e3 shr 26)
        f0 = (d0 and 0x3FFFFFF) + ((e4 shr 26) * 5)
        out_(o)     = f0 and 0x3FFFFFF
        out_(o + 1) = (e1 and 0x3FFFFFF) + (f0 shr 26)
        out_(o + 2) = e2 and 0x3FFFFFF
        out_(o + 3) = e3 and 0x3FFFFFF
        out_(o + 4) = e4 and 0x3FFFFFF
        0

-- pw_(5 (j - 1) ..) = r^j for j = 1..n.
fn :: poly1305 powers Tensor[Int * m] Tensor[Int * 5] Int Int => Tensor[Int * m]
      poly1305 powers pw r j n =
        | j > n     = pw
        | j == 1    =
          pw_(0) = r_(0)
          pw_(1) = r_(1)
          pw_(2) = r_(2)
          pw_(3) = r_(3)
          pw_(4) = r_(4)
          poly1305 powers pw r 2 n
        | otherwise =
          poly1305 mul into pw (5 * (j - 2)) r 0 pw (5 * (j - 1))
          poly1305 powers pw r (j + 1) n

-- Lane l starts at block l: lx_(l) = off + 16 l.
fn :: poly1305 lane starts Tensor[U64 * n] Int Int Int => Tensor[U64 * n]
      poly1305 lane starts t off l n =
        | l >= n    = t
        | otherwise =
          t_(l) = off + (16 * l)
          poly1305 lane starts t off (l + 1) n

-- Limb `k` (times `f`) of r^(n - l) for every lane l: the multiplier of the last step.
fn :: poly1305 lane powers Tensor[U64 * n] Tensor[Int * m] Int Int Int Int => Tensor[U64 * n]
      poly1305 lane powers t pw k f l n =
        | l >= n    = t
        | otherwise =
          t_(l) = f * pw_((5 * ((n - l) - 1)) + k)
          poly1305 lane powers t pw k f (l + 1) n

-- h = the state after the `steps * 32` blocks of `msg` from byte `off` on, 32 blocks at a time:
-- lane l takes blocks l, l + 32, ...; every step multiplies by r^32 and the last one by r^(32 - l),
-- so the sum of the lanes is the same value as block-by-block (RFC 8439 §2.5.1).
fn :: poly1305 lanes Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int Int => Tensor[Int * 5]
      poly1305 lanes h r msg off steps =
        pw = poly1305 powers (Tensor[Int * 160]) r 1 32
        h0 = Tensor[U64 * 32]
        h1 = Tensor[U64 * 32]
        h2 = Tensor[U64 * 32]
        h3 = Tensor[U64 * 32]
        h4 = Tensor[U64 * 32]
        h0_(0) = h_(0)
        h1_(0) = h_(1)
        h2_(0) = h_(2)
        h3_(0) = h_(3)
        h4_(0) = h_(4)
        lx = poly1305 lane starts (Tensor[U64 * 32]) 0 0 32
        m0, m1, m2, m3, m4 = poly1305 lanes loop h0 h1 h2 h3 h4 msg lx (Tensor[U64 * 32] with pw_(155)) (Tensor[U64 * 32] with pw_(156)) (Tensor[U64 * 32] with pw_(157)) (Tensor[U64 * 32] with pw_(158)) (Tensor[U64 * 32] with pw_(159)) (Tensor[U64 * 32] with (5 * pw_(156))) (Tensor[U64 * 32] with (5 * pw_(157))) (Tensor[U64 * 32] with (5 * pw_(158))) (Tensor[U64 * 32] with (5 * pw_(159))) off (steps - 1)
        q0 = poly1305 lane powers (Tensor[U64 * 32]) pw 0 1 0 32
        q1 = poly1305 lane powers (Tensor[U64 * 32]) pw 1 1 0 32
        q2 = poly1305 lane powers (Tensor[U64 * 32]) pw 2 1 0 32
        q3 = poly1305 lane powers (Tensor[U64 * 32]) pw 3 1 0 32
        q4 = poly1305 lane powers (Tensor[U64 * 32]) pw 4 1 0 32
        u1 = poly1305 lane powers (Tensor[U64 * 32]) pw 1 5 0 32
        u2 = poly1305 lane powers (Tensor[U64 * 32]) pw 2 5 0 32
        u3 = poly1305 lane powers (Tensor[U64 * 32]) pw 3 5 0 32
        u4 = poly1305 lane powers (Tensor[U64 * 32]) pw 4 5 0 32
        f0, f1, f2, f3, f4 = poly1305 lanes loop m0 m1 m2 m3 m4 msg lx q0 q1 q2 q3 q4 u1 u2 u3 u4 (off + (512 * (steps - 1))) 1
        out = Tensor[Int * 5]
        poly1305 carry into (tensor sum f0) (tensor sum f1) (tensor sum f2) (tensor sum f3) (tensor sum f4) out 0
        out

fn :: c pick Bool Int Int => Int
      c pick use_a a   b   =
        | use_a     = a
        | otherwise = b

fn :: poly1305 finalize Tensor[Int * 5] Tensor[U8] => Tensor[U8]
      poly1305 finalize h                otk        =
        c1   = h_(1) / 67108864
        h1   = h_(1) % 67108864
        t2   = h_(2) + c1
        c2   = t2 / 67108864
        h2   = t2 % 67108864
        t3   = h_(3) + c2
        c3   = t3 / 67108864
        h3   = t3 % 67108864
        t4   = h_(4) + c3
        c4   = t4 / 67108864
        h4   = t4 % 67108864
        t0   = h_(0) + (c4 * 5)
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

        use_g = g4 >= 0
        f0   = c pick use_g g0 h0
        f1   = c pick use_g g1 h1_f
        f2   = c pick use_g g2 h2
        f3   = c pick use_g g3 h3
        f4   = c pick use_g g4 h4

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
        tag  = Tensor[U8 * 16]
        o1   = c put le32 tag 0 (sum0 % 4294967296)
        o2   = c put le32 tag o1 (sum1 % 4294967296)
        o3   = c put le32 tag o2 (sum2 % 4294967296)
        c put le32 tag o3 (sum3 % 4294967296)
        tag

fn :: pad16 len Int => Int
      pad16 len len =
        | (len % 16) == 0 = 0
        | otherwise       = 16 - (len % 16)

-- Writes `n` as 8 little-endian bytes at `off`; returns `off + 8`.
fn :: c put le64 Tensor[U8] Int Int => Int
      c put le64 t          off n   =
        o1 = c put le32 t off (n % 4294967296)
        c put le32 t o1 (n / 4294967296)

-- The MAC of RFC 8439 §2.8 over aad || pad16 || ct || pad16 || le64(len aad) || le64(len ct).
-- The ciphertext is read in place: 32 blocks at a time while at least 4 steps remain, then block by block;
-- only the padded aad, the last partial block and the lengths are copied (to small buffers).
fn :: poly1305 aead mac Tensor[U8] Tensor[U8] Tensor[U8] => Tensor[U8]
      poly1305 aead mac otk        aad_b      ct_b       =
        alen  = c u8 len aad_b
        clen  = c u8 len ct_b
        r     = poly1305 r limbs otk
        abuf  = Tensor[U8 * (alen + (pad16 len alen))]
        c copy bytes abuf 0 aad_b 0 alen
        h1    = poly1305 blocks loop (Tensor[Int * 5]) r abuf 0 (alen + (pad16 len alen))
        full  = (clen shr 4) shl 4
        steps = clen shr 9
        h2    =
          | steps >= 4 = poly1305 lanes h1 r ct_b 0 steps
          | otherwise  = h1
        done  =
          | steps >= 4 = steps shl 9
          | otherwise  = 0
        h3    = poly1305 blocks loop h2 r ct_b done full
        tail  = Tensor[U8 * 32]
        c copy bytes tail 0 ct_b full (clen - full)
        tlen  =
          | clen > full = 16
          | otherwise   = 0
        o1    = c put le64 tail tlen alen
        c put le64 tail o1 clen
        h_fin = poly1305 blocks loop h3 r tail 0 (tlen + 16)
        poly1305 finalize h_fin otk

fn :: aead seal String String String String => String
      aead seal key nonce aad plaintext =
        | (str len key) != 32 or (str len nonce) != 12 = ""
        | otherwise                                    =
          key_bs   = tensor from str key
          nonce_bs = tensor from str nonce
          otk      = chacha20 block key_bs nonce_bs 0
          ct_bs    = chacha20 bitxor key_bs nonce_bs 1 (tensor from str plaintext)
          tag_bs   = poly1305 aead mac otk (tensor from str aad) ct_bs
          (tensor to str ct_bs) + (tensor to str tag_bs)

fn :: decrypt verified aead Bool Tensor[U8] Tensor[U8] Tensor[U8] => Int String
      decrypt verified aead False _          _          _          =  (0 - 12, "")
      decrypt verified aead True  key_bs     nonce_bs   ct_bs      =
        chacha20 bitxor key_bs nonce_bs 1 ct_bs -> pt_bs
        (0, tensor to str pt_bs)

fn :: aead open String String String String => Int String
      aead open key nonce aad ciphertext_and_tag =
        | (str len key) != 32 or (str len nonce) != 12 or (str len ciphertext_and_tag) < 16 = (0 - 7, "")
        | otherwise =
          total_len = str len ciphertext_and_tag
          ct_len    = total_len - 16
          ct_str    = byte slice ciphertext_and_tag 0 ct_len
          tag_str   = byte slice ciphertext_and_tag ct_len total_len
          key_bs    = tensor from str key
          nonce_bs  = tensor from str nonce
          ct_bs     = tensor from str ct_str
          otk       = chacha20 block key_bs nonce_bs 0
          exp_tag   = tensor to str (poly1305 aead mac otk (tensor from str aad) ct_bs)
          decrypt verified aead (ct equal tag_str exp_tag) key_bs nonce_bs ct_bs
```

### 24.4.4. Intern implementation: AES-128-CTR on n blocks at once and GHASH with carry-less products (NIST SP 800-38D)

Se hur `crypto.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
-- The S-box as bytes, to index it element-wise.
fn :: aes sbox u8 loop Tensor[U64 * 256] Tensor[U8 * 256] Int => Tensor[U8 * 256]
      aes sbox u8 loop sb t i =
        | i >= 256  = t
        | otherwise =
          t_(i) = sb_(i)
          aes sbox u8 loop sb t (i + 1)

-- One AES round (FIPS 197 §5.1) on n blocks at once: s<4 c + r> is the byte of column c, row r of every block.
-- SubBytes and ShiftRows are one indexed read of the S-box; MixColumns and AddRoundKey are element-wise.
fn :: aes ctr round Tensor[U8 * 256] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int => Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n]
      aes ctr round sb s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 k0 k1 k2 k3 k4 k5 k6 k7 k8 k9 k10 k11 k12 k13 k14 k15 =
        a0 = sb_(s0_i)
        a1 = sb_(s5_i)
        a2 = sb_(s10_i)
        a3 = sb_(s15_i)
        a4 = sb_(s4_i)
        a5 = sb_(s9_i)
        a6 = sb_(s14_i)
        a7 = sb_(s3_i)
        a8 = sb_(s8_i)
        a9 = sb_(s13_i)
        a10 = sb_(s2_i)
        a11 = sb_(s7_i)
        a12 = sb_(s12_i)
        a13 = sb_(s1_i)
        a14 = sb_(s6_i)
        a15 = sb_(s11_i)
        t0 = ((a0_i xor a1_i) xor a2_i) xor a3_i
        n0 = ((a0_i xor t0_i) xor (((a0_i xor a1_i) shl 1) xor (((a0_i xor a1_i) shr 7) * 27))) xor k0
        n1 = ((a1_i xor t0_i) xor (((a1_i xor a2_i) shl 1) xor (((a1_i xor a2_i) shr 7) * 27))) xor k1
        n2 = ((a2_i xor t0_i) xor (((a2_i xor a3_i) shl 1) xor (((a2_i xor a3_i) shr 7) * 27))) xor k2
        n3 = ((a3_i xor t0_i) xor (((a3_i xor a0_i) shl 1) xor (((a3_i xor a0_i) shr 7) * 27))) xor k3
        t1 = ((a4_i xor a5_i) xor a6_i) xor a7_i
        n4 = ((a4_i xor t1_i) xor (((a4_i xor a5_i) shl 1) xor (((a4_i xor a5_i) shr 7) * 27))) xor k4
        n5 = ((a5_i xor t1_i) xor (((a5_i xor a6_i) shl 1) xor (((a5_i xor a6_i) shr 7) * 27))) xor k5
        n6 = ((a6_i xor t1_i) xor (((a6_i xor a7_i) shl 1) xor (((a6_i xor a7_i) shr 7) * 27))) xor k6
        n7 = ((a7_i xor t1_i) xor (((a7_i xor a4_i) shl 1) xor (((a7_i xor a4_i) shr 7) * 27))) xor k7
        t2 = ((a8_i xor a9_i) xor a10_i) xor a11_i
        n8 = ((a8_i xor t2_i) xor (((a8_i xor a9_i) shl 1) xor (((a8_i xor a9_i) shr 7) * 27))) xor k8
        n9 = ((a9_i xor t2_i) xor (((a9_i xor a10_i) shl 1) xor (((a9_i xor a10_i) shr 7) * 27))) xor k9
        n10 = ((a10_i xor t2_i) xor (((a10_i xor a11_i) shl 1) xor (((a10_i xor a11_i) shr 7) * 27))) xor k10
        n11 = ((a11_i xor t2_i) xor (((a11_i xor a8_i) shl 1) xor (((a11_i xor a8_i) shr 7) * 27))) xor k11
        t3 = ((a12_i xor a13_i) xor a14_i) xor a15_i
        n12 = ((a12_i xor t3_i) xor (((a12_i xor a13_i) shl 1) xor (((a12_i xor a13_i) shr 7) * 27))) xor k12
        n13 = ((a13_i xor t3_i) xor (((a13_i xor a14_i) shl 1) xor (((a13_i xor a14_i) shr 7) * 27))) xor k13
        n14 = ((a14_i xor t3_i) xor (((a14_i xor a15_i) shl 1) xor (((a14_i xor a15_i) shr 7) * 27))) xor k14
        n15 = ((a15_i xor t3_i) xor (((a15_i xor a12_i) shl 1) xor (((a15_i xor a12_i) shr 7) * 27))) xor k15
        (n0, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15)

-- The last round has no MixColumns.
fn :: aes ctr last round Tensor[U8 * 256] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int Int => Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n]
      aes ctr last round sb s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 k0 k1 k2 k3 k4 k5 k6 k7 k8 k9 k10 k11 k12 k13 k14 k15 =
        n0 = sb_(s0_i) xor k0
        n1 = sb_(s5_i) xor k1
        n2 = sb_(s10_i) xor k2
        n3 = sb_(s15_i) xor k3
        n4 = sb_(s4_i) xor k4
        n5 = sb_(s9_i) xor k5
        n6 = sb_(s14_i) xor k6
        n7 = sb_(s3_i) xor k7
        n8 = sb_(s8_i) xor k8
        n9 = sb_(s13_i) xor k9
        n10 = sb_(s2_i) xor k10
        n11 = sb_(s7_i) xor k11
        n12 = sb_(s12_i) xor k12
        n13 = sb_(s1_i) xor k13
        n14 = sb_(s6_i) xor k14
        n15 = sb_(s11_i) xor k15
        (n0, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15)

-- Byte `sh / 8` (from the low end) of the big-endian counter of every block, XORed with the round-0 key byte.
fn :: aes ctr fill Tensor[U8 * n] Int Int Int Int Int => Tensor[U8 * n]
      aes ctr fill t ctr sh kb i n =
        | i >= n    = t
        | otherwise =
          t_(i) = ((((ctr + i) and 0xFFFFFFFF) shr sh) and 255) xor kb
          aes ctr fill t ctr sh kb (i + 1) n

-- E(K, nonce || ctr + b) for b in 0..nb-1 (NIST SP 800-38D §6.5): 16 tensors of `nb` bytes.
fn :: aes ctr page Tensor[U8 * 256] Tensor[U64 * 176] Tensor[U8] Int Int => Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n] Tensor[U8 * n]
      aes ctr page sb rk nonce_bs ctr nb =
        i0 = Tensor[U8 * nb] with (nonce_bs_(0) xor rk_(0))
        i1 = Tensor[U8 * nb] with (nonce_bs_(1) xor rk_(1))
        i2 = Tensor[U8 * nb] with (nonce_bs_(2) xor rk_(2))
        i3 = Tensor[U8 * nb] with (nonce_bs_(3) xor rk_(3))
        i4 = Tensor[U8 * nb] with (nonce_bs_(4) xor rk_(4))
        i5 = Tensor[U8 * nb] with (nonce_bs_(5) xor rk_(5))
        i6 = Tensor[U8 * nb] with (nonce_bs_(6) xor rk_(6))
        i7 = Tensor[U8 * nb] with (nonce_bs_(7) xor rk_(7))
        i8 = Tensor[U8 * nb] with (nonce_bs_(8) xor rk_(8))
        i9 = Tensor[U8 * nb] with (nonce_bs_(9) xor rk_(9))
        i10 = Tensor[U8 * nb] with (nonce_bs_(10) xor rk_(10))
        i11 = Tensor[U8 * nb] with (nonce_bs_(11) xor rk_(11))
        i12 = aes ctr fill (Tensor[U8 * nb]) ctr 24 rk_(12) 0 nb
        i13 = aes ctr fill (Tensor[U8 * nb]) ctr 16 rk_(13) 0 nb
        i14 = aes ctr fill (Tensor[U8 * nb]) ctr 8 rk_(14) 0 nb
        i15 = aes ctr fill (Tensor[U8 * nb]) ctr 0 rk_(15) 0 nb
        r1x0, r1x1, r1x2, r1x3, r1x4, r1x5, r1x6, r1x7, r1x8, r1x9, r1x10, r1x11, r1x12, r1x13, r1x14, r1x15 = aes ctr round sb i0 i1 i2 i3 i4 i5 i6 i7 i8 i9 i10 i11 i12 i13 i14 i15 rk_(16) rk_(17) rk_(18) rk_(19) rk_(20) rk_(21) rk_(22) rk_(23) rk_(24) rk_(25) rk_(26) rk_(27) rk_(28) rk_(29) rk_(30) rk_(31)
        r2x0, r2x1, r2x2, r2x3, r2x4, r2x5, r2x6, r2x7, r2x8, r2x9, r2x10, r2x11, r2x12, r2x13, r2x14, r2x15 = aes ctr round sb r1x0 r1x1 r1x2 r1x3 r1x4 r1x5 r1x6 r1x7 r1x8 r1x9 r1x10 r1x11 r1x12 r1x13 r1x14 r1x15 rk_(32) rk_(33) rk_(34) rk_(35) rk_(36) rk_(37) rk_(38) rk_(39) rk_(40) rk_(41) rk_(42) rk_(43) rk_(44) rk_(45) rk_(46) rk_(47)
        r3x0, r3x1, r3x2, r3x3, r3x4, r3x5, r3x6, r3x7, r3x8, r3x9, r3x10, r3x11, r3x12, r3x13, r3x14, r3x15 = aes ctr round sb r2x0 r2x1 r2x2 r2x3 r2x4 r2x5 r2x6 r2x7 r2x8 r2x9 r2x10 r2x11 r2x12 r2x13 r2x14 r2x15 rk_(48) rk_(49) rk_(50) rk_(51) rk_(52) rk_(53) rk_(54) rk_(55) rk_(56) rk_(57) rk_(58) rk_(59) rk_(60) rk_(61) rk_(62) rk_(63)
        r4x0, r4x1, r4x2, r4x3, r4x4, r4x5, r4x6, r4x7, r4x8, r4x9, r4x10, r4x11, r4x12, r4x13, r4x14, r4x15 = aes ctr round sb r3x0 r3x1 r3x2 r3x3 r3x4 r3x5 r3x6 r3x7 r3x8 r3x9 r3x10 r3x11 r3x12 r3x13 r3x14 r3x15 rk_(64) rk_(65) rk_(66) rk_(67) rk_(68) rk_(69) rk_(70) rk_(71) rk_(72) rk_(73) rk_(74) rk_(75) rk_(76) rk_(77) rk_(78) rk_(79)
        r5x0, r5x1, r5x2, r5x3, r5x4, r5x5, r5x6, r5x7, r5x8, r5x9, r5x10, r5x11, r5x12, r5x13, r5x14, r5x15 = aes ctr round sb r4x0 r4x1 r4x2 r4x3 r4x4 r4x5 r4x6 r4x7 r4x8 r4x9 r4x10 r4x11 r4x12 r4x13 r4x14 r4x15 rk_(80) rk_(81) rk_(82) rk_(83) rk_(84) rk_(85) rk_(86) rk_(87) rk_(88) rk_(89) rk_(90) rk_(91) rk_(92) rk_(93) rk_(94) rk_(95)
        r6x0, r6x1, r6x2, r6x3, r6x4, r6x5, r6x6, r6x7, r6x8, r6x9, r6x10, r6x11, r6x12, r6x13, r6x14, r6x15 = aes ctr round sb r5x0 r5x1 r5x2 r5x3 r5x4 r5x5 r5x6 r5x7 r5x8 r5x9 r5x10 r5x11 r5x12 r5x13 r5x14 r5x15 rk_(96) rk_(97) rk_(98) rk_(99) rk_(100) rk_(101) rk_(102) rk_(103) rk_(104) rk_(105) rk_(106) rk_(107) rk_(108) rk_(109) rk_(110) rk_(111)
        r7x0, r7x1, r7x2, r7x3, r7x4, r7x5, r7x6, r7x7, r7x8, r7x9, r7x10, r7x11, r7x12, r7x13, r7x14, r7x15 = aes ctr round sb r6x0 r6x1 r6x2 r6x3 r6x4 r6x5 r6x6 r6x7 r6x8 r6x9 r6x10 r6x11 r6x12 r6x13 r6x14 r6x15 rk_(112) rk_(113) rk_(114) rk_(115) rk_(116) rk_(117) rk_(118) rk_(119) rk_(120) rk_(121) rk_(122) rk_(123) rk_(124) rk_(125) rk_(126) rk_(127)
        r8x0, r8x1, r8x2, r8x3, r8x4, r8x5, r8x6, r8x7, r8x8, r8x9, r8x10, r8x11, r8x12, r8x13, r8x14, r8x15 = aes ctr round sb r7x0 r7x1 r7x2 r7x3 r7x4 r7x5 r7x6 r7x7 r7x8 r7x9 r7x10 r7x11 r7x12 r7x13 r7x14 r7x15 rk_(128) rk_(129) rk_(130) rk_(131) rk_(132) rk_(133) rk_(134) rk_(135) rk_(136) rk_(137) rk_(138) rk_(139) rk_(140) rk_(141) rk_(142) rk_(143)
        r9x0, r9x1, r9x2, r9x3, r9x4, r9x5, r9x6, r9x7, r9x8, r9x9, r9x10, r9x11, r9x12, r9x13, r9x14, r9x15 = aes ctr round sb r8x0 r8x1 r8x2 r8x3 r8x4 r8x5 r8x6 r8x7 r8x8 r8x9 r8x10 r8x11 r8x12 r8x13 r8x14 r8x15 rk_(144) rk_(145) rk_(146) rk_(147) rk_(148) rk_(149) rk_(150) rk_(151) rk_(152) rk_(153) rk_(154) rk_(155) rk_(156) rk_(157) rk_(158) rk_(159)
        aes ctr last round sb r9x0 r9x1 r9x2 r9x3 r9x4 r9x5 r9x6 r9x7 r9x8 r9x9 r9x10 r9x11 r9x12 r9x13 r9x14 r9x15 rk_(160) rk_(161) rk_(162) rk_(163) rk_(164) rk_(165) rk_(166) rk_(167) rk_(168) rk_(169) rk_(170) rk_(171) rk_(172) rk_(173) rk_(174) rk_(175)

-- The first `n` bytes (at most 1 MiB) of the CTR key stream from counter `ctr` on: all the blocks at once,
-- then the 16 byte tensors side by side (ridgunc 1.0.40).
fn :: aes ctr key stream chunk Tensor[U8 * 256] Tensor[U64 * 176] Tensor[U8] Int Int => Tensor[U8]
      aes ctr key stream chunk sb8 rk nonce_bs ctr n =
        nb = (n + 15) / 16
        o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15 = aes ctr page sb8 rk nonce_bs ctr nb
        c first bytes (tensor interleave [o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15]) (16 * nb) n

fn :: aes ctr key stream loop Tensor[U8 * 256] Tensor[U64 * 176] Tensor[U8] Int Int => Tensor[U8]
      aes ctr key stream loop sb8 rk nonce_bs ctr n =
        | n <= 0       = Tensor[U8 * 0]
        | n <= 1048576 = aes ctr key stream chunk sb8 rk nonce_bs ctr n
        | otherwise    = tensor from str ((tensor to str (aes ctr key stream chunk sb8 rk nonce_bs ctr 1048576)) + (tensor to str (aes ctr key stream loop sb8 rk nonce_bs (ctr + 65536) (n - 1048576))))

-- The first `n` bytes of the CTR key stream from counter `ctr` on.
fn :: aes ctr key stream Tensor[U64 * 256] Tensor[U64 * 176] Tensor[U8] Int Int => Tensor[U8]
      aes ctr key stream sb rk nonce_bs ctr n =
        aes ctr key stream loop (aes sbox u8 loop sb (Tensor[U8 * 256]) 0) rk nonce_bs ctr n

-- GHASH product (NIST SP 800-38D §6.3) of two blocks, each as two big-endian 64-bit integers (high, low).
-- Read that way the bits of the field element are reversed, so the carry-less product comes out one place
-- to the right: shift left by 1, then reduce by x^128 + x^7 + x^2 + x + 1.
fn :: ghash mul Int Int Int Int => Int Int
      ghash mul x1 x0 h1 h0 =
        lo  = x0 clmul h0
        loh = x0 clmulhi h0
        hi  = x1 clmul h1
        hih = x1 clmulhi h1
        xm  = x0 xor x1
        hm  = h0 xor h1
        mi  = ((xm clmul hm) xor lo) xor hi
        mih = ((xm clmulhi hm) xor loh) xor hih
        w1  = loh xor mi
        w2  = hi xor mih
        v3  = (hih shl 1) or (w2 shr 63)
        v2  = (w2 shl 1) or (w1 shr 63)
        v1  = (w1 shl 1) or (lo shr 63)
        v0  = lo shl 1
        u2  = v2 xor v0 xor (v0 shr 1) xor (v0 shr 2) xor (v0 shr 7)
        u1  = v1 xor (v0 shl 63) xor (v0 shl 62) xor (v0 shl 57)
        z1  = v3 xor u1 xor (u1 shr 1) xor (u1 shr 2) xor (u1 shr 7)
        z0  = u2 xor (u1 shl 63) xor (u1 shl 62) xor (u1 shl 57)
        (z1, z0)

-- The 8 bytes at `off` as a big-endian integer; bytes at or after `n` count as 0 (the zero padding of a block).
fn :: ghash be64 Tensor[U8] Int Int => Int
      ghash be64 bs off n =
        | (off + 8) <= n = (bs_(off) shl 56) or (bs_(off + 1) shl 48) or (bs_(off + 2) shl 40) or (bs_(off + 3) shl 32) or (bs_(off + 4) shl 24) or (bs_(off + 5) shl 16) or (bs_(off + 6) shl 8) or bs_(off + 7)
        | otherwise      = ghash be64 tail bs off n 0 0

fn :: ghash be64 tail Tensor[U8] Int Int Int Int => Int
      ghash be64 tail bs off n i acc =
        | i >= 8         = acc
        | (off + i) >= n = ghash be64 tail bs off n (i + 1) (acc shl 8)
        | otherwise      = ghash be64 tail bs off n (i + 1) ((acc shl 8) or bs_(off + i))

-- Y = (Y xor block) * H for every 16-byte block of `bs` (the last one zero-padded).
fn :: ghash absorb Int Int Int Int Tensor[U8] Int Int => Int Int
      ghash absorb y1 y0 h1 h0 bs off n =
        | off >= n  = (y1, y0)
        | otherwise =
          z1, z0 = ghash mul (y1 xor (ghash be64 bs off n)) (y0 xor (ghash be64 bs (off + 8) n)) h1 h0
          ghash absorb z1 z0 h1 h0 bs (off + 16) n

fn :: ghash put be64 Tensor[U8] Int Int => Int
      ghash put be64 t off v =
        t_(off + 0) = (v shr 56) and 255
        t_(off + 1) = (v shr 48) and 255
        t_(off + 2) = (v shr 40) and 255
        t_(off + 3) = (v shr 32) and 255
        t_(off + 4) = (v shr 24) and 255
        t_(off + 5) = (v shr 16) and 255
        t_(off + 6) = (v shr 8) and 255
        t_(off + 7) = (v shr 0) and 255
        0

-- GHASH_H(aad || pad || ct || pad || len64(aad) || len64(ct)) as 16 bytes (NIST SP 800-38D §7.1 step 5).
fn :: ghash compute Tensor[U8] Tensor[U8] Tensor[U8] => Tensor[U8]
      ghash compute h_bs aad_bs ct_bs =
        h1 = ghash be64 h_bs 0 16
        h0 = ghash be64 h_bs 8 16
        alen = c u8 len aad_bs
        clen = c u8 len ct_bs
        a1, a0 = ghash absorb 0 0 h1 h0 aad_bs 0 alen
        b1, b0 = ghash absorb a1 a0 h1 h0 ct_bs 0 clen
        f1, f0 = ghash mul (b1 xor (alen * 8)) (b0 xor (clen * 8)) h1 h0
        out = Tensor[U8 * 16]
        ghash put be64 out 0 f1
        ghash put be64 out 8 f0
        out

fn :: aes128 gcm seal String String String String => String
      aes128 gcm seal key    nonce  aad    plaintext =
        | (str len key) != 16 or (str len nonce) != 12 = ""
        | otherwise =
          tbl = c build b256
          sb  = aes init sbox
          rk  = aes expand key sb key
          h_s = aes encrypt with rk tbl sb rk (c repeat byte 0 16)
          ej0 = aes encrypt with rk tbl sb rk (nonce + (be32 bytes 1))
          pt  = tensor from str plaintext
          ct  = c bitxor bytes pt (aes ctr key stream sb rk (tensor from str nonce) 2 (c u8 len pt))
          s   = ghash compute (tensor from str h_s) (tensor from str aad) ct
          tag = c bitxor bytes s (tensor from str ej0)
          (tensor to str ct) + (tensor to str tag)

fn :: aes128 gcm open verified Bool Tensor[U64 * 256] Tensor[U64 * 176] String Tensor[U8] => Int String
      aes128 gcm open verified False _ _ _ _ = (0 - 12, "")
      aes128 gcm open verified True sb rk nonce ct =
        pt = c bitxor bytes ct (aes ctr key stream sb rk (tensor from str nonce) 2 (c u8 len ct))
        (0, tensor to str pt)

fn :: aes128 gcm open String String String String => Int String
      aes128 gcm open key    nonce  aad    ciphertext_and_tag =
        | (str len key) != 16 or (str len nonce) != 12 or (str len ciphertext_and_tag) < 16 = (0 - 7, "")
        | otherwise =
          tlen    = str len ciphertext_and_tag
          clen    = tlen - 16
          ct      = tensor from str (byte slice ciphertext_and_tag 0 clen)
          tag     = byte slice ciphertext_and_tag clen tlen
          tbl     = c build b256
          sb      = aes init sbox
          rk      = aes expand key sb key
          h_s     = aes encrypt with rk tbl sb rk (c repeat byte 0 16)
          ej0     = aes encrypt with rk tbl sb rk (nonce + (be32 bytes 1))
          s       = ghash compute (tensor from str h_s) (tensor from str aad) ct
          exp_tag = tensor to str (c bitxor bytes s (tensor from str ej0))
          aes128 gcm open verified (ct equal tag exp_tag) sb rk nonce ct
```

### 24.4.5. Intern implementation: Montgomery Multiplication for Odd Moduli (`bn mont mul`, `bn mont pow`, `bn mod exp`)

Se hur `crypto.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
-- One step per limb of a: t = (t + a_i b + q m) / 2^16, with q chosen so the low limb is 0.
-- The limbs of t are not carried (each stays below 2^41); only the low 16 bits of limb 0 decide q,
-- and the carry of the limb that drops out goes to the new limb 0.
fn :: bn mont loop Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Int Int => Tensor[U64 * n] Tensor[U64 * n]
      bn mont loop t ci a b m sh nx zr e0 minv k =
        | k <= 0 = (t, ci)
        | otherwise =
          ai  = a_(ci_i)
          l0  = t_(zr_i) + (ai_i * b_(zr_i))
          q   = (l0_i * minv) and 65535
          t1  = ((t_(nx_i) + (ai_i * b_(sh_i))) + (q_i * m_(sh_i))) + (((l0_i + (q_i * m_(zr_i))) shr 16) * e0_i)
          ci1 = ci_i + 1
          bn mont loop t1 ci1 a b m sh nx zr e0 minv (k - 1)

-- Carries the limbs of t into `out` (16 bits each); returns the carry out of limb lim - 1.
fn :: bn mont carry Tensor[U64 * n] Tensor[U64 * 260] Int Int Int => Int
      bn mont carry t out j lim carry =
        | j >= lim  = carry
        | otherwise =
          v = t_(j) + carry
          out_(j) = v and 65535
          bn mont carry t out (j + 1) lim (v shr 16)

-- a * b / R mod m, for a, b < m.
fn :: bn mont mul BnMont Tensor[U64 * 260] Tensor[U64 * 260] => Tensor[U64 * 260]
      bn mont mul ctx a b =
        lim   = bm_lim ctx
        m     = bm_m ctx
        t, ci = bn mont loop (Tensor[U64 * (lim + 2)]) (Tensor[U64 * (lim + 2)]) a b m (bm_sh ctx) (bm_nx ctx) (bm_zr ctx) (bm_e0 ctx) (bm_minv ctx) lim
        out   = bn zero lim
        top   = bn mont carry t out 0 lim 0
        bn add mod finish (top > 0 or (bn cmp out m lim) >= 0) out m lim

-- t_(j) = j + 1, but never above `cap`, for the `len` lanes.
fn :: bn mont ix Tensor[U64 * n] Int Int Int => Tensor[U64 * n]
      bn mont ix t cap j len =
        | j >= len  = t
        | otherwise =
          t_(j) = | (j + 1) > cap = cap | otherwise = j + 1 |.
          bn mont ix t cap (j + 1) len

-- -m^-1 mod 2^16 for odd m (Newton: each step doubles the correct bits).
fn :: bn mont minv Int => Int
      bn mont minv m0 =
        x1 = m0
        x2 = (x1 * (2 - (m0 * x1))) and 65535
        x3 = (x2 * (2 - (m0 * x2))) and 65535
        x4 = (x3 * (2 - (m0 * x3))) and 65535
        x5 = (x4 * (2 - (m0 * x4))) and 65535
        (65536 - x5) and 65535

-- 2^e in Montgomery form (2^e R mod m), by square and multiply from `two` = 2 R mod m.
fn :: bn mont pow2 BnMont Tensor[U64 * 260] Tensor[U64 * 260] Int Int => Tensor[U64 * 260]
      bn mont pow2 ctx acc two e bit =
        | bit < 0   = acc
        | otherwise =
          sq = bn mont mul ctx acc acc
          nx = | ((e shr bit) and 1) == 1 = bn mont mul ctx sq two | otherwise = sq |.
          bn mont pow2 ctx nx two e (bit - 1)

-- The context of an odd modulus of `lim` limbs.
fn :: bn mont ctx Tensor[U64 * 260] Int => BnMont
      bn mont ctx m lim =
        sh    = bn mont ix (Tensor[U64 * (lim + 2)]) (lim + 2) 0 (lim + 2)
        nx    = bn mont ix (Tensor[U64 * (lim + 2)]) (lim + 1) 0 (lim + 2)
        zr    = Tensor[U64 * (lim + 2)]
        e0    = Tensor[U64 * (lim + 2)]
        e0_(0) = 1
        prod  = bn zero520 ((2 * lim) + 4)
        prod_(lim) = 1
        one   = bn reduce520 prod m lim
        unit  = bn zero lim
        unit_(0) = 1
        ctx0  = BnMont m lim (bn mont minv m_(0)) one one unit sh nx zr e0
        two   = bn add mod one one m lim
        r2    = bn mont pow2 ctx0 one two (16 * lim) 12
        ctx0 with bm_r2 = r2

-- a * b mod m through the context: (a b / R) * R^2 / R.
fn :: bn mont mul mod BnMont Tensor[U64 * 260] Tensor[U64 * 260] => Tensor[U64 * 260]
      bn mont mul mod ctx a b =  bn mont mul ctx (bn mont mul ctx a b) (bm_r2 ctx)

fn :: bn mont sq BnMont Tensor[U64 * 260] => Tensor[U64 * 260]
      bn mont sq ctx a =  bn mont mul ctx a a

-- To Montgomery form (a R mod m) and back.
fn :: bn mont in BnMont Tensor[U64 * 260] => Tensor[U64 * 260]
      bn mont in ctx a =  bn mont mul ctx a (bm_r2 ctx)

fn :: bn mont out BnMont Tensor[U64 * 260] => Tensor[U64 * 260]
      bn mont out ctx a =  bn mont mul ctx a (bm_unit ctx)

fn :: bn mont pow bits Tensor[U64 * 260] BnMont Tensor[U64 * 260] Int Int => Tensor[U64 * 260]
      bn mont pow bits acc ctx base e_word bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          acc2 = bn mont mul ctx acc acc
          acc3 =
            | ((e_word shr bit_idx) and 1) == 1 = bn mont mul ctx acc2 base
            | otherwise                         = acc2
          bn mont pow bits acc3 ctx base e_word (bit_idx - 1)

fn :: bn mont pow bytes Tensor[U64 * 260] BnMont Tensor[U64 * 260] String Int Int => Tensor[U64 * 260]
      bn mont pow bytes acc ctx base exp_s idx elen =
        | idx >= elen = acc
        | otherwise   = bn mont pow bytes (bn mont pow bits acc ctx base (norm byte (str char at exp_s idx)) 7) ctx base exp_s (idx + 1) elen

-- base^exp for `base` and the result in Montgomery form; `exp_be` is the exponent as big-endian bytes.
fn :: bn mont pow BnMont Tensor[U64 * 260] String => Tensor[U64 * 260]
      bn mont pow ctx base exp_be =
        exp_s = bn strip leading zeroes exp_be 0 (str len exp_be)
        bn mont pow bytes (bn clone (bm_one ctx) (bm_lim ctx)) ctx base exp_s 0 (str len exp_s)

fn :: bn mod exp bits loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int Int => Tensor[U64 * 260]
      bn mod exp bits loop acc base m lim e_word bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          acc2 = bn sq mod acc m lim
          bit  = (e_word shr bit_idx) and 1
          acc3 =
            | bit == 1  = bn mul mod acc2 base m lim
            | otherwise = acc2
          bn mod exp bits loop acc3 base m lim e_word (bit_idx - 1)
```

---

## 24.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `crypto`

- **Algoritmisk garanti och säkerhet**: `aead open` verifierar Poly1305-autentiseringstaggen på 16 byte i konstant tid innan en enda byte klartext lämnas ut (returnerar `(-1, "")` vid manipulering).
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/crypto.ridgun` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test crypto.ridgun`.

### De 5 Gyllene Reglerna när du programmerar med `crypto`

1. **Deklarera `import crypto` överst i filen** och anropa dess funktioner med mellanslag, precis som de är deklarerade, så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `crypto`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `crypto`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `crypto` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 25** går vi vidare och utforskar lib:en **`argon2id`** på djupet (Lib:en `argon2id` — RFC 9106 Argon2id över `Tensor[U64 * 128]`, Blake2b och OWASP-profiler).
