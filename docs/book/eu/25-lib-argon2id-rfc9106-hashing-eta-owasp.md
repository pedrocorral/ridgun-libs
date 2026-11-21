# 25. kapitulua: `argon2id` lib-a — RFC 9106 Argon2id `Tensor[U64 * 128]` gainean, Blake2b eta OWASP Aurrezarpenak

## 25.1. Zergatik existitzen da `argon2id` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `argon2id` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `argon2id`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: pasahitzak SHA-256 soil batekin gordetzeak GPU moderno bati segundoko milaka milioi konbinazio probatzea ahalbidetzen dio, baina Argon2id izateko kanpoko C liburutegiak estekatzeak konpilazio- eta memoria-buruhausteak ekartzen ditu.

**`argon2id`** lib-ak **RFC 9106 Argon2id** eta **RFC 7693 Blake2b-512** % 100ean Ridgun hutsean inplementatzen ditu `Tensor[U64 * 128]` bloke natiboen gainean (1 024 byte blokeko RMM2 memoria jarraituan), **PHC** kateen sorrerarekin (`$argon2id$v=19$m=...,t=...,p=...$`), **OWASP** profilekin (`default argon2 params`, `argon2 moderate params`), *pepper* euskarriarekin (`argon2id hash ctx`), gakoen eratorpenarekin (`argon2id derive key`) eta parametroen eguneratze-detekzioarekin (`argon2id needs rehash`).

