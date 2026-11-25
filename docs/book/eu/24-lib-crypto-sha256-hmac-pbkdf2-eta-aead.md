# 24. kapitulua: `crypto` lib-a — Hash Funtzioak, HMAC, HKDF, PBKDF2, AEAD Zifraketak, X25519, Ed25519, ECDSA, RSA eta X.509

## 24.1. Zergatik existitzen da `crypto` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `crypto` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `crypto`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: HMAC bat `==`-rekin konparatzeak denbora-erasoei (*timing attacks*) atea irekitzen die, eta `SHA-256` bat kalkulatzeko edo `ChaCha20-Poly1305`-ekin zifratzeko `libssl.so`-ren menpe egoteak edozein bitarren eramangarritasun estatikoa apurtzen du.

**`crypto`** lib-ak % 100ean Ridgun hutsean eta tentsoreen gainean inplementatzen ditu: byte gordinen eta bit-eragiketen primitibak (`RGF-019`), **SHA-256**, **SHA-384**, **SHA-512**, **SHA-1** eta **MD5** hash funtzioak, **HMAC** eta **HKDF**, denbora konstanteko berdintasuna (`ct equal`), **PBKDF2-HMAC-SHA-256**, **ChaCha20-Poly1305** (RFC 8439) eta **AES-128-GCM** eta **AES-256-GCM** (NIST SP 800-38D) AEAD zifraketak, **X25519** gako-adostea, **Ed25519** eta Minisign sinadurak, **ECDH** eta **ECDSA** P-256 eta P-384 gainean, **RSA** PKCS#1 v1.5 eta PSS egiaztapena, eta **X.509** ziurtagirien analisia. `argon2id` lib-a ere eskaintzen du (`import argon2id` gehi `export argon2id`); beraz, `argon2id hash` eta `argon2id verify` erabilgarri daude `import crypto` soilarekin. Zifraketak, Poly1305, GHASH eta zenbaki handien aritmetika konpilatzailearen tentsore osoko eragiketen gainean exekutatzen dira: 1 MiB `aead seal`-ekin zigilatzeak 3 ms inguru behar ditu.