Ekosistema tradizional batean, **`CRYPTO`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`argon2id`** lib-ak (`src/main/ridgun/lib/argon2id.ridgun`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import argon2id` (edo `import argon2id as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: argon2id` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `argon2id`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 25.2. Artefaktu natiboak, inportazioa eta `argon2id` APIaren katalogo osoa

`ridgun-libs`-en, **`argon2id`** lehen mailako **lib** bat da, `src/main/ridgun/lib/argon2id.ridgun` bidean kokatua (`CRYPTO` domeinua). `stable bundle`-ekin konpilatzean, formatu natibo bakarrean paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/argon2id.ridgunlib` | Banaketa eta inportazio zuzena `import argon2id` bidez |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: argon2id` bidez: nahikoa da goiburuan `import argon2id` (edo `import argon2id as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 25.2.1. `argon2id`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `argon2id hash / argon2id verify` | 5 argumentuko RFC 9106 PHC pasahitz-hashinga (`pwd, salt, m_kib, t, p`) eta denbora konstanteko egiaztapena |
| `default argon2 params / argon2 interactive params / argon2 moderate params / argon2 sensitive params / argon2 params` | Parametro-aurrezarpenak (19 MiB OWASP gutxienekoa, 46 MiB, 64 MiB) eta parametro pertsonalizatuak (`m_cost` KiB-tan, `t_cost`, `lanes`, `tag_len`) |
| `argon2id hash ctx / argon2id verify ctx` | RFC 9106 hashinga `pepper` sekretuarekin ($K$) eta datu elkartuekin ($X$) |
| `argon2id derive key / argon2id needs rehash` | Gako bitar gordinaren eratorpena eta PHC kateetan rehash beharraren detekzioa |
| `blake2b` | Helburu orokorreko RFC 7693 Blake2b laburpen kriptografikoa (`1..64` byte) |

### 25.2.2. `src/main/ridgun/lib/argon2id.ridgun`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/argon2id.ridgun` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`10` mota, `0` eragile eta `135` funtzio):

**`argon2id`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type Argon2Params = m_cost: Int, t_cost: Int, lanes: Int, tag_len: Int, version: Int
type Argon2Phc    = params: Argon2Params, salt_b64: String, tag_b64: String
type Argon2Res    = Argon2Ok String | Argon2Err String
type Argon2KeyRes = Argon2KeyOk Tensor[U8] | Argon2KeyErr String
type Argon2PhcRes = Argon2PhcOk Argon2Phc | Argon2PhcErr String
type A2M16   = mb0: Tensor[U64 * 128], mb1: Tensor[U64 * 128], mb2: Tensor[U64 * 128], mb3: Tensor[U64 * 128], mb4: Tensor[U64 * 128], mb5: Tensor[U64 * 128], mb6: Tensor[U64 * 128], mb7: Tensor[U64 * 128], mb8: Tensor[U64 * 128], mb9: Tensor[U64 * 128], mb10: Tensor[U64 * 128], mb11: Tensor[U64 * 128], mb12: Tensor[U64 * 128], mb13: Tensor[U64 * 128], mb14: Tensor[U64 * 128], mb15: Tensor[U64 * 128]
type A2M256  = mr0: A2M16, mr1: A2M16, mr2: A2M16, mr3: A2M16, mr4: A2M16, mr5: A2M16, mr6: A2M16, mr7: A2M16, mr8: A2M16, mr9: A2M16, mr10: A2M16, mr11: A2M16, mr12: A2M16, mr13: A2M16, mr14: A2M16, mr15: A2M16
type A2M4096 = mp0: A2M256, mp1: A2M256, mp2: A2M256, mp3: A2M256, mp4: A2M256, mp5: A2M256, mp6: A2M256, mp7: A2M256, mp8: A2M256, mp9: A2M256, mp10: A2M256, mp11: A2M256, mp12: A2M256, mp13: A2M256, mp14: A2M256, mp15: A2M256
type A2Mem   = mt0: A2M4096, mt1: A2M4096, mt2: A2M4096, mt3: A2M4096, mt4: A2M4096, mt5: A2M4096, mt6: A2M4096, mt7: A2M4096, mt8: A2M4096, mt9: A2M4096, mt10: A2M4096, mt11: A2M4096, mt12: A2M4096, mt13: A2M4096, mt14: A2M4096, mt15: A2M4096
type A2Ctx   = r_pass: Int, s_slice: Int, l_lane: Int, p_lanes: Int, q_cols: Int, seg_len: Int, t_iters: Int
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: a2 str list len [String]` | `Int` |
| `2` | `fn :: a2 nth str [String] Int` | `String` |
| `3` | `fn :: a2 u8 len Tensor[U8]` | `Int` |
| `4` | `fn :: a2 copy loop Tensor[U8] Int Tensor[U8] Int Int Int` | `Int` |
| `5` | `fn :: a2 copy bytes Tensor[U8] Int Tensor[U8] Int Int` | `Int` |
| `6` | `fn :: a2 put u32 Tensor[U8] Int Int` | `Int` |
| `7` | `fn :: a2 put field Tensor[U8] Int Tensor[U8]` | `Int` |
| `8` | `fn :: hex digits` | `String` |
| `9` | `fn :: byte to hex Int` | `String` |
| `10` | `fn :: a2 hex code Int` | `Int` |
| `11` | `fn :: bytes to hex loop Tensor[U8] Tensor[U8] Int Int` | `Tensor[U8]` |
| `12` | `fn :: bytes to hex Tensor[U8]` | `String` |
| `13` | `fn :: byte bitxor Int Int` | `Int` |
| `14` | `fn :: u32 norm Int` | `Int` |
| `15` | `fn :: u32 add Int Int` | `Int` |
| `16` | `fn :: u32 bitxor Int Int` | `Int` |
| `17` | `fn :: a2 u64 lh Int Int` | `U64` |
| `18` | `fn :: a2 f blamka U64 U64` | `U64` |
| `19` | `fn :: a2 bytes to u32 le Tensor[U8] Int` | `Int` |
| `20` | `fn :: a2 zero w16` | `Tensor[U64 * 32]` |
| `21` | `fn :: a2 zero blk8` | `Tensor[U64 * 128]` |
| `22` | `fn :: a2 w16 get Tensor[U64 * 32] Int` | `U64` |
| `23` | `fn :: a2 w16 set Tensor[U64 * 32] Int U64` | `Tensor[U64 * 32]` |
| `24` | `fn :: a2 b2b iv w16` | `Tensor[U64 * 32]` |
| `25` | `fn :: a2 b2b g4 U64 U64 U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `26` | `fn :: a2 b2b sigma table` | `String` |
| `27` | `fn :: a2 sig Int Int` | `Int` |
| `28` | `fn :: a2 b2b round Tensor[U64 * 32] Tensor[U64 * 32] Int` | `Tensor[U64 * 32]` |
| `29` | `fn :: a2 b2b rounds Tensor[U64 * 32] Tensor[U64 * 32] Int` | `Tensor[U64 * 32]` |
| `30` | `fn :: a2 b2b compress Tensor[U64 * 32] Tensor[U64 * 32] Int Bool` | `Tensor[U64 * 32]` |
| `31` | `fn :: a2 bytes to u64 Tensor[U8] Int` | `U64` |
| `32` | `fn :: a2 bytes to w16 Tensor[U8] Int` | `Tensor[U64 * 32]` |
| `33` | `fn :: a2 h8 bytes loop Tensor[U64 * 32] Tensor[U8] Int Int` | `Tensor[U8]` |
| `34` | `fn :: a2 h8 to bytes Tensor[U64 * 32] Int` | `Tensor[U8]` |
| `35` | `fn :: a2 b2b loop Tensor[U64 * 32] Tensor[U8] Int Int` | `Tensor[U64 * 32]` |
| `36` | `fn :: a2 blake2b Tensor[U8] Int` | `Tensor[U8]` |
| `37` | `fn :: a2 b2b prefixed Tensor[U8] Int` | `Tensor[U8]` |
| `38` | `fn :: a2 b2b long loop Tensor[U8] Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `39` | `fn :: a2 blake2b long Tensor[U8] Int` | `Tensor[U8]` |
| `40` | `fn :: a2 lane ids Tensor[U64 * n] Int` | `Tensor[U64 * n]` |
| `41` | `fn :: a2 perm rows Tensor[U64 * m] Tensor[U64 * n]` | `Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n]` |
| `42` | `fn :: a2 perm cols Tensor[U64 * m] Tensor[U64 * n]` | `Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n]` |
| `43` | `fn :: a2 bitxor blk8 Tensor[U64 * 128] Tensor[U64 * 128]` | `Tensor[U64 * 128]` |
| `44` | `fn :: a2 blamka block Tensor[U64 * 128]` | `Tensor[U64 * 128]` |
| `45` | `fn :: a2 compress blk8 Tensor[U64 * 128] Tensor[U64 * 128]` | `Tensor[U64 * 128]` |
| `46` | `fn :: a2 compress blk8 bxor Tensor[U64 * 128] Tensor[U64 * 128] Tensor[U64 * 128]` | `Tensor[U64 * 128]` |
| `47` | `fn :: a2 bitxor3 Tensor[U64 * 128] Tensor[U64 * 128] Tensor[U64 * 128]` | `Tensor[U64 * 128]` |
| `48` | `fn :: a2 bytes to blk8 loop Tensor[U64 * 128] Tensor[U8] Int` | `Tensor[U64 * 128]` |
| `49` | `fn :: a2 bytes to blk8 Tensor[U8]` | `Tensor[U64 * 128]` |
| `50` | `fn :: a2 blk8 to bytes loop Tensor[U64 * 128] Tensor[U8] Int` | `Tensor[U8]` |
| `51` | `fn :: a2 blk8 to bytes Tensor[U64 * 128]` | `Tensor[U8]` |
| `52` | `fn :: a2 zero mem` | `A2Mem` |
| `53` | `fn :: a2 get m16 A2M16 Int` | `Tensor[U64 * 128]` |
| `54` | `fn :: a2 get m256 A2M256 Int Int` | `Tensor[U64 * 128]` |
| `55` | `fn :: a2 get m4096 A2M4096 Int Int Int` | `Tensor[U64 * 128]` |
| `56` | `fn :: a2 get mem A2Mem Int Int Int Int` | `Tensor[U64 * 128]` |
| `57` | `fn :: a2 nth blk A2Mem Int` | `Tensor[U64 * 128]` |
| `58` | `fn :: a2 set m16 A2M16 Int Tensor[U64 * 128]` | `A2M16` |
| `59` | `fn :: a2 set m256 A2M256 Int Int Tensor[U64 * 128]` | `A2M256` |
| `60` | `fn :: a2 set m4096 A2M4096 Int Int Int Tensor[U64 * 128]` | `A2M4096` |
| `61` | `fn :: a2 set mem A2Mem Int Int Int Int Tensor[U64 * 128]` | `A2Mem` |
| `62` | `fn :: a2 set blk A2Mem Int Tensor[U64 * 128]` | `A2Mem` |
| `63` | `fn :: a2 lane seed Tensor[U8] Int Int` | `Tensor[U8]` |
| `64` | `fn :: a2 init all lanes loop A2Mem Tensor[U8] Int Int Int` | `A2Mem` |
| `65` | `fn :: a2 init all lanes Tensor[U8] Int Int Int` | `A2Mem` |
| `66` | `fn :: a2 make addr blk A2Ctx Int` | `Tensor[U64 * 128]` |
| `67` | `fn :: a2 calc w size A2Ctx Int Bool` | `Int` |
| `68` | `fn :: a2 fill seg ind p1 A2Mem A2Ctx Int Int Int Tensor[U64 * 128] Tensor[U64 * 128]` | `A2Mem` |
| `69` | `fn :: a2 fill seg r0 p1 A2Mem Int Int Tensor[U64 * 128]` | `A2Mem` |
| `70` | `fn :: a2 fill seg rn p1 A2Mem Int Int Int Int Int Tensor[U64 * 128]` | `A2Mem` |
| `71` | `fn :: a2 step block A2Mem Int Int Tensor[U64 * 128] Tensor[U64 * 128]` | `A2Mem Tensor[U64 * 128]` |
| `72` | `fn :: a2 fill segment A2Mem A2Ctx Int Tensor[U64 * 128] Tensor[U64 * 128]` | `A2Mem` |
| `73` | `fn :: a2 run lane seg A2Mem A2Ctx Int Int Int Int Int Int Int Tensor[U64 * 128]` | `A2Mem` |
| `74` | `fn :: a2 run lanes A2Mem A2Ctx Int` | `A2Mem` |
| `75` | `fn :: a2 run slices A2Mem A2Ctx Int` | `A2Mem` |
| `76` | `fn :: a2 run passes A2Mem A2Ctx Int` | `A2Mem` |
| `77` | `fn :: a2 bitxor final lanes A2Mem Int Int Int Tensor[U64 * 128]` | `Tensor[U64 * 128]` |
| `78` | `fn :: a2 h0 input Argon2Params Tensor[U8] Tensor[U8] Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `79` | `fn :: derive raw tag ctx Tensor[U8] Tensor[U8] String String Argon2Params` | `Tensor[U8]` |
| `80` | `fn :: derive raw tag Tensor[U8] Tensor[U8] Argon2Params` | `Tensor[U8]` |
| `81` | `fn :: b64 alphabet` | `String` |
| `82` | `fn :: b64 code Int` | `Int` |
| `83` | `fn :: b64 enc tail Tensor[U8] Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `84` | `fn :: b64 enc loop Tensor[U8] Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `85` | `fn :: b64 tail len Int` | `Int` |
| `86` | `fn :: b64 encode nopad Tensor[U8]` | `String` |
| `87` | `fn :: b64 char val Int` | `Int` |
| `88` | `fn :: valid b64 chars String Int Int` | `Bool` |
| `89` | `fn :: is valid b64 nopad String` | `Bool` |
| `90` | `fn :: b64 val at String Int` | `Int` |
| `91` | `fn :: b64 dec tail String Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `92` | `fn :: b64 dec loop String Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `93` | `fn :: b64 dec len Int` | `Int` |
| `94` | `fn :: b64 decode nopad String` | `Tensor[U8]` |
| `95` | `fn :: default argon2 params` | `Argon2Params` |
| `96` | `fn :: argon2 interactive params` | `Argon2Params` |
| `97` | `fn :: argon2 moderate params` | `Argon2Params` |
| `98` | `fn :: argon2 sensitive params` | `Argon2Params` |
| `99` | `fn :: argon2 params Int Int Int Int` | `Argon2Params` |
| `100` | `fn :: clamp salt len Int` | `Int` |
| `101` | `fn :: a2 random next Tensor[U8] Int Int Tensor[U8] Int` | `Int` |
| `102` | `fn :: a2 random fill Tensor[U8] Int Int` | `Int` |
| `103` | `fn :: argon2id generate salt Int` | `String` |
| `104` | `fn :: validate argon2 params Argon2Params Tensor[U8]` | `String` |
| `105` | `fn :: finish derive key checked Tensor[U8] Int` | `Argon2KeyRes` |
| `106` | `fn :: finish derive key String Tensor[U8] Argon2Params String` | `Argon2KeyRes` |
| `107` | `fn :: argon2id derive key String String Argon2Params` | `Argon2KeyRes` |
| `108` | `fn :: key res to hex Argon2KeyRes` | `Argon2Res` |
| `109` | `fn :: argon2id derive key hex String String Argon2Params` | `Argon2Res` |
| `110` | `fn :: build phc from tag Tensor[U8] Tensor[U8] Argon2Params` | `Argon2Res` |
| `111` | `fn :: finish argon2id hash ctx String Tensor[U8] String String Argon2Params String` | `Argon2Res` |
| `112` | `fn :: argon2id hash ctx String String String String Argon2Params` | `Argon2Res` |
| `113` | `fn :: argon2id hash bytes String Tensor[U8] Argon2Params` | `Argon2Res` |
| `114` | `fn :: argon2id hash params String String Argon2Params` | `Argon2Res` |
| `115` | `fn :: argon2id hash password String Argon2Params` | `Argon2Res` |
| `116` | `fn :: ct diff loop Tensor[U8] Tensor[U8] Int Int Int` | `Int` |
| `117` | `fn :: constant time bytes eq Tensor[U8] Tensor[U8]` | `Bool` |
| `118` | `fn :: constant time eq String String` | `Bool` |
| `119` | `fn :: split str loop String Int Int Int Int` | `[String]` |
| `120` | `fn :: a2 is digits loop String Int Int` | `Bool` |
| `121` | `fn :: parse kv int String String` | `Int` |
| `122` | `fn :: build parsed phc String String Argon2Params String` | `Argon2PhcRes` |
| `123` | `fn :: decode phc fields String String Int Int Int` | `Argon2PhcRes` |
| `124` | `fn :: parse phc mtp Int Int Int [String]` | `Argon2PhcRes` |
| `125` | `fn :: parse phc kvs [String] [String]` | `Argon2PhcRes` |
| `126` | `fn :: parse phc parts [String]` | `Argon2PhcRes` |
| `127` | `fn :: argon2id parse phc String` | `Argon2PhcRes` |
| `128` | `fn :: check rehash parsed Argon2PhcRes Argon2Params` | `Bool` |
| `129` | `fn :: argon2id needs rehash String Argon2Params` | `Bool` |
| `130` | `fn :: verify parsed ctx Argon2PhcRes String String String` | `Bool` |
| `131` | `fn :: argon2id verify ctx String String String String` | `Bool` |
| `132` | `fn :: argon2id verify String String` | `Bool` |
| `133` | `fn :: unwrap phc res Argon2Res` | `String` |
| `134` | `fn :: argon2id hash String String Int Int Int` | `String` |
| `135` | `fn :: argon2id hash phc String String Int Int Int` | `String` |