Ekosistema tradizional batean, **`CRYPTO`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`crypto`** lib-ak (`src/main/ridgun/lib/crypto.ridgun`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import crypto` (edo `import crypto as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: crypto` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `crypto`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 24.2. Artefaktu natiboak, inportazioa eta `crypto` APIaren katalogo osoa

`ridgun-libs`-en, **`crypto`** lehen mailako **lib** bat da, `src/main/ridgun/lib/crypto.ridgun` bidean kokatua (`CRYPTO` domeinua). `stable bundle`-ekin konpilatzean, formatu natibo bakarrean paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/crypto.ridgunlib` | Banaketa eta inportazio zuzena `import crypto` bidez |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: crypto` bidez: nahikoa da goiburuan `import crypto` (edo `import crypto as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 24.2.1. `crypto`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `sha256 bytes / sha256 hex` | FIPS 180-4 SHA-256 32 byteko laburpen bitarra edo 64 karaktereko hamaseitarra |
| `hmac sha256 / ct equal` | RFC 2104 gakodun MACa eta denbora konstanteko metagailu-konparazioa |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | RFC 8018 gako-eratorpena aurrez kalkulatutako SHA-256 tarteko egoerekin |
| `argon2id hash / argon2id verify` | 5 argumentuko RFC 9106 PHC pasahitz-hashinga eta denbora konstanteko egiaztapena |
| `aead seal / aead open` | RFC 8439 ChaCha20-Poly1305 zifraketa autentifikatua eta etiketa egiaztatuko deszifraketa |
| `sha512 bytes / sha512 hex` | 64 byteko laburpen bitarra edo 128 karaktereko hamaseitarra FIPS 180-4 SHA-512 |
| `ed25519 public key / ed25519 sign / ed25519 verify` | Gako publikoa, denbora konstanteko sinadura determinista eta RFC 8032 §5.1 Ed25519 egiaztapen kanonikoa |
| `minisign sign / minisign verify / minisign trusted comment` | `minisign` tresna estandarrarekin bateragarriak diren gako publikoak eta `.minisig` sinadurak |
| `sha1 bytes / sha1 hex / md5 bytes / md5 hex` | SHA-1 eta MD5, oraindik izendatzen dituzten protokoloetarako (WebSocket handshake-a, PostgreSQL `md5` autentifikazioa); ez diseinu berrietarako |
| `sha384 bytes / hmac sha384 / hkdf extract / hkdf expand / hkdf expand label` | SHA-384, HMAC-SHA-384 eta RFC 5869 HKDF, TLS 1.3ren etiketa-formarekin |
| `x25519 / x25519 public key` | RFC 7748 denbora konstanteko Diffie-Hellman gako-adostea |
| `aes128 gcm seal / aes128 gcm open` | AES-128-GCM zifraketa autentifikatua eta etiketa egiaztatuko deszifraketa (NIST SP 800-38D) |
| `p256 public key / p256 ecdh / ecdsa p256 verify / ecdsa p384 verify / rsa verify pkcs1 / rsa verify pss` | ECDH P-256 gainean, ECDSA egiaztapena P-256 eta P-384 gainean, eta RSA sinadura-egiaztapena 2048 bit edo gehiagoko gakoetarako |
| `x509 parse cert / x509 match hostname / x509 verify cert sig` | X.509 ziurtagirien analisia, RFC 6125 ostalari-izenen bat-etortzea eta jaulkitzailearen sinaduraren egiaztapena |
| `aes128 gcm seal / aes128 gcm open / aes256 gcm seal / aes256 gcm open` | AES-128-GCM eta AES-256-GCM zifraketa autentifikatua eta etiketa egiaztatuko deszifraketa (NIST SP 800-38D) |

### 24.2.2. `src/main/ridgun/lib/crypto.ridgun`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/crypto.ridgun` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`5` mota, `0` eragile eta `518` funtzio):

**`crypto`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type CT16     = ct0: A, ct1: A, ct2: A, ct3: A, ct4: A, ct5: A, ct6: A, ct7: A, ct8: A, ct9: A, ct10: A, ct11: A, ct12: A, ct13: A, ct14: A, ct15: A
type EcPoint  = ecx: Tensor[U64 * 260], ecy: Tensor[U64 * 260], ecz: Tensor[U64 * 260], ec_inf: Bool
type BnMont = bm_m: Tensor[U64 * 260], bm_lim: Int, bm_minv: Int, bm_one: Tensor[U64 * 260], bm_r2: Tensor[U64 * 260], bm_unit: Tensor[U64 * 260], bm_sh: Tensor[U64 * n], bm_nx: Tensor[U64 * n], bm_zr: Tensor[U64 * n], bm_e0: Tensor[U64 * n]
type EcCurve  = ecp: Tensor[U64 * 260], ecn: Tensor[U64 * 260], ecb: Tensor[U64 * 260], ecgx: Tensor[U64 * 260], ecgy: Tensor[U64 * 260], eclimbs: Int, ecm: BnMont
type X509Cert = tbs_der: String, issuer_der: String, subject_der: String, issuer_cn: String, subject_cn: String, not_before_at: Int, not_after_at: Int, key_alg: String, pubkey_bytes: String, rsa_exp_bytes: String, sig_alg: String, sig_bytes: String, san_dns: [String], is_ca: Bool, key_usage_bits: Int, has_server_auth: Bool
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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
| `65` | `arch :: sha256 round Tensor[U32 * 1] Tensor[U32 * 1] Tensor[U32 * 1] Tensor[U32 * 1] Tensor[U32 * 1] Tensor[U32 * 1] Tensor[U32 * 1] Tensor[U32 * 1] Tensor[U32 * 1]` | `Tensor[U32 * 1] Tensor[U32 * 1]` |
| `66` | `arch :: sha256 rounds Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `67` | `arch :: sha256 schedule Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U32 * 4]` |
| `68` | `arch :: sha256 compress Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `69` | `arch :: sha256 block Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * 64]` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `70` | `arch :: sha256 hmac outer Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `71` | `arch :: sha256 hmac step Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `72` | `fn :: sha256 pbkdf2 loop Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Int` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `73` | `fn :: sha256 absorb Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * n * 64] Int Int` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `74` | `arch :: sha256 be bytes Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U8 * 32]` |
| `75` | `arch :: sha256 end Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * 64] Int Int` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `76` | `arch :: sha256 end two Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * 64] Int Int` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `77` | `arch :: sha256 end bytes Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `78` | `arch :: sha256 end two bytes Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `79` | `arch :: sha256 start` | `Tensor[U32 * 4] Tensor[U32 * 4]` |
| `80` | `arch :: sha256 short Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `81` | `arch :: sha256 short two Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `82` | `arch :: sha256 mid Tensor[U8 * 64] Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `83` | `arch :: sha256 mid two Tensor[U8 * 64] Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `84` | `arch :: sha256 hmac one Tensor[U8 * 64] Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `85` | `arch :: sha256 hmac one two Tensor[U8 * 64] Tensor[U8 * 64] Int Int` | `Tensor[U8 * 32]` |
| `86` | `arch :: sha256 hmac keys Tensor[U8 * 64]` | `Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` |
| `87` | `arch :: sha256 hmac outer bytes Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U8 * 32]` |
| `88` | `idem :: sha256 pad Int` | `String` |
| `89` | `idem :: sha256 zeros Int` | `String` |
| `90` | `fn :: sha256 group4 Int Int Int Int` | `Tensor[U32]` |
| `91` | `idem :: sha256 iv a` | `Tensor[U32]` |
| `92` | `idem :: sha256 iv e` | `Tensor[U32]` |
| `93` | `fn :: sha256 full bytes String Int` | `Tensor[U8]` |
| `94` | `fn :: sha256 after full String Int Tensor[U32] Tensor[U32]` | `Tensor[U32] Tensor[U32]` |
| `95` | `fn :: sha256 end block String Int` | `Tensor[U8]` |
| `96` | `fn :: sha256 one end Int` | `Bool` |
| `97` | `fn :: sha256 words (Tensor[U32], Tensor[U32]) String Int` | `Tensor[U32] Tensor[U32]` |
| `98` | `fn :: sha256 digest of (Tensor[U32], Tensor[U32]) String` | `String` |
| `99` | `fn :: sha256 hex String` | `String` |
| `100` | `fn :: sha256 bytes String` | `String` |
| `101` | `fn :: sha256 bytes short String Int` | `String` |
| `102` | `fn :: sha256 bytes mid String Tensor[U8] Int` | `String` |
| `103` | `fn :: sha256 raw String` | `String` |
| `104` | `fn :: sha256 str String` | `String` |
| `105` | `fn :: sha256 digest Tensor[U8]` | `Tensor[U8]` |
| `106` | `fn :: sha256 file String` | `String` |
| `107` | `fn :: sha256 file from Int` | `String` |
| `108` | `fn :: sha256 file step Int Tensor[U32] Tensor[U32] String Int String` | `String` |
| `109` | `fn :: sha256 file more Int (Tensor[U32], Tensor[U32]) String Int` | `String` |
| `110` | `fn :: sha256 file end Int (Tensor[U32], Tensor[U32])` | `String` |
| `111` | `fn :: bitxor key pad loop Tensor[U8] Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `112` | `fn :: bitxor key pad Tensor[U8] Int` | `Tensor[U8]` |
| `113` | `fn :: c hmac key block String Int` | `Tensor[U8]` |
| `114` | `fn :: hmac sha256 String String` | `String` |
| `115` | `fn :: hmac sha256 key block String` | `Tensor[U8]` |
| `116` | `fn :: hmac sha256 long (Tensor[U32], Tensor[U32], Tensor[U32], Tensor[U32]) String` | `String` |
| `117` | `fn :: ct diff str String String Int Int Int` | `Int` |
| `118` | `fn :: ct equal String String` | `Bool` |
| `119` | `fn :: bitxor byte lists loop Tensor[U8] Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `120` | `fn :: bitxor byte lists Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `121` | `fn :: bitxor byte strings String String` | `String` |
| `122` | `fn :: be32 bytes Int` | `String` |
| `123` | `fn :: c get16 CT16 Int` | `A` |
| `124` | `fn :: c set16 CT16 Int A` | `CT16` |
| `125` | `fn :: c build b16 Int` | `CT16` |
| `126` | `fn :: c build b256` | `CT16` |
| `127` | `fn :: c get b256 CT16 Int Int` | `String` |
| `128` | `fn :: c hex nib Int` | `Int` |
| `129` | `fn :: c hex pair CT16 String Int` | `String` |
| `130` | `fn :: c hex2raw4 CT16 String Int` | `String` |
| `131` | `fn :: c hex2raw32 CT16 String` | `String` |
| `132` | `fn :: c hex8 word String Int` | `U64` |
| `133` | `fn :: c bxor acc8 Tensor[U64 * 8] String` | `Tensor[U64 * 8]` |
| `134` | `fn :: c word32 to raw4 CT16 U64` | `String` |
| `135` | `fn :: c acc8 to raw CT16 Tensor[U64 * 8]` | `String` |
| `136` | `fn :: pbkdf2 hmac sha256 String String Int Int` | `String` |
| `137` | `fn :: pbkdf2 block (Tensor[U32], Tensor[U32], Tensor[U32], Tensor[U32]) String Int Int` | `String` |
| `138` | `fn :: pbkdf2 out (Tensor[U32], Tensor[U32])` | `String` |
| `139` | `fn :: pbkdf2 blocks (Tensor[U32], Tensor[U32], Tensor[U32], Tensor[U32]) String Int Int Int String` | `String` |
| `140` | `fn :: f blamka U64 U64` | `U64` |
| `141` | `fn :: blamka g U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `142` | `fn :: blamka p16 Tensor[U64 * 16]` | `()` |
| `143` | `fn :: ca2 blamka col pair Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `144` | `fn :: ca2 blamka cols loop Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `145` | `fn :: compress block Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `146` | `fn :: le32 at Tensor[U8] Int` | `Int` |
| `147` | `fn :: chacha rounds Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Int` | `Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n]` |
| `148` | `fn :: chacha fill counter Tensor[U32 * n] Int Int Int` | `Tensor[U32 * n]` |
| `149` | `fn :: chacha page Tensor[U8] Tensor[U8] Int Int` | `Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n] Tensor[U32 * n]` |
| `150` | `fn :: c bytes part Tensor[U8] Int Int` | `Tensor[U8]` |
| `151` | `fn :: c first bytes Tensor[U8] Int Int` | `Tensor[U8]` |
| `152` | `fn :: chacha20 key stream chunk Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `153` | `arch :: chacha quarter Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` |
| `154` | `arch :: chacha double Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` | `Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4]` |
| `155` | `arch :: chacha one block Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Int` | `Tensor[U8 * 64]` |
| `156` | `fn :: chacha block rows Tensor[U8 * n * 64] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Int Int Int` | `Tensor[U8 * n * 64]` |
| `157` | `fn :: chacha key words Tensor[U8] Int` | `Tensor[U32 * 4]` |
| `158` | `fn :: chacha nonce words Tensor[U8]` | `Tensor[U32 * 4]` |
| `159` | `fn :: chacha20 key stream blocks Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `160` | `fn :: chacha20 key stream pieces Tensor[U8] Tensor[U8] Int Int` | `[String]` |
| `161` | `fn :: chacha20 key stream Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `162` | `fn :: chacha20 block Tensor[U8] Tensor[U8] Int` | `Tensor[U8]` |
| `163` | `fn :: c bitxor bytes Tensor[U8 * n] Tensor[U8 * n]` | `Tensor[U8 * n]` |
| `164` | `fn :: chacha20 bitxor Tensor[U8] Tensor[U8] Int Tensor[U8]` | `Tensor[U8]` |
| `165` | `fn :: poly1305 r limbs Tensor[U8]` | `Tensor[Int * 5]` |
| `166` | `fn :: poly1305 step Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int` | `Tensor[Int * 5]` |
| `167` | `fn :: poly1305 blocks loop Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int Int` | `Tensor[Int * 5]` |
| `168` | `fn :: poly1305 carry into Int Int Int Int Int Tensor[Int * j] Int` | `Int` |
| `169` | `arch :: poly1305 quad Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U8 * 64] Int Int Int Int Int Int Int Int Int` | `Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4]` |
| `170` | `arch :: poly1305 quad last Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U8 * 64] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4]` | `Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4]` |
| `171` | `fn :: poly1305 quads Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U8 * n * 64] Int Int Int Int Int Int Int Int Int Int Int` | `Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4]` |
| `172` | `fn :: poly1305 quads last Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U8 * n * 64] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Int Int` | `Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4]` |
| `173` | `fn :: poly1305 mul Tensor[Int * 5] Tensor[Int * 5]` | `Tensor[Int * 5]` |
| `174` | `fn :: poly1305 quad powers Tensor[Int * 5] Tensor[Int * 5] Tensor[Int * 5] Tensor[Int * 5] Int` | `Tensor[U64 * 4]` |
| `175` | `fn :: poly1305 quad start Int` | `Tensor[U64 * 4]` |
| `176` | `fn :: poly1305 quad sum Tensor[U64 * 4]` | `Int` |
| `177` | `fn :: poly1305 quad run Tensor[Int * 5] Tensor[Int * 5] Tensor[Int * 5] Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int` | `Tensor[Int * 5]` |
| `178` | `fn :: poly1305 quad from Tensor[Int * 5] Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int` | `Tensor[Int * 5]` |
| `179` | `fn :: poly1305 quad bytes Tensor[U8] Int` | `Tensor[U8]` |
| `180` | `fn :: poly1305 quad rows Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int` | `Tensor[Int * 5]` |
| `181` | `fn :: poly1305 quad count Int` | `Int` |
| `182` | `fn :: c pick Bool Int Int` | `Int` |
| `183` | `fn :: poly1305 finalize Tensor[Int * 5] Tensor[U8]` | `Tensor[U8]` |
| `184` | `fn :: pad16 len Int` | `Int` |
| `185` | `fn :: c put le64 Tensor[U8] Int Int` | `Int` |
| `186` | `fn :: poly1305 aead mac Tensor[U8] Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `187` | `fn :: aead key stream Tensor[U8] Tensor[U8] Int` | `Tensor[U8]` |
| `188` | `fn :: aead seal String String String String` | `String` |
| `189` | `fn :: decrypt verified aead Bool Tensor[U8] Tensor[U8]` | `Int String` |
| `190` | `fn :: aead open String String String String` | `Int String` |
| `191` | `fn :: sha512 k hex0` | `String` |
| `192` | `fn :: sha512 k hex1` | `String` |
| `193` | `fn :: sha512 fill hex words Tensor[U64 * 160] String Int Int` | `Tensor[U64 * 160]` |
| `194` | `fn :: sha512 init k` | `Tensor[U64 * 160]` |
| `195` | `fn :: sha512 init h loop Tensor[U64 * 16] String Int` | `Tensor[U64 * 16]` |
| `196` | `fn :: sha512 init h` | `Tensor[U64 * 16]` |
| `197` | `fn :: sha512 rrot lt32 U64 U64 Int` | `U64 U64` |
| `198` | `fn :: sha512 rshift lt32 U64 U64 Int` | `U64 U64` |
| `199` | `fn :: sha512 big sigma0 U64 U64` | `U64 U64` |
| `200` | `fn :: sha512 big sigma1 U64 U64` | `U64 U64` |
| `201` | `fn :: sha512 small sigma0 U64 U64` | `U64 U64` |
| `202` | `fn :: sha512 small sigma1 U64 U64` | `U64 U64` |
| `203` | `fn :: sha512 vbyte String Int Int Int` | `U64` |
| `204` | `fn :: sha512 load w fast Tensor[U64 * 160] String Int Int` | `Tensor[U64 * 160]` |
| `205` | `fn :: sha512 load w pad Tensor[U64 * 160] String Int Int Int Int` | `Tensor[U64 * 160]` |
| `206` | `fn :: sha512 expand w Tensor[U64 * 160] Int` | `Tensor[U64 * 160]` |
| `207` | `fn :: sha512 copy state Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `208` | `fn :: sha512 add state Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `209` | `fn :: sha512 rounds loop Tensor[U64 * 16] Tensor[U64 * 160] Tensor[U64 * 160] Int` | `Tensor[U64 * 16]` |
| `210` | `fn :: sha512 blocks loop Tensor[U64 * 16] Tensor[U64 * 16] Tensor[U64 * 160] Tensor[U64 * 160] String Int Int Int` | `Tensor[U64 * 16]` |
| `211` | `fn :: sha512 state to raw CT16 Tensor[U64 * 16] Int` | `String` |
| `212` | `fn :: sha512 bytes String` | `String` |
| `213` | `fn :: sha512 hex String` | `String` |
| `214` | `fn :: fe lit U64 U64 U64 U64 U64 U64 U64 U64 U64 U64` | `Tensor[U64 * 10]` |
| `215` | `fn :: fe zero` | `Tensor[U64 * 10]` |
| `216` | `fn :: fe one` | `Tensor[U64 * 10]` |
| `217` | `fn :: fe d` | `Tensor[U64 * 10]` |
| `218` | `fn :: fe d2` | `Tensor[U64 * 10]` |
| `219` | `fn :: fe sqrt m1` | `Tensor[U64 * 10]` |
| `220` | `fn :: fe bx` | `Tensor[U64 * 10]` |
| `221` | `fn :: fe by` | `Tensor[U64 * 10]` |
| `222` | `fn :: fe bt` | `Tensor[U64 * 10]` |
| `223` | `fn :: fe carry pass Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `224` | `fn :: fe carry Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `225` | `fn :: fe add Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `226` | `fn :: fe sub Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `227` | `fn :: fe mul Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `228` | `fn :: fe sq Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `229` | `fn :: fe sq n Tensor[U64 * 10] Int` | `Tensor[U64 * 10]` |
| `230` | `fn :: fe freeze Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `231` | `fn :: fe eq Tensor[U64 * 10] Tensor[U64 * 10]` | `Bool` |
| `232` | `fn :: fe pow22523 Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `233` | `fn :: fe invert Tensor[U64 * 10]` | `Tensor[U64 * 10]` |
| `234` | `fn :: fe to words8 Tensor[U64 * 10]` | `Tensor[U64 * 8]` |
| `235` | `fn :: words8 to raw32 loop CT16 Tensor[U64 * 8] Int` | `String` |
| `236` | `fn :: raw32 to words8 String` | `Tensor[U64 * 8]` |
| `237` | `fn :: fe from raw32 String` | `Bool U64 Tensor[U64 * 10]` |
| `238` | `fn :: ge pack Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10]` | `Tensor[U64 * 40]` |
| `239` | `fn :: ge coord Tensor[U64 * 40] Int` | `Tensor[U64 * 10]` |
| `240` | `fn :: ge zero` | `Tensor[U64 * 40]` |
| `241` | `fn :: ge base` | `Tensor[U64 * 40]` |
| `242` | `fn :: ge add Tensor[U64 * 40] Tensor[U64 * 40]` | `Tensor[U64 * 40]` |
| `243` | `fn :: ge dbl Tensor[U64 * 40]` | `Tensor[U64 * 40]` |
| `244` | `fn :: ge cselect loop Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 40] U64 Int` | `Tensor[U64 * 40]` |
| `245` | `fn :: ge cselect Tensor[U64 * 40] Tensor[U64 * 40] U64` | `Tensor[U64 * 40]` |
| `246` | `fn :: ge scalarmult loop Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 8] Int` | `Tensor[U64 * 40]` |
| `247` | `fn :: ge scalarmult ct Tensor[U64 * 40] Tensor[U64 * 8]` | `Tensor[U64 * 40]` |
| `248` | `fn :: ge to bytes Tensor[U64 * 40]` | `String` |
| `249` | `fn :: ge finish sign Bool Bool Tensor[U64 * 10] Tensor[U64 * 10]` | `Bool Tensor[U64 * 40]` |
| `250` | `fn :: ge decompress step2 Tensor[U64 * 10] Tensor[U64 * 10] U64` | `Bool Tensor[U64 * 40]` |
| `251` | `fn :: ge check root Bool Bool Tensor[U64 * 10] Tensor[U64 * 10] U64` | `Bool Tensor[U64 * 40]` |
| `252` | `fn :: ge decompress y Bool U64 Tensor[U64 * 10]` | `Bool Tensor[U64 * 40]` |
| `253` | `fn :: ge from bytes String` | `Bool Tensor[U64 * 40]` |
| `254` | `fn :: sc l words` | `Tensor[U64 * 8]` |
| `255` | `fn :: sc lt l loop Tensor[U64 * 8] Tensor[U64 * 8] Int` | `Bool` |
| `256` | `fn :: sc lt l Tensor[U64 * 8]` | `Bool` |
| `257` | `fn :: sc sub word U64 U64` | `U64 U64` |
| `258` | `fn :: sc sub l loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int U64` | `Tensor[U64 * 8]` |
| `259` | `fn :: sc sub l Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `260` | `fn :: sc norm l Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `261` | `fn :: sc add raw loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int U64` | `Tensor[U64 * 8]` |
| `262` | `fn :: sc add mod l Tensor[U64 * 8] Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `263` | `fn :: sc zero` | `Tensor[U64 * 8]` |
| `264` | `fn :: sc one` | `Tensor[U64 * 8]` |
| `265` | `fn :: sc cond add bit Bool Tensor[U64 * 8] Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `266` | `fn :: sc reduce byte bits Tensor[U64 * 8] Tensor[U64 * 8] U64 Int` | `Tensor[U64 * 8]` |
| `267` | `fn :: sc reduce le64 loop Tensor[U64 * 8] Tensor[U64 * 8] String Int` | `Tensor[U64 * 8]` |
| `268` | `fn :: sc reduce le64 String` | `Tensor[U64 * 8]` |
| `269` | `fn :: sc mul word bits Tensor[U64 * 8] Tensor[U64 * 8] U64 Int` | `Tensor[U64 * 8]` |
| `270` | `fn :: sc mul mod l loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int` | `Tensor[U64 * 8]` |
| `271` | `fn :: sc muladd mod l Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8]` | `Tensor[U64 * 8]` |
| `272` | `fn :: ed25519 clamp scalar String` | `Tensor[U64 * 8]` |
| `273` | `fn :: ed25519 public key String` | `String` |
| `274` | `fn :: ed25519 sign String String` | `String` |
| `275` | `fn :: ed25519 verify points Bool Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 8] String String String` | `Bool` |
| `276` | `fn :: ed25519 verify scalar Bool String String String Tensor[U64 * 8]` | `Bool` |
| `277` | `fn :: ed25519 verify String String String` | `Bool` |
| `278` | `fn :: c is ws Int` | `Bool` |
| `279` | `fn :: c trim start String Int Int` | `Int` |
| `280` | `fn :: c trim end String Int Int` | `Int` |
| `281` | `fn :: c trim String` | `String` |
| `282` | `fn :: c starts with String String` | `Bool` |
| `283` | `fn :: c split lines loop String Int Int Int [String]` | `[String]` |
| `284` | `fn :: c split lines trimmed String Int` | `[String]` |
| `285` | `fn :: c split lines String` | `[String]` |
| `286` | `fn :: c b64 table` | `String` |
| `287` | `fn :: c b64 ch Int` | `String` |
| `288` | `fn :: c b64 encode loop String Int Int` | `String` |
| `289` | `fn :: c b64 encode String` | `String` |
| `290` | `fn :: c b64 val Int` | `Int` |
| `291` | `fn :: c b64 quad CT16 String Int Int String Int Int Int Int` | `Bool String` |
| `292` | `fn :: c b64 decode loop CT16 String Int Int String` | `Bool String` |
| `293` | `fn :: c b64 decode trimmed String Int` | `Bool String` |
| `294` | `fn :: c b64 decode String` | `Bool String` |
| `295` | `fn :: c nth str [String] Int` | `String` |
| `296` | `fn :: c str list len [String] Int` | `Int` |
| `297` | `fn :: minisign encode pubkey String String` | `String` |
| `298` | `fn :: minisign select pubkey line [String] Int` | `String` |
| `299` | `fn :: minisign unpack pubkey Bool String` | `String String` |
| `300` | `fn :: minisign decode pubkey String` | `String String` |
| `301` | `fn :: minisign sign String String String String String` | `String` |
| `302` | `fn :: minisign extract tc line String` | `String` |
| `303` | `fn :: minisign extract tc lines [String] Int` | `String` |
| `304` | `fn :: minisign trusted comment String` | `String` |
| `305` | `fn :: minisign payload for alg String String` | `Bool String` |
| `306` | `fn :: minisign check sigs Bool String String String String String String` | `Bool` |
| `307` | `fn :: minisign verify decoded Bool String String String String String` | `Bool` |
| `308` | `fn :: minisign verify body Bool String String String String String String` | `Bool` |
| `309` | `fn :: minisign verify lines Bool String String String [String]` | `Bool` |
| `310` | `fn :: minisign verify String String String` | `Bool` |
| `311` | `fn :: sha384 init h` | `Tensor[U64 * 16]` |
| `312` | `fn :: sha384 state to raw CT16 Tensor[U64 * 16] Int` | `String` |
| `313` | `fn :: sha384 bytes String` | `String` |
| `314` | `fn :: sha384 hex String` | `String` |
| `315` | `fn :: normalize hmac384 key String` | `Tensor[U8]` |
| `316` | `fn :: hmac sha384 String String` | `String` |
| `317` | `fn :: c repeat byte Int Int` | `String` |
| `318` | `fn :: hkdf extract String String` | `String` |
| `319` | `fn :: hkdf expand loop String String Int Int String String` | `String` |
| `320` | `fn :: hkdf expand String String Int` | `String` |
| `321` | `fn :: hkdf extract sha384 String String` | `String` |
| `322` | `fn :: hkdf expand sha384 loop String String Int Int String String` | `String` |
| `323` | `fn :: hkdf expand sha384 String String Int` | `String` |
| `324` | `fn :: hkdf expand label String String String Int` | `String` |
| `325` | `fn :: derive secret String String String` | `String` |
| `326` | `fn :: fe a24` | `Tensor[U64 * 10]` |
| `327` | `fn :: fe cswap loop Tensor[U64 * 10] Tensor[U64 * 10] U64 Int` | `Tensor[U64 * 10] Tensor[U64 * 10]` |
| `328` | `fn :: fe cswap Tensor[U64 * 10] Tensor[U64 * 10] U64` | `Tensor[U64 * 10] Tensor[U64 * 10]` |
| `329` | `fn :: x25519 clamp scalar String` | `Tensor[U64 * 8]` |
| `330` | `fn :: x25519 decode u String` | `Tensor[U64 * 10]` |
| `331` | `fn :: x25519 ladder loop Tensor[U64 * 8] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] U64 Int` | `Tensor[U64 * 10] Tensor[U64 * 10]` |
| `332` | `fn :: x25519 check non zero String` | `String` |
| `333` | `fn :: x25519 String String` | `String` |
| `334` | `fn :: x25519 public key String` | `String` |
| `335` | `arch :: aes round Tensor[U8 * 16] Tensor[U8 * 16] Tensor[U8 * 256]` | `Tensor[U8 * 16]` |
| `336` | `arch :: aes last round Tensor[U8 * 16] Tensor[U8 * 16] Tensor[U8 * 256]` | `Tensor[U8 * 16]` |
| `337` | `arch :: aes128 encrypt block Tensor[U8 * 16] Tensor[U8 * 11 * 16] Tensor[U8 * 256]` | `Tensor[U8 * 16]` |
| `338` | `arch :: aes256 encrypt block Tensor[U8 * 16] Tensor[U8 * 15 * 16] Tensor[U8 * 256]` | `Tensor[U8 * 16]` |
| `339` | `arch :: aes128 ctr block Tensor[U8 * 16] Tensor[U8 * 11 * 16] Tensor[U8 * 256] Int` | `Tensor[U8 * 16]` |
| `340` | `arch :: aes256 ctr block Tensor[U8 * 16] Tensor[U8 * 15 * 16] Tensor[U8 * 256] Int` | `Tensor[U8 * 16]` |
| `341` | `fn :: aes128 ctr rows Tensor[U8 * n * 16] Tensor[U8 * 16] Tensor[U8 * 11 * 16] Tensor[U8 * 256] Int Int Int` | `Tensor[U8 * n * 16]` |
| `342` | `fn :: aes256 ctr rows Tensor[U8 * n * 16] Tensor[U8 * 16] Tensor[U8 * 15 * 16] Tensor[U8 * 256] Int Int Int` | `Tensor[U8 * n * 16]` |
| `343` | `fn :: aes rotl8 Int Int` | `Int` |
| `344` | `fn :: aes box fill Tensor[U8] Int Int Bool` | `Tensor[U8]` |
| `345` | `idem :: aes make box` | `Tensor[U8]` |
| `346` | `fn :: aes key byte Tensor[U8] Int Int` | `Int` |
| `347` | `fn :: aes put word Tensor[U8] Int Int Int Int Int` | `Tensor[U8]` |
| `348` | `fn :: aes expand Tensor[U8] Tensor[U8] Int Int Int Int` | `Tensor[U8]` |
| `349` | `fn :: aes set key Tensor[U8] String Int Int` | `Tensor[U8]` |
| `350` | `fn :: aes128 keys Tensor[U8] String` | `Tensor[U8]` |
| `351` | `fn :: aes256 keys Tensor[U8] String` | `Tensor[U8]` |
| `352` | `fn :: aes iv16 String` | `Tensor[U8]` |
| `353` | `fn :: aes128 key stream Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `354` | `fn :: aes256 key stream Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `355` | `fn :: aes128 block String String` | `String` |
| `356` | `fn :: aes256 block String String` | `String` |
| `357` | `arch :: ghash times Tensor[U64 * 2] Tensor[U64 * 2]` | `Tensor[U64 * 2]` |
| `358` | `arch :: ghash words Tensor[U8 * 16]` | `Tensor[U64 * 2]` |
| `359` | `arch :: ghash block bytes Tensor[U64 * 2]` | `Tensor[U8 * 16]` |
| `360` | `arch :: ghash step Tensor[U64 * 2] Tensor[U64 * 2] Tensor[U8 * 16]` | `Tensor[U64 * 2]` |
| `361` | `fn :: ghash rows Tensor[U64 * 2] Tensor[U64 * 2] Tensor[U8 * n * 16] Int Int` | `Tensor[U64 * 2]` |
| `362` | `fn :: ghash padded Tensor[U8] Int` | `Tensor[U8]` |
| `363` | `fn :: ghash absorb Tensor[U64 * 2] Tensor[U64 * 2] Tensor[U8] Int` | `Tensor[U64 * 2]` |
| `364` | `fn :: ghash lengths Int Int` | `Tensor[U64 * 2]` |
| `365` | `arch :: ghash last Tensor[U64 * 2] Tensor[U64 * 2] Tensor[U64 * 2]` | `Tensor[U64 * 2]` |
| `366` | `fn :: ghash compute Tensor[U8] Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `367` | `fn :: aes gcm tag String String String Tensor[U8]` | `String` |
| `368` | `fn :: aes gcm seal parts String String Tensor[U8] String String` | `String` |
| `369` | `fn :: aes128 gcm seal String String String String` | `String` |
| `370` | `fn :: aes128 gcm open verified Bool Tensor[U8] Tensor[U8] String Tensor[U8]` | `Int String` |
| `371` | `fn :: aes128 gcm open String String String String` | `Int String` |
| `372` | `fn :: aes256 gcm seal String String String String` | `String` |
| `373` | `fn :: aes256 gcm open verified Bool Tensor[U8] Tensor[U8] String Tensor[U8]` | `Int String` |
| `374` | `fn :: aes256 gcm open String String String String` | `Int String` |
| `375` | `fn :: bn zero loop Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `376` | `fn :: bn zero Int` | `Tensor[U64 * 260]` |
| `377` | `fn :: bn zero520 loop Tensor[U64 * 520] Int Int` | `Tensor[U64 * 520]` |
| `378` | `fn :: bn zero520 Int` | `Tensor[U64 * 520]` |
| `379` | `fn :: bn clone loop Tensor[U64 * 260] Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `380` | `fn :: bn clone Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `381` | `fn :: bn strip leading zeroes String Int Int` | `String` |
| `382` | `fn :: bn from be loop Tensor[U64 * 260] String Int Int Int` | `Tensor[U64 * 260]` |
| `383` | `fn :: bn from be String Int` | `Tensor[U64 * 260]` |
| `384` | `fn :: bn from hex String Int` | `Tensor[U64 * 260]` |
| `385` | `fn :: bn to be loop CT16 Tensor[U64 * 260] Int String String String String` | `String` |
| `386` | `fn :: bn to be Tensor[U64 * 260] Int` | `String` |
| `387` | `fn :: bn is zero loop Tensor[U64 * 260] Int Int` | `Bool` |
| `388` | `fn :: bn is zero Tensor[U64 * 260] Int` | `Bool` |
| `389` | `fn :: bn cmp loop Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Int` |
| `390` | `fn :: bn cmp Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Int` |
| `391` | `fn :: bn add raw loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int U64` | `U64` |
| `392` | `fn :: bn sub raw loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int U64` | `U64` |
| `393` | `fn :: bn add mod finish Bool Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `394` | `fn :: bn add mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `395` | `fn :: bn sub mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `396` | `fn :: bn mul row loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int U64` | `Tensor[U64 * 520]` |
| `397` | `fn :: bn mul full loop Tensor[U64 * 520] Tensor[U64 * 260] Tensor[U64 * 260] Int Int` | `Tensor[U64 * 520]` |
| `398` | `fn :: bn sub qm loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int U64` | `Tensor[U64 * 520]` |
| `399` | `fn :: bn cmp520 offset loop Tensor[U64 * 520] Int Tensor[U64 * 260] Int` | `Int` |
| `400` | `fn :: bn ge520 offset Tensor[U64 * 520] Int Tensor[U64 * 260] Int` | `Bool` |
| `401` | `fn :: bn sub m while ge Tensor[U64 * 520] Int Tensor[U64 * 260] Int` | `Tensor[U64 * 520]` |
| `402` | `fn :: bn reduce step q Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int` | `Tensor[U64 * 520]` |
| `403` | `fn :: bn reduce loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int` | `Tensor[U64 * 520]` |
| `404` | `fn :: bn copy520 to out Tensor[U64 * 260] Tensor[U64 * 520] Int Int` | `Tensor[U64 * 260]` |
| `405` | `fn :: bn reduce520 Tensor[U64 * 520] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `406` | `fn :: bn mul mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `407` | `fn :: bn sq mod Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `408` | `fn :: bn mod from be String Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `409` | `fn :: bn mont loop Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Int Int` | `Tensor[U64 * n] Tensor[U64 * n]` |
| `410` | `fn :: bn mont carry Tensor[U64 * n] Tensor[U64 * 260] Int Int Int` | `Int` |
| `411` | `fn :: bn mont mul BnMont Tensor[U64 * 260] Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `412` | `fn :: bn mont ix Tensor[U64 * n] Int Int Int` | `Tensor[U64 * n]` |
| `413` | `fn :: bn mont minv Int` | `Int` |
| `414` | `fn :: bn mont pow2 BnMont Tensor[U64 * 260] Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `415` | `fn :: bn mont ctx Tensor[U64 * 260] Int` | `BnMont` |
| `416` | `fn :: bn mont mul mod BnMont Tensor[U64 * 260] Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `417` | `fn :: bn mont sq BnMont Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `418` | `fn :: bn mont in BnMont Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `419` | `fn :: bn mont out BnMont Tensor[U64 * 260]` | `Tensor[U64 * 260]` |
| `420` | `fn :: bn mont pow bits Tensor[U64 * 260] BnMont Tensor[U64 * 260] Int Int` | `Tensor[U64 * 260]` |
| `421` | `fn :: bn mont pow bytes Tensor[U64 * 260] BnMont Tensor[U64 * 260] String Int Int` | `Tensor[U64 * 260]` |
| `422` | `fn :: bn mont pow BnMont Tensor[U64 * 260] String` | `Tensor[U64 * 260]` |
| `423` | `fn :: bn mod exp bits loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int Int` | `Tensor[U64 * 260]` |
| `424` | `fn :: bn mod exp bytes loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int String Int Int` | `Tensor[U64 * 260]` |
| `425` | `fn :: bn mod exp plain Tensor[U64 * 260] String Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `426` | `fn :: bn mod exp mont Tensor[U64 * 260] String BnMont` | `Tensor[U64 * 260]` |
| `427` | `fn :: bn mod exp Tensor[U64 * 260] String Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `428` | `fn :: bn mod inv Tensor[U64 * 260] Tensor[U64 * 260] Int` | `Tensor[U64 * 260]` |
| `429` | `fn :: p256 curve` | `EcCurve` |
| `430` | `fn :: p384 curve` | `EcCurve` |
| `431` | `fn :: ec inf point Int` | `EcPoint` |
| `432` | `fn :: ec affine point EcCurve Tensor[U64 * 260] Tensor[U64 * 260]` | `EcPoint` |
| `433` | `fn :: ec point on curve EcCurve Tensor[U64 * 260] Tensor[U64 * 260]` | `Bool` |
| `434` | `fn :: ec dbl EcCurve EcPoint` | `EcPoint` |
| `435` | `fn :: ec add diff EcCurve EcPoint Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260]` | `EcPoint` |
| `436` | `fn :: ec add EcCurve EcPoint EcPoint` | `EcPoint` |
| `437` | `fn :: ec to affine EcCurve EcPoint` | `Bool Tensor[U64 * 260] Tensor[U64 * 260]` |
| `438` | `fn :: ec cselect bn loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] U64 Int Int` | `Tensor[U64 * 260]` |
| `439` | `fn :: ec cselect point EcPoint EcPoint U64 Int` | `EcPoint` |
| `440` | `fn :: ec scalar mul loop EcCurve EcPoint EcPoint Tensor[U64 * 260] Int` | `EcPoint` |
| `441` | `fn :: ec scalar mul EcCurve EcPoint Tensor[U64 * 260]` | `EcPoint` |
| `442` | `fn :: ec shamir loop EcCurve EcPoint EcPoint EcPoint EcPoint Tensor[U64 * 260] Tensor[U64 * 260] Int` | `EcPoint` |
| `443` | `fn :: p256 public key inner EcCurve Tensor[U64 * 260]` | `String` |
| `444` | `fn :: p256 public key String` | `String` |
| `445` | `fn :: p256 ecdh inner EcCurve Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260]` | `String` |
| `446` | `fn :: p256 ecdh String String` | `String` |
| `447` | `fn :: ecdsa unpack der rs Bool Int Int Int Int Bool Int Int Int String Int` | `Bool String String` |
| `448` | `fn :: ecdsa unpack der seq Bool Int Int String Int` | `Bool String String` |
| `449` | `fn :: ecdsa unpack sig String Int` | `Bool String String` |
| `450` | `fn :: ecdsa verify shamir EcCurve Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] String Int` | `Bool` |
| `451` | `fn :: ecdsa verify curve EcCurve String String String` | `Bool` |
| `452` | `fn :: ecdsa p256 verify String String String` | `Bool` |
| `453` | `fn :: ecdsa p256 verify sha256 String String String` | `Bool` |
| `454` | `fn :: ecdsa p384 verify String String String` | `Bool` |
| `455` | `fn :: ecdsa p384 verify sha384 String String String` | `Bool` |
| `456` | `fn :: rsa mod exp inner String String String Int` | `String` |
| `457` | `fn :: rsa mod exp String String String` | `String` |
| `458` | `fn :: rsa hash msg String String` | `String` |
| `459` | `fn :: rsa digest info prefix String` | `String` |
| `460` | `fn :: rsa verify pkcs1 inner String String String String String Int` | `Bool` |
| `461` | `fn :: rsa verify pkcs1 String String String String String` | `Bool` |
| `462` | `fn :: rsa mgf1 loop String String Int Int String` | `String` |
| `463` | `fn :: rsa pss check db zeroes String Int Int` | `Bool` |
| `464` | `fn :: rsa pss unmask db CT16 String String Int Int String` | `String` |
| `465` | `fn :: rsa verify pss em String String String Int Int` | `Bool` |
| `466` | `fn :: rsa verify pss inner String String String String String Int` | `Bool` |
| `467` | `fn :: rsa verify pss String String String String String` | `Bool` |
| `468` | `fn :: pem strip ws step Bool CT16 Int String Int Int String String String String` | `String` |
| `469` | `fn :: pem strip ws loop CT16 String Int Int String String String String` | `String` |
| `470` | `fn :: pem decode b64 block CT16 String` | `Bool String` |
| `471` | `fn :: pem find sub from String String Int Int Int` | `Int` |
| `472` | `fn :: pem decode blocks step CT16 String String String Int Int Int [String]` | `[String]` |
| `473` | `fn :: pem decode blocks loop CT16 String String String Int Int [String]` | `[String]` |
| `474` | `fn :: pem decode blocks String String` | `[String]` |
| `475` | `fn :: asn1 read len bytes String Int Int Int` | `Int` |
| `476` | `fn :: asn1 finish tlv Bool Int Int Int Int Int` | `Bool Int Int Int Int` |
| `477` | `fn :: asn1 parse long len String Int Int Int Int` | `Bool Int Int Int Int` |
| `478` | `fn :: asn1 parse len dispatch String Int Int Int Int` | `Bool Int Int Int Int` |
| `479` | `fn :: asn1 parse tlv String Int` | `Bool Int Int Int Int` |
| `480` | `fn :: x509 parse dec2 String Int` | `Int` |
| `481` | `fn :: x509 days from civil Int Int Int` | `Int` |
| `482` | `fn :: x509 parse time tag Int String` | `Int` |
| `483` | `fn :: x509 parse validity inner Bool Int Int Int Int Int Int String` | `Int Int` |
| `484` | `fn :: x509 parse validity String Int Int` | `Int Int` |
| `485` | `fn :: x509 check cn attr Bool String Int Int Int` | `String` |
| `486` | `fn :: x509 find cn in rdn String Int Int` | `String` |
| `487` | `fn :: x509 parse sig alg oid String String` | `String` |
| `488` | `fn :: x509 parse sig alg String Int Int` | `String` |
| `489` | `fn :: x509 parse rsa spki String` | `String String String` |
| `490` | `fn :: x509 parse ec spki String Int String` | `String String String` |
| `491` | `fn :: x509 dispatch spki oid String String Int String` | `String String String` |
| `492` | `fn :: x509 parse spki inner Bool String Int Int Int` | `String String String` |
| `493` | `fn :: x509 parse spki String Int Int` | `String String String` |
| `494` | `fn :: x509 parse san entry Bool Int Int Int Int String Int [String]` | `[String]` |
| `495` | `fn :: x509 parse san loop String Int Int [String]` | `[String]` |
| `496` | `fn :: x509 ext octet span String Bool Int Int Int Int` | `Int Int` |
| `497` | `fn :: x509 dispatch ext oid String String Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `498` | `fn :: x509 parse single ext inner Bool String Int Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `499` | `fn :: x509 parse single ext String Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `500` | `fn :: x509 parse exts step Bool String Int Int Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `501` | `fn :: x509 parse exts loop String Int Int [String] Bool Int Bool` | `[String] Bool Int Bool` |
| `502` | `fn :: x509 find exts step Bool Int Int Int String Int` | `[String] Bool Int Bool` |
| `503` | `fn :: x509 find exts in tbs String Int Int` | `[String] Bool Int Bool` |
| `504` | `fn :: x509 empty cert` | `X509Cert` |
| `505` | `fn :: x509 parse cert tbs Bool String Int Int Int Int Int Int Int` | `Bool X509Cert` |
| `506` | `fn :: x509 parse cert outer Bool String Int` | `Bool X509Cert` |
| `507` | `fn :: x509 parse cert String` | `Bool X509Cert` |
| `508` | `fn :: x509 ascii lower char Int` | `String` |
| `509` | `fn :: x509 to lower loop String Int Int String` | `String` |
| `510` | `fn :: x509 to lower String` | `String` |
| `511` | `fn :: x509 count dots loop String Int Int Int` | `Int` |
| `512` | `fn :: x509 first dot String Int Int` | `Int` |
| `513` | `fn :: x509 match single san inner String String` | `Bool` |
| `514` | `fn :: x509 match single san String String` | `Bool` |
| `515` | `fn :: x509 match san list [String] String` | `Bool` |
| `516` | `fn :: x509 match hostname X509Cert String` | `Bool` |
| `517` | `fn :: x509 verify signature String String String String String String` | `Bool` |
| `518` | `fn :: x509 verify cert sig X509Cert X509Cert` | `Bool` |

---

## 24.3. `crypto` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `crypto` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test crypto.ridgun`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 24.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `crypto` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `crypto` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

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

### 24.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`crypto` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 38 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import crypto

fn :: verificar firma webhook String String String => Bool
      verificar firma webhook clave cuerpo firma_hex =
        hmac sha256 clave cuerpo -> esperada
        ct equal esperada firma_hex
```

### 24.3.3. 3. adibidea: `0..255` byte gordinen manipulazioa (`byte str`, `bytes from list`, `bytes to list`) eta 32 biteko bit-eragiketak (`band`, `bor`, `bxor`, `shl`, `shr`)

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.4. 4. adibidea: SHA-256 (FIPS 180-4), HMAC-SHA-256 (RFC 4231), denbora konstanteko konparazioa (`ct equal`) eta PBKDF2-HMAC-SHA-256 (RFC 6070) bektore ofizialak

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.5. 5. adibidea: 5 argumentuko Argon2id pasahitzen hashing-a (`argon2id hash`, `argon2id verify`) eta memoria-gogortasuna (RFC 9106)

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.6. 6. adibidea: ChaCha20 korronte-zifraketa, Poly1305 autentifikatzailea eta ChaCha20-Poly1305 AEAD zigilatze/irekitze autentifikatua (RFC 8439)

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.7. 7. Adibidea: FIPS 180-4 SHA-512 (`sha512 bytes`, `sha512 hex`), RFC 8032 §5.1 Ed25519 sinadurak (`ed25519 public key`, `ed25519 sign`, `ed25519 verify`) eta Minisign formatua (`minisign sign`, `minisign verify`)

Adibide praktiko honetan FIPS 180-4 SHA-512 bektore ofizialak, denbora konstanteko Ed25519 gako eta sinadurak ($S \ge L$ maleabilitatearen ukapen zorrotzarekin) eta `.minisig` formatuko argitalpen-manifestuen sinadura/egiaztapena probatzen ditugu:

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
        assert false (ed25519 verify pk "aldatua" sig) "Mezu aldatua baztertua"
        minisign encode pubkey "01234567" pk -> pub_txt
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ridgun-linux-x86_64.tar.gz\n" -> sums
        minisign sign sk "01234567" sums "ridgun release key" "timestamp:1761667200\tfile:SHA256SUMS" -> msig
        assert true (minisign verify pub_txt sums msig) "Minisign baliozkoa"
        assert str eq (minisign trusted comment msig) "timestamp:1761667200\tfile:SHA256SUMS" "Iruzkin autentifikatua" -> ()
```