---

## 25.3. `argon2id` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `argon2id` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test argon2id.ridgun`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 25.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `argon2id` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `argon2id` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import argon2id

fn :: proteger clave usuario String => String Bool Bool
      proteger clave usuario clave =
        argon2id hash clave "sal-unica-16byte" 32 2 1 -> phc
        argon2id verify clave phc -> valido
        argon2id needs rehash phc (default argon2 params) -> rehash
        (phc, valido, rehash)
```

### 25.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`argon2id` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 38 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import argon2id

fn :: derivar clave maestra String String => Argon2KeyRes
      derivar clave maestra frase sal =
        -- Deriva 32 bytes listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal (argon2 params 64 2 1 32)
```

### 25.3.3. 3. adibidea: OWASP segurtasun-profilak (`Interactive`, `Moderate`, `Sensitive`), `$argon2id$v=19$...` PHC kateen sorrera eta denbora konstanteko egiaztapena

Adibide praktiko honetan `argon2id` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test argon2id phc hashing and verification => ()
      test argon2id phc hashing and verification =
        -- LIB-1: OpenSSL 3.5 / libsodium reference vectors
        v1 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 8 1 1 32))
        v2 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 64 2 1 32))
        v3 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 256 2 1 32))
        v1 -> assert str eq "b7940bccc95f48f2cc7b36f55ff851c356ca4d3a6bc8cd4986a0692f2aac78ec" "LIB-1 vector m=8,t=1,p=1"
        v2 -> assert str eq "e6374c2335a815bcd23a5ea4df06a2f6e5377fc2c3f879865d0828d6e84740f2" "LIB-1 vector m=64,t=2,p=1"
        v3 -> assert str eq "8f65ef99a71b1e98450f2c80d78604af3644276f965db52045bbed139b03b5fd" "LIB-1 vector m=256,t=2,p=1"

        -- LIB-1: RFC 9106 §5.3 official test vector (pwd=32*0x01, salt=16*0x02, secret=8*0x03, ad=12*0x04, m=32, t=3, p=4, tag=32)
        pwd32  = u8 of list [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        salt16 = u8 of list [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        sec8   = tensor to str (u8 of list [3, 3, 3, 3, 3, 3, 3, 3])
        ad12   = tensor to str (u8 of list [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4])
        rfc_h  = bytes to hex (derive raw tag ctx pwd32 salt16 sec8 ad12 (argon2 params 32 3 4 32))
        rfc_h -> assert str eq "0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659" "RFC 9106 §5.3 official vector"

        -- ADR-0010: byte sequences are Tensor[U8] (hex, unpadded Base64, constant-time compare)
        hi_bytes = u8 of list [0, 15, 128, 200, 255]
        bytes to hex hi_bytes -> assert str eq "000f80c8ff" "bytes to hex Tensor[U8]"
        b64 encode nopad hi_bytes -> assert str eq "AA+AyP8" "b64 encode nopad Tensor[U8]"
        b64 encode nopad (u8 of list [102, 111, 111, 98]) -> assert str eq "Zm9vYg" "b64 encode nopad 4 bytes"
        b64 encode nopad (u8 of list [102, 111, 111, 98, 97]) -> assert str eq "Zm9vYmE" "b64 encode nopad 5 bytes"
        bytes to hex (b64 decode nopad "AA+AyP8") -> assert str eq "000f80c8ff" "b64 decode nopad round-trip"
        constant time bytes eq hi_bytes (b64 decode nopad "AA+AyP8") -> assert ok
        constant time bytes eq hi_bytes (u8 of list [0, 15, 128, 200, 254]) -> assert eq False
        constant time bytes eq hi_bytes (u8 of list [0, 15, 128, 200]) -> assert eq False
        bytes to hex (derive raw tag (tensor from str "correct horse") (tensor from str "saltsaltsaltsalt") (argon2 params 8 1 1 32)) -> assert str eq "b7940bccc95f48f2cc7b36f55ff851c356ca4d3a6bc8cd4986a0692f2aac78ec" "derive raw tag Tensor[U8]"

        params   = argon2 params 32 2 2 16
        res1     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res2     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res_diff = argon2id hash params "correct-horse-battery-staple" "othersalt999" params
        is a2 ok res1 -> assert ok
        is a2 ok res2 -> assert ok
        is a2 ok res_diff -> assert ok
        phc1     = unwrap a2 phc res1
        phc2     = unwrap a2 phc res2
        phc_diff = unwrap a2 phc res_diff
        phc1 -> assert eq phc2
        phc1 == phc_diff -> assert eq False
        str starts with phc1 "$argon2id$v=19$m=32,t=2,p=2$" -> assert ok
        bad_t    = argon2id hash params "password" "somesalt1234" (argon2 params 32 0 2 16)
        bad_p    = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 0 16)
        bad_m    = argon2id hash params "password" "somesalt1234" (argon2 params 8 2 2 16)
        bad_tag  = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 2 2)
        bad_salt = argon2id hash params "password" "short" params
        is a2 ok bad_t -> assert eq False
        is a2 ok bad_p -> assert eq False
        is a2 ok bad_m -> assert eq False
        is a2 ok bad_tag -> assert eq False
        is a2 ok bad_salt -> assert eq False

        -- LIB-7: Fixed (password, phc) argument order; never swaps if password starts with "$argon2id$"
        argon2id verify "correct-horse-battery-staple" phc1 -> assert ok
        argon2id verify phc1 "correct-horse-battery-staple" -> assert eq False
        argon2id verify "wrong-password" phc1 -> assert eq False
        tricky_pwd = "$argon2id$v=19$m=32,t=2,p=2$not-a-hash-just-a-password"
        tricky_phc = argon2id hash tricky_pwd "0123456789abcdef" 32 2 1
        argon2id verify tricky_pwd tricky_phc -> assert ok
        argon2id verify tricky_phc tricky_pwd -> assert eq False
        argon2id verify "correct-horse-battery-staple" "$argon2i$v=19$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA" -> assert eq False
        argon2id verify "correct-horse-battery-staple" "$argon2id$v=18$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA" -> assert eq False
        argon2id verify "correct-horse-battery-staple" "malformed_phc_string" -> assert eq False
        constant time eq "abc123xyz" "abc123xyz" -> assert ok
        assert eq (constant time eq "abc123xyz" "abc123xyw") False