### 24.3.8. 8. Adibidea: FIPS 180-4 SHA-1 bektoreak eta betegarri-mugak (`sha1 bytes`, `sha1 hex`)

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.9. 9. Adibidea: FIPS 180-4 SHA-512 bektoreak (`sha512 bytes`, `sha512 hex`)

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.10. 10. Adibidea: RFC 8032 Ed25519 proba-bektoreak eta sinadura maleagarri edo baliogabeen ukapena

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.11. 11. Adibidea: Minisign gako publikoak eta sinadurak: joan-etorria eta manipulazioaren detekzioa

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.12. 12. Adibidea: HMAC-SHA-384, HKDF (RFC 5869), X25519 (RFC 7748) eta AES-128-GCM (NIST SP 800-38D)

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.13. 13. Adibidea: P-256 eta P-384 ECDSA, RSA sinadura-egiaztapena eta X.509 ostalari-izenen bat-etortzea (RFC 6125)

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.14. 14. Adibidea: Muga-kasuak: gako-luzera okerrak, manipulatutako etiketak, RSA PKCS#1 v1.5 eta PSS, eta benetako ziurtagiriak

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.15. 15. Adibidea: RFC 1321 MD5 bektoreak (`md5 bytes`, `md5 hex`), oraindik izendatzen duten protokoloetarako

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 24.3.16. 16. Adibidea: SHA-256 eta PBKDF2 prozesadore-eragiketen gainean: luzera guztiak runtime-aren aurka eta erreferentzia-bektoreak

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test sha256 and pbkdf2 on processor operations => ()
      test sha256 and pbkdf2 on processor operations =
        sha256 hex (sha chain 0 300 "") -> assert str eq "7722024365d27836079cbf29de35d060b9383d7c713083199661392f983216d4" "the digests of every length from 0 to 300 bytes are Python's"
        sha256 hex (sha chain 500 580 "") -> assert str eq "57ea294cbc2c8bbe43f7083b5acc134734e0f43e44900161517e26119494fa8f" "and of every length from 500 to 580"
        sha256 hex (sha chain 4095 4097 "") -> assert str eq "d4f023801c2b814424b08cf869c14c329d9493e152cc207f5c02b9bae41c17d6" "and around 4 KB"
        sha256 hex (sha msg 70000) -> assert str eq "d284461e47fa34e0034954c43b9a11312be4932f0d45309c81b6355b65dbe334" "and of 70 000 bytes"
        sha256 hex make a1m -> assert str eq "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0" "FIPS 180-4: one million 'a'"
        sha256 hex "abc" -> assert str eq "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "FIPS 180-4: abc"

        -- the names the runtime used to give
        sha256 raw "abc" -> assert str eq (sha256 bytes "abc") "sha256 raw is sha256 bytes"
        sha256 str "abc" -> assert str eq (sha256 hex "abc") "sha256 str is sha256 hex"
        tensor to str (sha256 digest (tensor from str "abc")) -> assert str eq (sha256 bytes "abc") "sha256 digest of a tensor gives the 32 bytes as a tensor"
        f_abc = "/tmp/ridgun-libs-test-crypto-sha256-abc"
        f_big = "/tmp/ridgun-libs-test-crypto-sha256-big"
        put file f_abc "abc" -> assert int equals 3 "a file of 3 bytes is written"
        put file f_big (sha msg 200000) -> assert int equals 200000 "a file of 200 000 bytes is written"
        sha256 file f_abc -> assert str eq "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "sha256 file of a small file"
        sha256 file f_big -> assert str eq "56bfedd2826b1d2e9cdde6a38608dee5cf64f899bf711de08749cc7776dd2d12" "sha256 file of 200 000 bytes, read in several pieces"
        sha256 file "/tmp/ridgun-libs-test-crypto-no-such-file" -> assert str eq "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "a file that cannot be opened gives the digest of nothing"
        sha256 file "/tmp" -> assert str eq "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "and so does a directory"
        sys unlink f_abc -> assert true "the small file is removed"
        sys unlink f_big -> assert true "the big file is removed"

        -- HMAC-SHA-256: RFC 4231 and every message length from 0 to 400 with keys of 0 to 149 bytes
        bytes to hex str (hmac sha256 "Jefe" "what do ya want for nothing?") -> assert str eq "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843" "RFC 4231 test case 2"
        bytes to hex str (hmac sha256 (c repeat byte 170 131) "Test Using Larger Than Block-Size Key - Hash Key First") -> assert str eq "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54" "RFC 4231 test case 6: a key longer than a block"
        sha256 hex (hmac chain 0 400 "") -> assert str eq "907fba7eaf8a517237d4924964208b88cfd987d60d926706f94454bd0a11c098" "the HMACs of 401 messages and keys are Python's"

        -- PBKDF2-HMAC-SHA-256: RFC 7914 §11 and cases computed with Python's hashlib
        bytes to hex str (pbkdf2 hmac sha256 "passwd" "salt" 1 64) -> assert str eq "55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783" "RFC 7914: passwd / salt / 1"
        bytes to hex str (pbkdf2 hmac sha256 "Password" "NaCl" 80000 64) -> assert str eq "4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d" "RFC 7914: Password / NaCl / 80000"
        bytes to hex str (pbkdf2 hmac sha256 "password" "salt" 4096 32) -> assert str eq "c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a" "password / salt / 4096"
        bytes to hex str (pbkdf2 hmac sha256 (c repeat byte 112 65) (c repeat byte 115 55) 3 33) -> assert str eq "14a897bd94325458daa278746e49a58c45abfa72517fe315691b8d30180a11c55c" "a password longer than a block, a salt that fills one, 33 bytes"
        bytes to hex str (pbkdf2 hmac sha256 (c repeat byte 107 200) (c repeat byte 115 120) 2 100) -> assert str eq "5a9fd66ecadf76a485f3c2af00600288398f2a3e913373fcaeb838b0f8ad01006ea62244cae14ae6720b95bdd580bd66297d293303428382165a29a699bf3dbcbdee184a4a3fdb4b76cd65f78e585644a4805d650da41b0c4d6482d84a80a160024282d7" "200-byte password, 120-byte salt, four blocks of output"
        bytes to hex str (pbkdf2 hmac sha256 "" "" 1 32) -> assert str eq "f7ce0b653d2d72a4108cf5abe912ffdd777616dbbb27a70e8204f3ae2d0f6fad" "empty password and salt"
        ()
```

### 24.3.17. 17. Adibidea: AES-128 eta AES-256 prozesadore-eragiketen gainean: FIPS 197, GCMren proba-kasuak eta 70.000 byte

Adibide praktiko honetan `crypto` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test aes on processor operations => ()
      test aes on processor operations =
        k0  = c repeat byte 0 32
        n0  = c repeat byte 0 12
        k16 = hex to byte str "feffe9928665731c6d6a8f9467308308"
        k32 = k16 + k16
        n16 = hex to byte str "cafebabefacedbaddecaf888"
        bytes to hex str (aes128 block (hex to byte str "000102030405060708090a0b0c0d0e0f") (hex to byte str "00112233445566778899aabbccddeeff")) -> assert str eq "69c4e0d86a7b0430d8cdb78070b4c55a" "FIPS 197 C.1: AES-128 block"
        bytes to hex str (aes256 block (hex to byte str "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f") (hex to byte str "00112233445566778899aabbccddeeff")) -> assert str eq "8ea2b7ca516745bfeafc49904b496089" "FIPS 197 C.3: AES-256 block"
        bytes to hex str (aes256 block k0 (c repeat byte 0 16)) -> assert str eq "dc95c078a2408989ad48a21492842087" "AES-256 block of zeros under the zero key"
        aes256 block (c repeat byte 0 31) (c repeat byte 0 16) -> assert str eq "" "AES-256 rejects a 31-byte key"
        aes256 block k0 (c repeat byte 0 15) -> assert str eq "" "AES-256 rejects a 15-byte block"

        bytes to hex str (aes256 gcm seal k0 n0 "" "") -> assert str eq "530f8afbc74536b9a963b4f1c4cb738b" "GCM test case 13: AES-256, nothing to encrypt"
        bytes to hex str (aes256 gcm seal k0 n0 "" (c repeat byte 0 16)) -> assert str eq "cea7403d4d606b6e074ec5d3baf39d18d0d1c8a799996bf0265b98b5d48ab919" "GCM test case 14: AES-256, one block"
        p16 = hex to byte str "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39"
        a16 = hex to byte str "feedfacedeadbeeffeedfacedeadbeefabaddad2"
        s16 = aes256 gcm seal k32 n16 a16 p16
        bytes to hex str s16 -> assert str eq "522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f66276fc6ece0f4e1768cddf8853bb2d551b" "GCM test case 16: AES-256 with associated data"
        aead rc (aes256 gcm open k32 n16 a16 s16) -> assert int equals 0 "AES-256-GCM opens what it sealed"
        aead pt (aes256 gcm open k32 n16 a16 s16) -> assert str eq p16 "and gives the plaintext back"
        aead rc (aes256 gcm open k32 n16 "other" s16) -> assert int equals (0 - 12) "other associated data: rejected"
        aead rc (aes256 gcm open k32 n16 a16 ((byte slice s16 0 59) + (byte str 0) + (byte slice s16 60 76))) -> assert int equals (0 - 12) "one byte of the ciphertext changed: rejected"
        aead rc (aes256 gcm open (byte slice k32 0 31) n16 a16 s16) -> assert int equals (0 - 7) "a 31-byte key: rejected"
        aes256 gcm seal k32 (byte slice n16 0 11) a16 p16 -> assert str eq "" "an 11-byte nonce: rejected"

        big  = sha msg 70000
        b256 = aes256 gcm seal k32 n16 "hdr" big
        b128 = aes128 gcm seal k16 n16 "hdr" big
        str len b256 -> assert int equals 70016 "70 000 bytes sealed with AES-256-GCM plus the tag"
        bytes to hex str (byte slice b256 69984 70016) -> assert str eq "435561789b43a952599bf34be11ac40c27dde7737090ef450f2d8adac8a0da91" "AES-256-GCM of 70 000 bytes ends as Python's cryptography says"
        bytes to hex str (byte slice b128 69984 70016) -> assert str eq "aa923b409f3b783bc924341c9f61d9ed2a234901df0a73dafcfda27601fba9fc" "AES-128-GCM of 70 000 bytes ends as Python's cryptography says"
        aead pt (aes256 gcm open k32 n16 "hdr" b256) -> assert str eq big "AES-256-GCM opens the 70 000 bytes"
        aead pt (aes128 gcm open k16 n16 "hdr" b128) -> assert str eq big "AES-128-GCM opens the 70 000 bytes"
        ()
```