```

### 25.3.4. 4. adibidea: Gako bitarren eratorpena (`argon2id derive key`), CSPRNG gatzaren sorrera (`argon2id generate salt`) eta parametroen eguneratze-detekzioa (`argon2id needs rehash`)

Adibide praktiko honetan `argon2id` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test argon2id key derivation salting and rehash => ()
      test argon2id key derivation salting and rehash =
        -- LIB-3: Non-deterministic CSPRNG raw byte salt generation
        salt16    = argon2id generate salt 16
        salt16_b  = argon2id generate salt 16
        salt_min  = argon2id generate salt 2
        str len salt16 -> assert eq 16
        str len salt16_b -> assert eq 16
        str len salt_min -> assert eq 16
        salt16 == salt16_b -> assert eq False

        -- LIB-4: Presets at or above OWASP (19456 KiB) and RFC 9106 §4 (65536 KiB)
        p_def     = default argon2 params
        p_inter   = argon2 interactive params
        p_mod     = argon2 moderate params
        p_sens    = argon2 sensitive params
        m_cost p_def -> assert eq 19456
        t_cost p_def -> assert eq 2
        lanes p_def -> assert eq 1
        tag_len p_def -> assert eq 32
        m_cost p_inter -> assert eq 19456
        m_cost p_mod -> assert eq 47104
        m_cost p_sens -> assert eq 65536
        t_cost p_sens -> assert eq 3
        lanes p_sens -> assert eq 4

        p_fast    = argon2 params 64 2 2 32
        auto_res  = argon2id hash password "my-secret-passphrase" p_fast
        is a2 ok auto_res -> assert ok
        auto_phc  = unwrap a2 phc auto_res
        argon2id verify "my-secret-passphrase" auto_phc -> assert ok
        argon2id verify "other-passphrase" auto_phc -> assert eq False
        parsed    = argon2id parse phc auto_phc
        is phc parsed ok parsed -> assert ok
        is phc parsed ok (argon2id parse phc "invalid_phc") -> assert eq False
        argon2id needs rehash auto_phc p_fast -> assert eq False
        argon2id needs rehash auto_phc p_inter -> assert ok
        argon2id needs rehash auto_phc (argon2 params 64 3 2 32) -> assert ok
        argon2id needs rehash auto_phc (argon2 params 64 2 4 32) -> assert ok
        argon2id needs rehash auto_phc (argon2 params 64 2 2 64) -> assert ok
        argon2id needs rehash "invalid_phc" p_fast -> assert ok
        k_res     = argon2id derive key "encryption-passphrase" "1234567890abcdef" p_fast
        kh_res    = argon2id derive key hex "encryption-passphrase" "1234567890abcdef" p_fast
        k_bad     = argon2id derive key "encryption-passphrase" "short" p_fast
        kh_bad    = argon2id derive key hex "encryption-passphrase" "short" p_fast
        is key ok k_res -> assert ok
        is a2 ok kh_res -> assert ok
        is key ok k_bad -> assert eq False
        is a2 ok kh_bad -> assert eq False
        a2 u8 len (unwrap key bytes k_res) -> assert eq 32
        str len (unwrap a2 phc kh_res) -> assert eq 64
        ctx_res   = argon2id hash ctx "user-password" "1234567890abcdef" "app-pepper-key" "tenant:42" p_fast
        ctx_bad   = argon2id hash ctx "user-password" "short" "app-pepper-key" "tenant:42" p_fast
        is a2 ok ctx_res -> assert ok
        is a2 ok ctx_bad -> assert eq False
        ctx_phc   = unwrap a2 phc ctx_res
        argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:42" -> assert ok
        argon2id verify ctx "user-password" ctx_phc "wrong-pepper" "tenant:42" -> assert eq False
        argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:99" -> assert eq False

        -- RG-051: PHC string with empty tag segment must be rejected by parse & verify
        is phc parsed ok (argon2id parse phc "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$") -> assert eq False
        assert eq (argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$") False
```

### 25.3.5. 5. adibidea: Autentifikazio-fluxu osoa eta segurtasun-politiken migrazio gardena `argon2id verify` eta `argon2id needs rehash` bidez

Adibide praktiko honetan `argon2id` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
import argon2id

fn :: verificar y evaluar politica String String => Bool Bool
      verificar y evaluar politica password phc_guardado =
        es_valida       = argon2id verify password phc_guardado
        requiere_mejora = argon2id needs rehash phc_guardado (argon2 moderate params)
        (es_valida, requiere_mejora)
```

---

## 25.4. Kaputaren azpian: nola dagoen eraikia `argon2id` Ridgun hutsean (`src/main/ridgun/lib/argon2id.ridgun`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/argon2id.ridgun` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 25.4.1. Barne-inplementazioa: Byte (Tensor[U8], ADR-0010), String & 32/64-bit Modular Arithmetic Helpers (Internal)

Ikusi nola `argon2id.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
module :: argon2id

fn :: a2 str list len [String] => Int
      a2 str list len []       =  0
      a2 str list len (_:rest) =  1 + (a2 str list len rest)

fn :: a2 nth str [String] Int => String
      a2 nth str []       _   =  ""
      a2 nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = a2 nth str rest (idx - 1)

-- The tensor is bound to a name: with `_` ridgunc 0.9.49 binds a wrong `n`.
fn :: a2 u8 len Tensor[U8]          => Int
      a2 u8 len (Tensor[U8 * n] bs) =  n

fn :: a2 copy loop Tensor[U8] Int Tensor[U8] Int Int Int => Int
      a2 copy loop dst doff src soff i n =
        | i >= n    = doff + n
        | otherwise =
          dst_(doff + i) = src_(soff + i)
          a2 copy loop dst doff src soff (i + 1) n

-- Copies `n` bytes of `src` from `soff` into `dst` at `doff`; returns `doff + n`.
fn :: a2 copy bytes Tensor[U8] Int Tensor[U8] Int Int => Int
      a2 copy bytes dst doff src soff n =  a2 copy loop dst doff src soff 0 n

-- Writes `w` as 4 little-endian bytes at `off`; returns `off + 4`.
fn :: a2 put u32 Tensor[U8] Int Int => Int
      a2 put u32 t off w =
        uw          = w and 0xFFFFFFFF
        t_(off)     = uw and 255
        t_(off + 1) = (uw shr 8) and 255
        t_(off + 2) = (uw shr 16) and 255
        t_(off + 3) = (uw shr 24) and 255
        off + 4

-- Writes `le32(len src) || src` at `off` (RFC 9106 H0 field); returns the next offset.
fn :: a2 put field Tensor[U8] Int Tensor[U8] => Int
      a2 put field t off src =
        n  = a2 u8 len src
        o1 = a2 put u32 t off n
        a2 copy bytes t o1 src 0 n

fn :: hex digits => String
      hex digits =  "0123456789abcdef"

fn :: byte to hex Int => String
      byte to hex b   =
        ub = b % 256
        hi = (ub / 16) % 16
        lo = ub % 16
        (str slice (hex digits) hi (hi + 1)) + (str slice (hex digits) lo (lo + 1))

fn :: a2 hex code Int => Int
      a2 hex code v   =
        | v < 10    = v + 48
        | otherwise = v + 87

fn :: bytes to hex loop Tensor[U8] Tensor[U8] Int Int => Tensor[U8]
      bytes to hex loop bs out i n =
        | i >= n    = out
        | otherwise =
          b                 = bs_(i)
          out_(2 * i)       = a2 hex code (b shr 4)
          out_((2 * i) + 1) = a2 hex code (b and 15)
          bytes to hex loop bs out (i + 1) n

fn :: bytes to hex Tensor[U8] => String
      bytes to hex bs         =
        n   = a2 u8 len bs
        m   = 2 * n
        out = Tensor[U8 * m]
        tensor to str (bytes to hex loop bs out 0 n)

fn :: byte bitxor Int Int => Int
      byte bitxor a   b   =
        (a xor b) and 255

fn :: u32 norm Int => Int
      u32 norm x   =  x and 0xFFFFFFFF

fn :: u32 add Int Int => Int
      u32 add a   b   =  (a + b) and 0xFFFFFFFF

fn :: u32 bitxor Int Int => Int
      u32 bitxor a   b   =
        (a xor b) and 0xFFFFFFFF

fn :: a2 u64 lh Int Int => U64
      a2 u64 lh lo  hi  =  (lo and 0xFFFFFFFF) or (hi shl 32)

fn :: a2 f blamka U64 U64 => U64
      a2 f blamka x   y   =  x + y + 2 * ((x and 0xFFFFFFFF) * (y and 0xFFFFFFFF))

fn :: a2 bytes to u32 le Tensor[U8] Int => Int
      a2 bytes to u32 le bs         off =
        bs_(off) or (bs_(off + 1) shl 8) or (bs_(off + 2) shl 16) or (bs_(off + 3) shl 24)
```

### 25.4.2. Barne-inplementazioa: Pure-Ridgun RFC 7693 BLAKE2b-512 & Variable-Length H' (`blake2b_long`)