---

## 24.4. Kaputaren azpian: nola dagoen eraikia `crypto` Ridgun hutsean (`src/main/ridgun/lib/crypto.ridgun`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/crypto.ridgun` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 24.4.1. Barne-inplementazioa: RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`)

Ikusi nola `crypto.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 24.4.2. Barne-inplementazioa: RFC 8439 ChaCha20 Stream Cipher (`chacha20_block`, `chacha20_xor`)

Ikusi nola `crypto.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: le32 at Tensor[U8] Int => Int
      le32 at bs         off =
        bs_(off) + (bs_(off + 1) * 256) + (bs_(off + 2) * 65536) + (bs_(off + 3) * 16777216)

-- Ten double rounds on n blocks at once: one tensor per state word (RFC 8439 §2.3). Each line makes a new
-- tensor: the same rounds written in place (`s0_i = s0_i + s4_i`, ridgunc 1.0.86) were measured by Vonkeep on
-- 2026-11-25 1.5 us slower for a call and 10% slower for each byte, so they are not used.
-- Consecutive element-wise statements run as one loop, and the self call repeats it (requirement COMP-031 of the compiler).
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

-- The bytes `from` to `to` (not included) of `t`, as a new tensor. One copy per step, none byte by byte.
fn :: c bytes part Tensor[U8] Int Int => Tensor[U8]
      c bytes part t from to =  tensor from str (str slice (tensor to str t) from to)

-- The first `n` bytes of `stream` (the key stream is made in whole blocks).
fn :: c first bytes Tensor[U8] Int Int => Tensor[U8]
      c first bytes stream have n =
        | have == n = stream
        | otherwise = c bytes part stream 0 n

-- The first `n` bytes (at most 64 KiB) of the key stream from block `ctr` on: all the blocks at once,
-- then the 16 word tensors side by side and their bytes (ridgunc 1.0.40).
fn :: chacha20 key stream chunk Tensor[U8] Tensor[U8] Int Int => Tensor[U8]
      chacha20 key stream chunk key_bs nonce_bs ctr n =
        nb = (n + 63) / 64
        o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15 = chacha page key_bs nonce_bs ctr nb
        c first bytes (tensor bytes (tensor interleave [o0, o1, o2, o3, o4, o5, o6, o7, o8, o9, o10, o11, o12, o13, o14, o15])) (64 * nb) n
```

### 24.4.3. Barne-inplementazioa: RFC 8439 Poly1305 One-Time Authenticator (5 x 26-bit limbs)

Ikusi nola `crypto.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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
```

### 24.4.4. Barne-inplementazioa: SHA-256 on Processor Operations: a Block, the HMAC Step of PBKDF2 and the Loops

Ikusi nola `crypto.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
-- One block of 64 bytes: its words are read big-endian.
arch :: sha256 block Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * 64] => Tensor[U32 * 4] Tensor[U32 * 4]
        sha256 block abcd efgh m =
          w0 = group as u32 (group pick m [3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12])
          w1 = group as u32 (group pick m [19, 18, 17, 16, 23, 22, 21, 20, 27, 26, 25, 24, 31, 30, 29, 28])
          w2 = group as u32 (group pick m [35, 34, 33, 32, 39, 38, 37, 36, 43, 42, 41, 40, 47, 46, 45, 44])
          w3 = group as u32 (group pick m [51, 50, 49, 48, 55, 54, 53, 52, 59, 58, 57, 56, 63, 62, 61, 60])
          a1, e1 = sha256 compress abcd efgh w0 w1 w2 w3
          (a1, e1)

-- The outer hash of HMAC-SHA-256 from the outer key state and the inner digest (two word groups):
-- the block is digest || 0x80 || zeros || 768 bits.
arch :: sha256 hmac outer Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] => Tensor[U32 * 4] Tensor[U32 * 4]
        sha256 hmac outer oa oe na ne =
          z  = na_i xor na_i
          hi = z_i + 0x80000000
          lo = z_i + 768
          w2 = group pick two hi z [0, 4, 5, 6]
          w3 = group pick two z lo [0, 1, 2, 4]
          a2, e2 = sha256 compress oa oe na ne w2 w3
          (a2, e2)

-- HMAC-SHA-256 of a 32-byte message (a digest, as its two word groups) from the two key states.
-- The inner block has the same shape as the outer one.
arch :: sha256 hmac step Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] => Tensor[U32 * 4] Tensor[U32 * 4]
        sha256 hmac step ia ie oa oe ua ue =
          z  = ua_i xor ua_i
          hi = z_i + 0x80000000
          lo = z_i + 768
          w2 = group pick two hi z [0, 4, 5, 6]
          w3 = group pick two z lo [0, 1, 2, 4]
          a1, e1 = sha256 compress ia ie ua ue w2 w3
          a2, e2 = sha256 compress oa oe a1 e1 w2 w3
          (a2, e2)

-- The iterations of PBKDF2 after the first: U = HMAC(U), acc = acc xor U. One loop, everything in registers.
fn :: sha256 pbkdf2 loop Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U32 * 4] Int => Tensor[U32 * 4] Tensor[U32 * 4]
      sha256 pbkdf2 loop ia ie oa oe ua ue xa xe n
        | n <= 0 = (xa, xe)
        | otherwise =
          a1, e1 = sha256 hmac step ia ie oa oe ua ue
          x1 = xa_i xor a1_i
          x2 = xe_i xor e1_i
          sha256 pbkdf2 loop ia ie oa oe a1 e1 x1 x2 (n - 1)

-- The blocks of a message, one after another: one loop, the state in registers.
fn :: sha256 absorb Tensor[U32 * 4] Tensor[U32 * 4] Tensor[U8 * n * 64] Int Int => Tensor[U32 * 4] Tensor[U32 * 4]
      sha256 absorb abcd efgh msg at n
        | n <= 0 = (abcd, efgh)
        | otherwise =
          a1, e1 = sha256 block abcd efgh msg_(at,)
          sha256 absorb a1 e1 msg (at + 1) (n - 1)
```

### 24.4.5. Barne-inplementazioa: AES on processor operations (FIPS 197; `arch ::`, ridgunc 1.0.55)

Ikusi nola `crypto.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
-- A round, the last round, a whole block and the counter block of CTR mode are operations: each has a portable
-- definition and a variant on the AES instructions of x86-64 (RIDGUN_CPU=2 forces the portable one).
-- The rounds have two variants: four blocks per instruction where the processor has it (`on x64 by 4`) and one
-- block. Since ridgunc 1.0.84 the counter loop takes four rows per turn and runs the four-block one: a wrong
-- instruction planted in it makes the suite fail (checked with 1.0.86).

arch :: aes round Tensor[U8 * 16] Tensor[U8 * 16] Tensor[U8 * 256] => Tensor[U8 * 16]
        aes round s k box =
          t = box_(s_i)
          r = group pick t [0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 1, 6, 11]
          a1 = group pick r [1, 2, 3, 0, 5, 6, 7, 4, 9, 10, 11, 8, 13, 14, 15, 12]
          a2 = group pick r [2, 3, 0, 1, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13]
          a3 = group pick r [3, 0, 1, 2, 7, 4, 5, 6, 11, 8, 9, 10, 15, 12, 13, 14]
          x0 = (r_i shl 1) xor ((r_i shr 7) * 27)
          x1 = (a1_i shl 1) xor ((a1_i shr 7) * 27)
          m = ((x0_i xor x1_i) xor a1_i) xor (a2_i xor a3_i)
          m_i xor k_i
        aes round s k box on x64 by 4 =
          group as u8 (cpu aesenc (group as u64 s) (group as u64 k))
        aes round s k box on x64 =
          group as u8 (cpu aesenc (group as u64 s) (group as u64 k))

arch :: aes last round Tensor[U8 * 16] Tensor[U8 * 16] Tensor[U8 * 256] => Tensor[U8 * 16]
        aes last round s k box =
          t = box_(s_i)
          r = group pick t [0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 1, 6, 11]
          r_i xor k_i
        aes last round s k box on x64 by 4 =
          group as u8 (cpu aesenclast (group as u64 s) (group as u64 k))
        aes last round s k box on x64 =
          group as u8 (cpu aesenclast (group as u64 s) (group as u64 k))