Ikusi nola `argon2id.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: a2 zero w16 => Tensor[U64 * 32]
      a2 zero w16 =  Tensor[U64 * 32]

fn :: a2 zero blk8 => Tensor[U64 * 128]
      a2 zero blk8 =  Tensor[U64 * 128]

fn :: a2 w16 get Tensor[U64 * 32] Int => U64
      a2 w16 get w                idx =  w_(2 * idx) or (w_((2 * idx) + 1) shl 32)

fn :: a2 w16 set Tensor[U64 * 32] Int U64 => Tensor[U64 * 32]
      a2 w16 set w                idx val =
        w_(2 * idx)       = val and 0xFFFFFFFF
        w_((2 * idx) + 1) = (val shr 32) and 0xFFFFFFFF
        w

fn :: a2 b2b iv w16 => Tensor[U64 * 32]
      a2 b2b iv w16 =
        iv = Tensor[U64 * 32]
        a2 w16 set iv 0 (a2 u64 lh 4089235720 1779033703)
        a2 w16 set iv 1 (a2 u64 lh 2227873595 3144134277)
        a2 w16 set iv 2 (a2 u64 lh 4271175723 1013904242)
        a2 w16 set iv 3 (a2 u64 lh 1595750129 2773480762)
        a2 w16 set iv 4 (a2 u64 lh 2917565137 1359893119)
        a2 w16 set iv 5 (a2 u64 lh 725511199  2600822924)
        a2 w16 set iv 6 (a2 u64 lh 4215389547 528734635)
        a2 w16 set iv 7 (a2 u64 lh 327033209  1541459225)

fn :: a2 b2b g4 U64 U64 U64 U64 U64 U64 => U64 U64 U64 U64
      a2 b2b g4 a b c d mx my =
        mut a = a + b + mx
        mut d = (d xor a) rotr 32
        mut c = c + d
        mut b = (b xor c) rotr 24
        a = a + b + my
        d = (d xor a) rotr 16
        c = c + d
        b = (b xor c) rotr 63
        (a, b, c, d)

-- RFC 7693 SIGMA: 10 rows of 16 message-word indices, one hex digit each.
fn :: a2 b2b sigma table => String
      a2 b2b sigma table =  "0123456789abcdefea489fd61c02b753b8c052fdae3671947931dcbe265a40f8905724afe1bc683d2c6a0b834d75fe19c51fed4a0763928bdb7ec13950f4862a6fe9b308c2d714a5a2847615fb9e3cd0"

fn :: a2 sig Int Int => Int
      a2 sig base i   =
        c = str char at (a2 b2b sigma table) (base + i)
        (c and 15) + ((c shr 6) * 9)

fn :: a2 b2b round Tensor[U64 * 32] Tensor[U64 * 32] Int => Tensor[U64 * 32]
      a2 b2b round v m r =
        s       = (r % 10) * 16
        mut v0  = a2 w16 get v 0
        mut v1  = a2 w16 get v 1
        mut v2  = a2 w16 get v 2
        mut v3  = a2 w16 get v 3
        mut v4  = a2 w16 get v 4
        mut v5  = a2 w16 get v 5
        mut v6  = a2 w16 get v 6
        mut v7  = a2 w16 get v 7
        mut v8  = a2 w16 get v 8
        mut v9  = a2 w16 get v 9
        mut v10 = a2 w16 get v 10
        mut v11 = a2 w16 get v 11
        mut v12 = a2 w16 get v 12
        mut v13 = a2 w16 get v 13
        mut v14 = a2 w16 get v 14
        mut v15 = a2 w16 get v 15
        v0, v4, v8,  v12 = a2 b2b g4 v0 v4 v8  v12 (a2 w16 get m (a2 sig s 0))  (a2 w16 get m (a2 sig s 1))
        v1, v5, v9,  v13 = a2 b2b g4 v1 v5 v9  v13 (a2 w16 get m (a2 sig s 2))  (a2 w16 get m (a2 sig s 3))
        v2, v6, v10, v14 = a2 b2b g4 v2 v6 v10 v14 (a2 w16 get m (a2 sig s 4))  (a2 w16 get m (a2 sig s 5))
        v3, v7, v11, v15 = a2 b2b g4 v3 v7 v11 v15 (a2 w16 get m (a2 sig s 6))  (a2 w16 get m (a2 sig s 7))
        v0, v5, v10, v15 = a2 b2b g4 v0 v5 v10 v15 (a2 w16 get m (a2 sig s 8))  (a2 w16 get m (a2 sig s 9))
        v1, v6, v11, v12 = a2 b2b g4 v1 v6 v11 v12 (a2 w16 get m (a2 sig s 10)) (a2 w16 get m (a2 sig s 11))
        v2, v7, v8,  v13 = a2 b2b g4 v2 v7 v8  v13 (a2 w16 get m (a2 sig s 12)) (a2 w16 get m (a2 sig s 13))
        v3, v4, v9,  v14 = a2 b2b g4 v3 v4 v9  v14 (a2 w16 get m (a2 sig s 14)) (a2 w16 get m (a2 sig s 15))
        a2 w16 set v 0  v0
        a2 w16 set v 1  v1
        a2 w16 set v 2  v2
        a2 w16 set v 3  v3
        a2 w16 set v 4  v4
        a2 w16 set v 5  v5
        a2 w16 set v 6  v6
        a2 w16 set v 7  v7
        a2 w16 set v 8  v8
        a2 w16 set v 9  v9
        a2 w16 set v 10 v10
        a2 w16 set v 11 v11
        a2 w16 set v 12 v12
        a2 w16 set v 13 v13
        a2 w16 set v 14 v14
        a2 w16 set v 15 v15

fn :: a2 b2b rounds Tensor[U64 * 32] Tensor[U64 * 32] Int => Tensor[U64 * 32]
      a2 b2b rounds v m r =
        | r >= 12   = v
        | otherwise = a2 b2b rounds (a2 b2b round v m r) m (r + 1)

fn :: a2 b2b compress Tensor[U64 * 32] Tensor[U64 * 32] Int Bool => Tensor[U64 * 32]
      a2 b2b compress h m t is_last =
        iv  = a2 b2b iv w16
        iv6 = a2 w16 get iv 6
        v14 =
          | is_last   = iv6 xor (not 0)
          | otherwise = iv6
        v0  = Tensor[U64 * 32]
        a2 w16 set v0 0  (a2 w16 get h 0)
        a2 w16 set v0 1  (a2 w16 get h 1)
        a2 w16 set v0 2  (a2 w16 get h 2)
        a2 w16 set v0 3  (a2 w16 get h 3)
        a2 w16 set v0 4  (a2 w16 get h 4)
        a2 w16 set v0 5  (a2 w16 get h 5)
        a2 w16 set v0 6  (a2 w16 get h 6)
        a2 w16 set v0 7  (a2 w16 get h 7)
        a2 w16 set v0 8  (a2 w16 get iv 0)
        a2 w16 set v0 9  (a2 w16 get iv 1)
        a2 w16 set v0 10 (a2 w16 get iv 2)
        a2 w16 set v0 11 (a2 w16 get iv 3)
        a2 w16 set v0 12 ((a2 w16 get iv 4) xor (t and 0xFFFFFFFF))
        a2 w16 set v0 13 (a2 w16 get iv 5)
        a2 w16 set v0 14 v14
        a2 w16 set v0 15 (a2 w16 get iv 7)
        vf  = a2 b2b rounds v0 m 0
        out = Tensor[U64 * 32]
        a2 w16 set out 0 (((a2 w16 get h 0) xor (a2 w16 get vf 0)) xor (a2 w16 get vf 8))
        a2 w16 set out 1 (((a2 w16 get h 1) xor (a2 w16 get vf 1)) xor (a2 w16 get vf 9))
        a2 w16 set out 2 (((a2 w16 get h 2) xor (a2 w16 get vf 2)) xor (a2 w16 get vf 10))
        a2 w16 set out 3 (((a2 w16 get h 3) xor (a2 w16 get vf 3)) xor (a2 w16 get vf 11))
        a2 w16 set out 4 (((a2 w16 get h 4) xor (a2 w16 get vf 4)) xor (a2 w16 get vf 12))
        a2 w16 set out 5 (((a2 w16 get h 5) xor (a2 w16 get vf 5)) xor (a2 w16 get vf 13))
        a2 w16 set out 6 (((a2 w16 get h 6) xor (a2 w16 get vf 6)) xor (a2 w16 get vf 14))
        a2 w16 set out 7 (((a2 w16 get h 7) xor (a2 w16 get vf 7)) xor (a2 w16 get vf 15))

fn :: a2 bytes to u64 Tensor[U8] Int => U64
      a2 bytes to u64 bs off =
        a2 u64 lh (a2 bytes to u32 le bs off) (a2 bytes to u32 le bs (off + 4))

fn :: a2 bytes to w16 Tensor[U8] Int => Tensor[U64 * 32]
      a2 bytes to w16 bs off =
        w = Tensor[U64 * 32]
        a2 w16 set w 0  (a2 bytes to u64 bs off)
        a2 w16 set w 1  (a2 bytes to u64 bs (off + 8))
        a2 w16 set w 2  (a2 bytes to u64 bs (off + 16))
        a2 w16 set w 3  (a2 bytes to u64 bs (off + 24))
        a2 w16 set w 4  (a2 bytes to u64 bs (off + 32))
        a2 w16 set w 5  (a2 bytes to u64 bs (off + 40))
        a2 w16 set w 6  (a2 bytes to u64 bs (off + 48))
        a2 w16 set w 7  (a2 bytes to u64 bs (off + 56))
        a2 w16 set w 8  (a2 bytes to u64 bs (off + 64))
        a2 w16 set w 9  (a2 bytes to u64 bs (off + 72))
        a2 w16 set w 10 (a2 bytes to u64 bs (off + 80))
        a2 w16 set w 11 (a2 bytes to u64 bs (off + 88))
        a2 w16 set w 12 (a2 bytes to u64 bs (off + 96))
        a2 w16 set w 13 (a2 bytes to u64 bs (off + 104))
        a2 w16 set w 14 (a2 bytes to u64 bs (off + 112))
        a2 w16 set w 15 (a2 bytes to u64 bs (off + 120))

fn :: a2 h8 bytes loop Tensor[U64 * 32] Tensor[U8] Int Int => Tensor[U8]
      a2 h8 bytes loop h out i n =
        | i >= n    = out
        | otherwise =
          out_(i) = (h_(i shr 2) shr (8 * (i and 3))) and 255
          a2 h8 bytes loop h out (i + 1) n

-- The first `outlen` bytes of the little-endian state words (h holds 32-bit halves, low first).
fn :: a2 h8 to bytes Tensor[U64 * 32] Int    => Tensor[U8]
      a2 h8 to bytes h                outlen =
        out = Tensor[U8 * outlen]
        a2 h8 bytes loop h out 0 outlen

fn :: a2 b2b loop Tensor[U64 * 32] Tensor[U8] Int Int => Tensor[U64 * 32]
      a2 b2b loop h msg off len =
        | (len - off) <= 128 =
          blk = Tensor[U8 * 128]
          a2 copy bytes blk 0 msg off (len - off)
          a2 b2b compress h (a2 bytes to w16 blk 0) len True
        | otherwise =
          h1 = a2 b2b compress h (a2 bytes to w16 msg off) (off + 128) False
          a2 b2b loop h1 msg (off + 128) len

fn :: a2 blake2b Tensor[U8] Int    => Tensor[U8]
      a2 blake2b msg        outlen =
        h_in = a2 b2b iv w16
        a2 w16 set h_in 0 ((a2 w16 get h_in 0) xor ((16842752 + outlen) and 0xFFFFFFFF))
        h_fi = a2 b2b loop h_in msg 0 (a2 u8 len msg)
        a2 h8 to bytes h_fi outlen

-- `le32(outlen) || data`, the input of H' (RFC 9106 §3.3).
fn :: a2 b2b prefixed Tensor[U8] Int    => Tensor[U8]
      a2 b2b prefixed data       outlen =
        n   = a2 u8 len data
        m   = n + 4
        buf = Tensor[U8 * m]
        o1  = a2 put u32 buf 0 outlen
        a2 copy bytes buf o1 data 0 n
        buf

fn :: a2 b2b long loop Tensor[U8] Tensor[U8] Int Int Int => Tensor[U8]
      a2 b2b long loop out v idx r outlen =
        | idx > r =
          rem  = outlen - (32 * r)
          last = a2 blake2b v rem
          a2 copy bytes out (32 * r) last 0 rem
          out
        | otherwise =
          v_next = a2 blake2b v 64
          a2 copy bytes out (32 * (idx - 1)) v_next 0 32
          a2 b2b long loop out v_next (idx + 1) r outlen

fn :: a2 blake2b long Tensor[U8] Int    => Tensor[U8]
      a2 blake2b long data       outlen =
        | outlen <= 64 = a2 blake2b (a2 b2b prefixed data outlen) outlen
        | otherwise =
          r   = ((outlen + 31) / 32) - 2
          v1  = a2 blake2b (a2 b2b prefixed data outlen) 64
          out = Tensor[U8 * outlen]
          a2 copy bytes out 0 v1 0 32
          a2 b2b long loop out v1 2 r outlen
```

### 25.4.3. Barne-inplementazioa: The Blamka Permutation on Whole Tensors and the Compression Function G (RFC 9106 §3.5-3.6)

Ikusi nola `argon2id.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
-- The numbers 0..31: lane e = 4 g + j is word j of the quarter of group g (a row or a column).
fn :: a2 lane ids Tensor[U64 * n] Int => Tensor[U64 * n]
      a2 lane ids t e =
        | e >= 32   = t
        | otherwise =
          t_(e) = e
          a2 lane ids t (e + 1)

-- The Blamka permutation P (RFC 9106 §3.6) on the eight rows of a block at once.
-- a, b, c, d hold words 0-3, 4-7, 8-11, 12-15 of each row: lane e reads word 16 (e / 4) + 4 k + (e % 4).
-- The four column steps are element-wise; the diagonal step reads b, c, d rotated by 1, 2, 3 lanes inside each row,
-- so its results stay rotated: `a2 put rows` puts them back.
fn :: a2 perm rows Tensor[U64 * m] Tensor[U64 * n] => Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n]
      a2 perm rows q e =
        a0 = q_((((e_i shr 2) shl 4) + (e_i and 3)))
        b0 = q_((((e_i shr 2) shl 4) + (e_i and 3)) + 4)
        c0 = q_((((e_i shr 2) shl 4) + (e_i and 3)) + 8)
        d0 = q_((((e_i shr 2) shl 4) + (e_i and 3)) + 12)
        ca1 = (a0_i + b0_i) + (((a0_i and 0xFFFFFFFF) * (b0_i and 0xFFFFFFFF)) shl 1)
        cd1 = (d0_i xor ca1_i) rotr 32
        cc1 = (c0_i + cd1_i) + (((c0_i and 0xFFFFFFFF) * (cd1_i and 0xFFFFFFFF)) shl 1)
        cb1 = (b0_i xor cc1_i) rotr 24
        ca2 = (ca1_i + cb1_i) + (((ca1_i and 0xFFFFFFFF) * (cb1_i and 0xFFFFFFFF)) shl 1)
        cd2 = (cd1_i xor ca2_i) rotr 16
        cc2 = (cc1_i + cd2_i) + (((cc1_i and 0xFFFFFFFF) * (cd2_i and 0xFFFFFFFF)) shl 1)
        cb2 = (cb1_i xor cc2_i) rotr 63
        bx = cb2_((e_i and 28) + ((e_i + 1) and 3))
        cx = cc2_((e_i and 28) + ((e_i + 2) and 3))
        dx = cd2_((e_i and 28) + ((e_i + 3) and 3))
        da1 = (ca2_i + bx_i) + (((ca2_i and 0xFFFFFFFF) * (bx_i and 0xFFFFFFFF)) shl 1)
        dd1 = (dx_i xor da1_i) rotr 32
        dc1 = (cx_i + dd1_i) + (((cx_i and 0xFFFFFFFF) * (dd1_i and 0xFFFFFFFF)) shl 1)
        db1 = (bx_i xor dc1_i) rotr 24
        da2 = (da1_i + db1_i) + (((da1_i and 0xFFFFFFFF) * (db1_i and 0xFFFFFFFF)) shl 1)
        dd2 = (dd1_i xor da2_i) rotr 16
        dc2 = (dc1_i + dd2_i) + (((dc1_i and 0xFFFFFFFF) * (dd2_i and 0xFFFFFFFF)) shl 1)
        db2 = (db1_i xor dc2_i) rotr 63
        (da2, db2, dc2, dd2)

-- The same permutation on the eight columns: column c is words 2 c and 2 c + 1 of every row.
-- Lane e reads word 2 (e / 4) + 16 (2 k + (e % 4) / 2) + (e % 2).
fn :: a2 perm cols Tensor[U64 * m] Tensor[U64 * n] => Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n] Tensor[U64 * n]
      a2 perm cols q e =
        a0 = q_((((e_i shr 2) shl 1) + (((e_i and 3) shr 1) shl 4) + (e_i and 1)))
        b0 = q_((((e_i shr 2) shl 1) + (((e_i and 3) shr 1) shl 4) + (e_i and 1)) + 32)
        c0 = q_((((e_i shr 2) shl 1) + (((e_i and 3) shr 1) shl 4) + (e_i and 1)) + 64)
        d0 = q_((((e_i shr 2) shl 1) + (((e_i and 3) shr 1) shl 4) + (e_i and 1)) + 96)
        ca1 = (a0_i + b0_i) + (((a0_i and 0xFFFFFFFF) * (b0_i and 0xFFFFFFFF)) shl 1)
        cd1 = (d0_i xor ca1_i) rotr 32
        cc1 = (c0_i + cd1_i) + (((c0_i and 0xFFFFFFFF) * (cd1_i and 0xFFFFFFFF)) shl 1)
        cb1 = (b0_i xor cc1_i) rotr 24
        ca2 = (ca1_i + cb1_i) + (((ca1_i and 0xFFFFFFFF) * (cb1_i and 0xFFFFFFFF)) shl 1)
        cd2 = (cd1_i xor ca2_i) rotr 16
        cc2 = (cc1_i + cd2_i) + (((cc1_i and 0xFFFFFFFF) * (cd2_i and 0xFFFFFFFF)) shl 1)
        cb2 = (cb1_i xor cc2_i) rotr 63
        bx = cb2_((e_i and 28) + ((e_i + 1) and 3))
        cx = cc2_((e_i and 28) + ((e_i + 2) and 3))
        dx = cd2_((e_i and 28) + ((e_i + 3) and 3))
        da1 = (ca2_i + bx_i) + (((ca2_i and 0xFFFFFFFF) * (bx_i and 0xFFFFFFFF)) shl 1)
        dd1 = (dx_i xor da1_i) rotr 32
        dc1 = (cx_i + dd1_i) + (((cx_i and 0xFFFFFFFF) * (dd1_i and 0xFFFFFFFF)) shl 1)
        db1 = (bx_i xor dc1_i) rotr 24
        da2 = (da1_i + db1_i) + (((da1_i and 0xFFFFFFFF) * (db1_i and 0xFFFFFFFF)) shl 1)
        dd2 = (dd1_i xor da2_i) rotr 16
        dc2 = (dc1_i + dd2_i) + (((dc1_i and 0xFFFFFFFF) * (dd2_i and 0xFFFFFFFF)) shl 1)
        db2 = (db1_i xor dc2_i) rotr 63
        (da2, db2, dc2, dd2)

fn :: a2 bitxor blk8 Tensor[U64 * 128] Tensor[U64 * 128] => Tensor[U64 * 128]
      a2 bitxor blk8 a b =  a_i xor b_i

-- P on every row and then on every column of `r` (RFC 9106 §3.5).
-- The results come back rotated by k lanes (see `a2 perm rows`); the indexed writes put each lane in its word.
fn :: a2 blamka block Tensor[U64 * 128] => Tensor[U64 * 128]
      a2 blamka block r =
        e  = a2 lane ids (Tensor[U64 * 32]) 0
        ra, rb, rc, rd = a2 perm rows r e
        q  = Tensor[U64 * 128]
        q_(((e_i shr 2) shl 4) + (e_i and 3)) = ra_i
        q_((((e_i shr 2) shl 4) + 4) + ((e_i + 1) and 3)) = rb_i
        q_((((e_i shr 2) shl 4) + 8) + ((e_i + 2) and 3)) = rc_i
        q_((((e_i shr 2) shl 4) + 12) + ((e_i + 3) and 3)) = rd_i
        ka, kb, kc, kd = a2 perm cols q e
        z  = Tensor[U64 * 128]
        z_((((e_i shr 2) shl 1) + (((e_i and 3) shr 1) shl 4)) + (e_i and 1)) = ka_i
        z_(((((e_i shr 2) shl 1) + ((((e_i + 1) and 3) shr 1) shl 4)) + 32) + ((e_i + 1) and 1)) = kb_i
        z_(((((e_i shr 2) shl 1) + ((((e_i + 2) and 3) shr 1) shl 4)) + 64) + ((e_i + 2) and 1)) = kc_i
        z_(((((e_i shr 2) shl 1) + ((((e_i + 3) and 3) shr 1) shl 4)) + 96) + ((e_i + 3) and 1)) = kd_i
        z

-- G(x, y) = P(x xor y) xor x xor y (RFC 9106 §3.5).
fn :: a2 compress blk8 Tensor[U64 * 128] Tensor[U64 * 128] => Tensor[U64 * 128]
      a2 compress blk8 x y =
        r = a2 bitxor blk8 x y
        a2 bitxor blk8 (a2 blamka block r) r

-- The same, XORed onto the block already at that place (passes after the first, RFC 9106 §3.4).
fn :: a2 compress blk8 bxor Tensor[U64 * 128] Tensor[U64 * 128] Tensor[U64 * 128] => Tensor[U64 * 128]
      a2 compress blk8 bxor x y old =
        r = a2 bitxor blk8 x y
        a2 bitxor3 (a2 blamka block r) r old
```