arch :: aes128 encrypt block Tensor[U8 * 16] Tensor[U8 * 11 * 16] Tensor[U8 * 256] => Tensor[U8 * 16]
        aes128 encrypt block p keys box =
          k0 = keys_(0,)
          s0 = p_i xor k0_i
          s1 = aes round s0 keys_(1,) box
          s2 = aes round s1 keys_(2,) box
          s3 = aes round s2 keys_(3,) box
          s4 = aes round s3 keys_(4,) box
          s5 = aes round s4 keys_(5,) box
          s6 = aes round s5 keys_(6,) box
          s7 = aes round s6 keys_(7,) box
          s8 = aes round s7 keys_(8,) box
          s9 = aes round s8 keys_(9,) box
          aes last round s9 keys_(10,) box

arch :: aes256 encrypt block Tensor[U8 * 16] Tensor[U8 * 15 * 16] Tensor[U8 * 256] => Tensor[U8 * 16]
        aes256 encrypt block p keys box =
          k0 = keys_(0,)
          s0 = p_i xor k0_i
          s1 = aes round s0 keys_(1,) box
          s2 = aes round s1 keys_(2,) box
          s3 = aes round s2 keys_(3,) box
          s4 = aes round s3 keys_(4,) box
          s5 = aes round s4 keys_(5,) box
          s6 = aes round s5 keys_(6,) box
          s7 = aes round s6 keys_(7,) box
          s8 = aes round s7 keys_(8,) box
          s9 = aes round s8 keys_(9,) box
          s10 = aes round s9 keys_(10,) box
          s11 = aes round s10 keys_(11,) box
          s12 = aes round s11 keys_(12,) box
          s13 = aes round s12 keys_(13,) box
          aes last round s13 keys_(14,) box

-- The counter block of CTR mode: the first 12 bytes of `iv` and the 32-bit counter `n`, big-endian (the last 4 bytes of `iv` are 0).
arch :: aes128 ctr block Tensor[U8 * 16] Tensor[U8 * 11 * 16] Tensor[U8 * 256] Int => Tensor[U8 * 16]
        aes128 ctr block iv keys box n =
          z = group as u32 iv
          c = z_i + n
          b = group as u8 c
          aes128 encrypt block (group pick two iv b [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 31, 30, 29, 28]) keys box

arch :: aes256 ctr block Tensor[U8 * 16] Tensor[U8 * 15 * 16] Tensor[U8 * 256] Int => Tensor[U8 * 16]
        aes256 ctr block iv keys box n =
          z = group as u32 iv
          c = z_i + n
          b = group as u8 c
          aes256 encrypt block (group pick two iv b [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 31, 30, 29, 28]) keys box

-- E(K, nonce || ctr + at) for the rows `at` on: one loop, the block in registers.
fn :: aes128 ctr rows Tensor[U8 * n * 16] Tensor[U8 * 16] Tensor[U8 * 11 * 16] Tensor[U8 * 256] Int Int Int => Tensor[U8 * n * 16]
      aes128 ctr rows out iv keys box ctr at k
        | k <= 0 = out
        | otherwise =
          out_(at,) = aes128 ctr block iv keys box (ctr + at)
          aes128 ctr rows out iv keys box ctr (at + 1) (k - 1)

fn :: aes256 ctr rows Tensor[U8 * n * 16] Tensor[U8 * 16] Tensor[U8 * 15 * 16] Tensor[U8 * 256] Int Int Int => Tensor[U8 * n * 16]
      aes256 ctr rows out iv keys box ctr at k
        | k <= 0 = out
        | otherwise =
          out_(at,) = aes256 ctr block iv keys box (ctr + at)
          aes256 ctr rows out iv keys box ctr (at + 1) (k - 1)

-- The S-box of AES, computed (FIPS 197 §5.1.1): no table of 256 numbers to type.
fn :: aes rotl8 Int Int => Int
      aes rotl8 x n =  ((x shl n) or (x shr (8 - n))) and 255

fn :: aes box fill Tensor[U8] Int Int Bool => Tensor[U8]
      aes box fill box p q first
        | p == 1 and not first = box
        | otherwise =
          p1 = (p xor (p shl 1) xor ((p shr 7) * 27)) and 255
          q1 = (q xor (q shl 1)) and 255
          q2 = (q1 xor (q1 shl 2)) and 255
          q3 = (q2 xor (q2 shl 4)) and 255
          q4 = (q3 xor ((q3 shr 7) * 9)) and 255
          box_(p1) = (q4 xor (aes rotl8 q4 1) xor (aes rotl8 q4 2) xor (aes rotl8 q4 3) xor (aes rotl8 q4 4)) xor 99
          aes box fill box p1 q4 False

-- Built once for the whole program (`idem ::`, ridgunc 1.0.54); nobody writes in it.
idem :: aes make box => Tensor[U8]
        aes make box =
          box = Tensor[U8 * 256]
          box_(0) = 99
          aes box fill box 1 1 True

-- The key schedule (FIPS 197 §5.2) for a key of `nk` words (4 or 8): byte i of word w at keys_(w / 4, (w % 4) * 4 + i).
fn :: aes key byte Tensor[U8] Int Int => Int
      aes key byte keys w i =  keys_(w / 4, ((w % 4) * 4) + i)

fn :: aes put word Tensor[U8] Int Int Int Int Int => Tensor[U8]
      aes put word keys w b0 b1 b2 b3 =
        keys_(w / 4, (w % 4) * 4)       = b0
        keys_(w / 4, ((w % 4) * 4) + 1) = b1
        keys_(w / 4, ((w % 4) * 4) + 2) = b2
        keys_(w / 4, ((w % 4) * 4) + 3) = b3
        keys

fn :: aes expand Tensor[U8] Tensor[U8] Int Int Int Int => Tensor[U8]
      aes expand keys box nk total w rcon
        | w >= total = keys
        | (w % nk) == 0 =
          k2 = aes put word keys w ((aes key byte keys (w - nk) 0) xor box_(aes key byte keys (w - 1) 1) xor rcon) ((aes key byte keys (w - nk) 1) xor box_(aes key byte keys (w - 1) 2)) ((aes key byte keys (w - nk) 2) xor box_(aes key byte keys (w - 1) 3)) ((aes key byte keys (w - nk) 3) xor box_(aes key byte keys (w - 1) 0))
          aes expand k2 box nk total (w + 1) (((rcon shl 1) xor ((rcon shr 7) * 283)) and 255)
        | nk > 6 and (w % nk) == 4 =
          k2 = aes put word keys w ((aes key byte keys (w - nk) 0) xor box_(aes key byte keys (w - 1) 0)) ((aes key byte keys (w - nk) 1) xor box_(aes key byte keys (w - 1) 1)) ((aes key byte keys (w - nk) 2) xor box_(aes key byte keys (w - 1) 2)) ((aes key byte keys (w - nk) 3) xor box_(aes key byte keys (w - 1) 3))
          aes expand k2 box nk total (w + 1) rcon
        | otherwise =
          k2 = aes put word keys w ((aes key byte keys (w - nk) 0) xor (aes key byte keys (w - 1) 0)) ((aes key byte keys (w - nk) 1) xor (aes key byte keys (w - 1) 1)) ((aes key byte keys (w - nk) 2) xor (aes key byte keys (w - 1) 2)) ((aes key byte keys (w - nk) 3) xor (aes key byte keys (w - 1) 3))
          aes expand k2 box nk total (w + 1) rcon

fn :: aes set key Tensor[U8] String Int Int => Tensor[U8]
      aes set key keys key i n
        | i >= n = keys
        | otherwise =
          keys_(i / 16, i % 16) = str char at key i
          aes set key keys key (i + 1) n

fn :: aes128 keys Tensor[U8] String => Tensor[U8]
      aes128 keys box key =  aes expand (aes set key (Tensor[U8 * 11 * 16]) key 0 16) box 4 44 4 1

fn :: aes256 keys Tensor[U8] String => Tensor[U8]
      aes256 keys box key =  aes expand (aes set key (Tensor[U8 * 15 * 16]) key 0 32) box 8 60 8 1

-- The first `n` bytes of the CTR key stream from counter `ctr` on (NIST SP 800-38D §6.5).
fn :: aes iv16 String => Tensor[U8]
      aes iv16 nonce =  tensor from str (nonce + (c repeat byte 0 4))

fn :: aes128 key stream Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      aes128 key stream box keys nonce ctr n =
        | n <= 0    = Tensor[U8 * 0]
        | otherwise = c first bytes (tensor bytes (aes128 ctr rows (Tensor[U8 * ((n + 15) / 16) * 16]) (aes iv16 nonce) keys box ctr 0 ((n + 15) / 16))) (16 * ((n + 15) / 16)) n

fn :: aes256 key stream Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      aes256 key stream box keys nonce ctr n =
        | n <= 0    = Tensor[U8 * 0]
        | otherwise = c first bytes (tensor bytes (aes256 ctr rows (Tensor[U8 * ((n + 15) / 16) * 16]) (aes iv16 nonce) keys box ctr 0 ((n + 15) / 16))) (16 * ((n + 15) / 16)) n

fn :: aes128 block String String => String
      aes128 block key    blk    =
        | (str len key) != 16 or (str len blk) != 16 = ""
        | otherwise = tensor to str (aes128 encrypt block (tensor from str blk) (aes128 keys (aes make box) key) (aes make box))

fn :: aes256 block String String => String
      aes256 block key    blk    =
        | (str len key) != 32 or (str len blk) != 16 = ""
        | otherwise = tensor to str (aes256 encrypt block (tensor from str blk) (aes256 keys (aes make box) key) (aes make box))
```

### 24.4.6. Barne-inplementazioa: Montgomery Multiplication for Odd Moduli (`bn mont mul`, `bn mont pow`, `bn mod exp`)

Ikusi nola `crypto.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 24.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `crypto`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: `aead open`-ek 16 byteko Poly1305 etiketa denbora konstantean egiaztatzen du testu lauko byte bakar bat itzuli aurretik (huts egiten badu, `(-1, "")` itzultzen du).
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/crypto.ridgun`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test crypto.ridgun` suite automatizatuaren bidez.

### `crypto`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import crypto` fitxategiaren hasieran** eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `crypto`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `crypto`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `crypto` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**25. kapituluan** **`argon2id`** lib-a sakonki esploratuko dugu (`argon2id` lib-a — RFC 9106 Argon2id `Tensor[U64 * 128]` gainean, Blake2b eta OWASP Aurrezarpenak).