### 25.4.4. Barne-inplementazioa: Presets, Salt Generation, Key Derivation, PHC & Rehash API

Ikusi nola `argon2id.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
-- Preset profiles (`m_cost` is in KiB: 19456 KiB = 19 MiB OWASP minimum;
-- 47104 KiB = 46 MiB OWASP moderate; 65536 KiB = 64 MiB RFC 9106 §4 second option)
fn :: default argon2 params => Argon2Params
      default argon2 params =  Argon2Params 19456 2 1 32 19

fn :: argon2 interactive params => Argon2Params
      argon2 interactive params =  Argon2Params 19456 2 1 32 19

fn :: argon2 moderate params => Argon2Params
      argon2 moderate params =  Argon2Params 47104 3 1 32 19

fn :: argon2 sensitive params => Argon2Params
      argon2 sensitive params =  Argon2Params 65536 3 4 32 19

fn :: argon2 params Int Int Int Int => Argon2Params
      argon2 params m_cost t_cost lanes tag_len = Argon2Params m_cost t_cost lanes tag_len 19

fn :: clamp salt len Int => Int
      clamp salt len n   =
        | n < 16    = 16
        | n > 64    = 64
        | otherwise = n

fn :: a2 random next Tensor[U8] Int Int Tensor[U8] Int => Int
      a2 random next buf        off n   tmp        rc  =
        | rc == (0 - 4) = a2 random fill buf off n
        | rc <= 0       = rc
        | otherwise     = a2 random fill buf (a2 copy bytes buf off tmp 0 rc) n

-- Fills `buf[off..n)` from getrandom(2); retries on EINTR and on short reads.
fn :: a2 random fill Tensor[U8] Int Int => Int
      a2 random fill buf        off n   =
        | off >= n  = 0
        | otherwise =
          rem = n - off
          tmp = Tensor[U8 * rem]
          a2 random next buf off n tmp (sys call (nr getrandom) tmp rem 0 0 0 0)

fn :: argon2id generate salt Int => String
      argon2id generate salt n   =
        eff_n = clamp salt len n
        buf   = Tensor[U8 * eff_n]
        a2 random fill buf 0 eff_n
        tensor to str buf

fn :: validate argon2 params Argon2Params Tensor[U8] => String
      validate argon2 params params       salt_bytes =
        | (version params) != 19                        = "unsupported Argon2 version (expected 19)"
        | (t_cost params) < 1                           = "t_cost must be >= 1"
        | (lanes params) < 1 or (lanes params) > 255    = "lanes must be in 1..255"
        | (m_cost params) < (8 * (lanes params))        = "m_cost must be >= 8 * lanes"
        | (tag_len params) < 4 or (tag_len params) > 64 = "tag_len must be in 4..64"
        | (a2 u8 len salt_bytes) < 8                    = "salt must be at least 8 bytes"
        | otherwise                                     = ""

fn :: finish derive key checked Tensor[U8] Int => Argon2KeyRes
      finish derive key checked tag_raw exp_len =
        | (a2 u8 len tag_raw) != exp_len = Argon2KeyErr "tag derivation failed"
        | otherwise                      = Argon2KeyOk tag_raw

fn :: finish derive key String Tensor[U8] Argon2Params String => Argon2KeyRes
      finish derive key pwd salt_bytes params err =
        | (str len err) > 0 = Argon2KeyErr err
        | otherwise         =
          tag_raw = derive raw tag (tensor from str pwd) salt_bytes params
          finish derive key checked tag_raw (tag_len params)

fn :: argon2id derive key String String Argon2Params => Argon2KeyRes
      argon2id derive key pwd salt params =
        salt_bytes = tensor from str salt
        finish derive key pwd salt_bytes params (validate argon2 params params salt_bytes)

fn :: key res to hex Argon2KeyRes       => Argon2Res
      key res to hex (Argon2KeyErr err) =  Argon2Err err
      key res to hex (Argon2KeyOk bytes) = Argon2Ok (bytes to hex bytes)

fn :: argon2id derive key hex String String Argon2Params => Argon2Res
      argon2id derive key hex pwd salt params = key res to hex (argon2id derive key pwd salt params)

fn :: build phc from tag Tensor[U8] Tensor[U8] Argon2Params => Argon2Res
      build phc from tag salt_bytes tag_raw params =
        | (a2 u8 len tag_raw) != (tag_len params) = Argon2Err "tag derivation failed"
        | otherwise =
          salt_b64 = b64 encode nopad salt_bytes
          tag_b64  = b64 encode nopad tag_raw
          m        = m_cost params
          t        = t_cost params
          p        = lanes params
          Argon2Ok "$argon2id$v=19$m={m},t={t},p={p}${salt_b64}${tag_b64}"

fn :: finish argon2id hash ctx String Tensor[U8] String String Argon2Params String => Argon2Res
      finish argon2id hash ctx pwd salt_bytes secret ad params err =
        | (str len err) > 0 = Argon2Err err
        | otherwise =
          pwd_raw = tensor from str pwd
          tag_raw = derive raw tag ctx pwd_raw salt_bytes secret ad params
          build phc from tag salt_bytes tag_raw params

fn :: argon2id hash ctx String String String String Argon2Params => Argon2Res
      argon2id hash ctx pwd salt secret ad params =
        salt_bytes = tensor from str salt
        finish argon2id hash ctx pwd salt_bytes secret ad params (validate argon2 params params salt_bytes)

fn :: argon2id hash bytes String Tensor[U8] Argon2Params => Argon2Res
      argon2id hash bytes pwd salt_bytes params =
        finish argon2id hash ctx pwd salt_bytes "" "" params (validate argon2 params params salt_bytes)

fn :: argon2id hash params String String Argon2Params => Argon2Res
      argon2id hash params pwd salt params = argon2id hash bytes pwd (tensor from str salt) params

fn :: argon2id hash password String Argon2Params => Argon2Res
      argon2id hash password pwd    params       =  argon2id hash params pwd (argon2id generate salt 16) params

fn :: ct diff loop Tensor[U8] Tensor[U8] Int Int Int => Int
      ct diff loop a          b          i   n   acc =
        | i >= n    = acc
        | otherwise = ct diff loop a b (i + 1) n (acc or (byte bitxor a_(i) b_(i)))

-- Compares every byte of the common prefix without early exit; equal only when lengths match too.
fn :: constant time bytes eq Tensor[U8] Tensor[U8] => Bool
      constant time bytes eq a          b          =
        la   = a2 u8 len a
        lb   = a2 u8 len b
        n    =
          | la < lb   = la
          | otherwise = lb
        diff = ct diff loop a b 0 n 0
        (la == lb) and (diff == 0)

fn :: constant time eq String String => Bool
      constant time eq a      b      =  constant time bytes eq (tensor from str a) (tensor from str b)

fn :: split str loop String Int Int Int Int => [String]
      split str loop s ch start idx len =
        | idx >= len                = [(str slice s start len)]
        | (str char at s idx) == ch = [(str slice s start idx)] :: (split str loop s ch (idx + 1) (idx + 1) len)
        | otherwise                 = split str loop s ch start (idx + 1) len

fn :: a2 is digits loop String Int Int => Bool
      a2 is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = a2 is digits loop s (idx + 1) len

fn :: parse kv int String String => Int
      parse kv int item   prefix =
        | (str len item) <= (str len prefix)                           = 0 - 1
        | not (str starts with item prefix)                            = 0 - 1
        | not (a2 is digits loop item (str len prefix) (str len item)) = 0 - 1
        | otherwise                                                    = str to int (str slice item (str len prefix) (str len item))

fn :: build parsed phc String String Argon2Params String => Argon2PhcRes
      build parsed phc s_b64 t_b64 params err =
        | (str len err) > 0 = Argon2PhcErr err
        | otherwise         = Argon2PhcOk (Argon2Phc params s_b64 t_b64)

fn :: decode phc fields String String Int Int Int => Argon2PhcRes
      decode phc fields s_b64 t_b64 m t p =
        | not (is valid b64 nopad s_b64) = Argon2PhcErr "invalid Base64 salt in PHC string"
        | not (is valid b64 nopad t_b64) = Argon2PhcErr "invalid Base64 tag in PHC string"
        | otherwise =
          salt_bytes = b64 decode nopad s_b64
          tag_bytes  = b64 decode nopad t_b64
          params     = Argon2Params m t p (a2 u8 len tag_bytes) 19
          build parsed phc s_b64 t_b64 params (validate argon2 params params salt_bytes)

fn :: parse phc mtp Int Int Int [String] => Argon2PhcRes
      parse phc mtp m t p parts =
        | m < 8 or t < 1 or p < 1 = Argon2PhcErr "invalid m, t, or p in PHC string"
        | otherwise               = decode phc fields (a2 nth str parts 4) (a2 nth str parts 5) m t p

fn :: parse phc kvs [String] [String] => Argon2PhcRes
      parse phc kvs parts    kvs      =
        | (a2 str list len kvs) != 3 = Argon2PhcErr "expected m,t,p parameters in PHC string"
        | otherwise =
          m = parse kv int (a2 nth str kvs 0) "m="
          t = parse kv int (a2 nth str kvs 1) "t="
          p = parse kv int (a2 nth str kvs 2) "p="
          parse phc mtp m t p parts

fn :: parse phc parts [String] => Argon2PhcRes
      parse phc parts parts    =
        | (a2 str list len parts) != 6       = Argon2PhcErr "invalid PHC segment count"
        | (a2 nth str parts 0) != ""         = Argon2PhcErr "PHC string must start with $"
        | (a2 nth str parts 1) != "argon2id" = Argon2PhcErr "unsupported algorithm (expected argon2id)"
        | (a2 nth str parts 2) != "v=19"     = Argon2PhcErr "unsupported version (expected v=19)"
        | otherwise =
          p_str = a2 nth str parts 3
          parse phc kvs parts (split str loop p_str 44 0 0 (str len p_str))

fn :: argon2id parse phc String => Argon2PhcRes
      argon2id parse phc phc    =  parse phc parts (split str loop phc 36 0 0 (str len phc))

fn :: check rehash parsed Argon2PhcRes     Argon2Params => Bool
      check rehash parsed (Argon2PhcErr _) _            =  True
      check rehash parsed (Argon2PhcOk parsed) target   =
        cur = params parsed
        ((m_cost cur) != (m_cost target)) or ((t_cost cur) != (t_cost target)) or ((lanes cur) != (lanes target)) or ((tag_len cur) != (tag_len target))

fn :: argon2id needs rehash String Argon2Params => Bool
      argon2id needs rehash phc    target       =  check rehash parsed (argon2id parse phc phc) target

fn :: verify parsed ctx Argon2PhcRes String String String => Bool
      verify parsed ctx (Argon2PhcErr _) _ _ _ = False
      verify parsed ctx (Argon2PhcOk parsed) pwd secret ad =
        parsed salt_b64 -> b64 decode nopad -> salt_bytes
        parsed tag_b64 -> b64 decode nopad -> tag_bytes
        tensor from str pwd -> pwd_bytes
        derive raw tag ctx pwd_bytes salt_bytes secret ad (params parsed) -> computed
        constant time bytes eq computed tag_bytes

fn :: argon2id verify ctx String String String String => Bool
      argon2id verify ctx pwd phc secret ad =
        phc argon2id parse phc -> parsed
        verify parsed ctx parsed pwd secret ad

fn :: argon2id verify String String => Bool
      argon2id verify pwd    phc    =
        | not (str starts with phc "$argon2id$") = False
        | otherwise                              = argon2id verify ctx pwd phc "" ""

fn :: unwrap phc res Argon2Res      => String
      unwrap phc res (Argon2Ok phc) =  phc
      unwrap phc res (Argon2Err _)  =  ""

fn :: argon2id hash String String Int Int Int => String
      argon2id hash pwd salt m_kib t_iters p_lanes =
        argon2id hash params pwd salt (Argon2Params m_kib t_iters p_lanes 32 19) -> unwrap phc res

fn :: argon2id hash phc String String Int Int Int => String
      argon2id hash phc pwd salt m_kib t_iters p_lanes =
        argon2id hash pwd salt m_kib t_iters p_lanes
```

---

## 25.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `argon2id`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Bat-etortze zehatza bytez byte RFC 9106 §5.3 eta OpenSSL 3.5 bektore ofizialekin, `Tensor[U64 * 128]` gainean C lerro bakar bat ere gabe lan eginez.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/argon2id.ridgun`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test argon2id.ridgun` suite automatizatuaren bidez.

### `argon2id`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import argon2id` fitxategiaren hasieran** eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `argon2id`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `argon2id`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `argon2id` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**26. kapituluan** **`jwt`** lib-a sakonki esploratuko dugu (`jwt` lib-a — RFC 7519 JSON Web Tokenak (`HS256`) eta ChaCha20-Poly1305 Token Zifratuak).
