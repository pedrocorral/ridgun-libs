# 25. kapitulua: `argon2id` lib-a — RFC 9106 Argon2id `Tensor[U64 * 8 * 16]` gainean, Blake2b eta OWASP Aurrezarpenak

## 25.1. Zergatik existitzen da `argon2id` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `argon2id` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `argon2id`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: pasahitzak SHA-256 soil batekin gordetzeak GPU moderno bati segundoko milaka milioi konbinazio probatzea ahalbidetzen dio, baina Argon2id izateko kanpoko C liburutegiak estekatzeak konpilazio- eta memoria-buruhausteak ekartzen ditu.

**`argon2id`** lib-ak **RFC 9106 Argon2id** eta **RFC 7693 Blake2b-512** % 100ean Ridgun hutsean inplementatzen ditu `Tensor[U64 * 8 * 16]` bloke natiboen gainean (1 024 byte blokeko RMM2 memoria jarraituan), **PHC** kateen sorrerarekin (`$argon2id$v=19$m=...,t=...,p=...$`), **OWASP** profilekin (`owaspfirst`, `owaspsecond`), *pepper* euskarriarekin (`argon2id hash ctx`), gakoen eratorpenarekin (`argon2id derive key`) eta parametroen eguneratze-detekzioarekin (`argon2id needs rehash`).

Ekosistema tradizional batean, **`CRYPTO`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`argon2id`** lib-ak (`src/main/ridgun/lib/argon2id.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `argon2id`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `argon2id`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `argon2id`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 25.2. Artefaktu natiboak, inportazioa eta `argon2id` APIaren katalogo osoa

`ridgun-libs`-en, **`argon2id`** lehen mailako **lib** bat da, `src/main/ridgun/lib/argon2id.rg` bidean kokatua (`CRYPTO` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/argon2id.rglib` | Banaketa eta inportazio zuzena `import argon2id` bidez |
| **Fitxategi konpilatua** | `target/argon2id.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libargon2id.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import argon2id` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 25.2.1. `argon2id`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `argon2id hash / argon2id verify` | 6 argumentuko RFC 9106 PHC pasahitz-hashinga (`pwd, salt, m_kib, t, p, tag_len`) eta denbora konstanteko egiaztapena |
| `argon2id hash with preset / argon2id params preset` | Izendun profilak: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | RFC 9106 hashinga `pepper` sekretuarekin ($K$) eta datu elkartuekin ($X$) |
| `argon2id derive key / argon2id needs rehash` | Gako bitar gordinaren eratorpena eta PHC kateetan rehash beharraren detekzioa |
| `blake2b / blake2b hex` | Helburu orokorreko RFC 7693 Blake2b laburpen kriptografikoa (`1..64` byte) |

### 25.2.2. `src/main/ridgun/lib/argon2id.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/argon2id.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`10` mota, `0` eragile eta `125` funtzio):

**`argon2id`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type Argon2Params = m_cost: Int, t_cost: Int, lanes: Int, tag_len: Int, version: Int
type Argon2Phc    = params: Argon2Params, salt_b64: String, tag_b64: String
type Argon2Res    = Argon2Ok String | Argon2Err String
type Argon2KeyRes = Argon2KeyOk [Int] | Argon2KeyErr String
type Argon2PhcRes = Argon2PhcOk Argon2Phc | Argon2PhcErr String
type A2M16   = mb0: Tensor[U64 * 8 * 16], mb1: Tensor[U64 * 8 * 16], mb2: Tensor[U64 * 8 * 16], mb3: Tensor[U64 * 8 * 16], mb4: Tensor[U64 * 8 * 16], mb5: Tensor[U64 * 8 * 16], mb6: Tensor[U64 * 8 * 16], mb7: Tensor[U64 * 8 * 16], mb8: Tensor[U64 * 8 * 16], mb9: Tensor[U64 * 8 * 16], mb10: Tensor[U64 * 8 * 16], mb11: Tensor[U64 * 8 * 16], mb12: Tensor[U64 * 8 * 16], mb13: Tensor[U64 * 8 * 16], mb14: Tensor[U64 * 8 * 16], mb15: Tensor[U64 * 8 * 16]
type A2M256  = mr0: A2M16, mr1: A2M16, mr2: A2M16, mr3: A2M16, mr4: A2M16, mr5: A2M16, mr6: A2M16, mr7: A2M16, mr8: A2M16, mr9: A2M16, mr10: A2M16, mr11: A2M16, mr12: A2M16, mr13: A2M16, mr14: A2M16, mr15: A2M16
type A2M4096 = mp0: A2M256, mp1: A2M256, mp2: A2M256, mp3: A2M256, mp4: A2M256, mp5: A2M256, mp6: A2M256, mp7: A2M256, mp8: A2M256, mp9: A2M256, mp10: A2M256, mp11: A2M256, mp12: A2M256, mp13: A2M256, mp14: A2M256, mp15: A2M256
type A2Mem   = mt0: A2M4096, mt1: A2M4096, mt2: A2M4096, mt3: A2M4096, mt4: A2M4096, mt5: A2M4096, mt6: A2M4096, mt7: A2M4096, mt8: A2M4096, mt9: A2M4096, mt10: A2M4096, mt11: A2M4096, mt12: A2M4096, mt13: A2M4096, mt14: A2M4096, mt15: A2M4096
type A2Ctx   = r_pass: Int, s_slice: Int, l_lane: Int, p_lanes: Int, q_cols: Int, seg_len: Int, t_iters: Int
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: a2 list len [Int]` | `Int` |
| `2` | `fn :: a2 str list len [String]` | `Int` |
| `3` | `fn :: a2 nth int [Int] Int` | `Int` |
| `4` | `fn :: a2 nth str [String] Int` | `String` |
| `5` | `fn :: a2 take ints [Int] Int` | `[Int]` |
| `6` | `fn :: a2 drop ints [Int] Int` | `[Int]` |
| `7` | `fn :: a2 pad zeroes Int` | `[Int]` |
| `8` | `fn :: a2 raw byte ub Int` | `String` |
| `9` | `fn :: a2 raw byte Int` | `String` |
| `10` | `fn :: a2 str to bytes loop String Int Int` | `[Int]` |
| `11` | `fn :: a2 str to bytes String` | `[Int]` |
| `12` | `fn :: a2 bytes to str [Int]` | `String` |
| `13` | `fn :: hex digits` | `String` |
| `14` | `fn :: byte to hex Int` | `String` |
| `15` | `fn :: bytes to hex [Int]` | `String` |
| `16` | `fn :: byte bitxor Int Int` | `Int` |
| `17` | `fn :: u32 norm Int` | `Int` |
| `18` | `fn :: u32 add Int Int` | `Int` |
| `19` | `fn :: u32 bitxor Int Int` | `Int` |
| `20` | `fn :: a2 u64 lh Int Int` | `U64` |
| `21` | `fn :: a2 f blamka U64 U64` | `U64` |
| `22` | `fn :: a2 u32 to le4 Int` | `[Int]` |
| `23` | `fn :: a2 bytes to u32 le [Int] Int` | `Int` |
| `24` | `fn :: a2 zero w16` | `Tensor[U64 * 16]` |
| `25` | `fn :: a2 zero blk8` | `Tensor[U64 * 8 * 16]` |
| `26` | `fn :: a2 b2b iv w16` | `Tensor[U64 * 16]` |
| `27` | `fn :: a2 b2b g4 U64 U64 U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `28` | `fn :: a2 b2b sigma Int` | `[Int]` |
| `29` | `fn :: a2 b2b round Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `30` | `fn :: a2 b2b rounds Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `31` | `fn :: a2 b2b compress Tensor[U64 * 16] Tensor[U64 * 16] Int Bool` | `Tensor[U64 * 16]` |
| `32` | `fn :: a2 bytes to u64 [Int] Int` | `U64` |
| `33` | `fn :: a2 bytes to w16 [Int] Int` | `Tensor[U64 * 16]` |
| `34` | `fn :: a2 u64 to le8 U64` | `[Int]` |
| `35` | `fn :: a2 h8 to bytes Tensor[U64 * 16]` | `[Int]` |
| `36` | `fn :: a2 b2b loop Tensor[U64 * 16] [Int] Int` | `Tensor[U64 * 16]` |
| `37` | `fn :: a2 blake2b [Int] Int` | `[Int]` |
| `38` | `fn :: a2 b2b long loop [Int] Int Int Int` | `[Int]` |
| `39` | `fn :: a2 blake2b long [Int] Int` | `[Int]` |
| `40` | `fn :: a2 blamka g U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `41` | `fn :: a2 blamka p16 Tensor[U64 * 16]` | `()` |
| `42` | `fn :: a2 blamka col pair Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `43` | `fn :: a2 blamka cols loop Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `44` | `fn :: a2 bitxor blk8 Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `45` | `fn :: a2 compress blk8 Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `46` | `fn :: a2 get blk8 Tensor[U64 * 8 * 16] Int` | `U64` |
| `47` | `fn :: a2 bytes to blk8 row Tensor[U64 * 8 * 16] Int [Int] Int` | `Tensor[U64 * 8 * 16]` |
| `48` | `fn :: a2 bytes to blk8 loop Tensor[U64 * 8 * 16] Int [Int]` | `Tensor[U64 * 8 * 16]` |
| `49` | `fn :: a2 bytes to blk8 [Int]` | `Tensor[U64 * 8 * 16]` |
| `50` | `fn :: a2 blk8 row to bytes Tensor[U64 * 8 * 16] Int Int` | `[Int]` |
| `51` | `fn :: a2 blk8 to bytes loop Tensor[U64 * 8 * 16] Int` | `[Int]` |
| `52` | `fn :: a2 blk8 to bytes Tensor[U64 * 8 * 16]` | `[Int]` |
| `53` | `fn :: a2 zero mem` | `A2Mem` |
| `54` | `fn :: a2 get m16 A2M16 Int` | `Tensor[U64 * 8 * 16]` |
| `55` | `fn :: a2 get m256 A2M256 Int Int` | `Tensor[U64 * 8 * 16]` |
| `56` | `fn :: a2 get m4096 A2M4096 Int Int Int` | `Tensor[U64 * 8 * 16]` |
| `57` | `fn :: a2 get mem A2Mem Int Int Int Int` | `Tensor[U64 * 8 * 16]` |
| `58` | `fn :: a2 nth blk A2Mem Int` | `Tensor[U64 * 8 * 16]` |
| `59` | `fn :: a2 set m16 A2M16 Int Tensor[U64 * 8 * 16]` | `A2M16` |
| `60` | `fn :: a2 set m256 A2M256 Int Int Tensor[U64 * 8 * 16]` | `A2M256` |
| `61` | `fn :: a2 set m4096 A2M4096 Int Int Int Tensor[U64 * 8 * 16]` | `A2M4096` |
| `62` | `fn :: a2 set mem A2Mem Int Int Int Int Tensor[U64 * 8 * 16]` | `A2Mem` |
| `63` | `fn :: a2 set blk A2Mem Int Tensor[U64 * 8 * 16]` | `A2Mem` |
| `64` | `fn :: a2 init all lanes loop A2Mem [Int] Int Int Int` | `A2Mem` |
| `65` | `fn :: a2 init all lanes [Int] Int Int Int` | `A2Mem` |
| `66` | `fn :: a2 make addr blk A2Ctx Int` | `Tensor[U64 * 8 * 16]` |
| `67` | `fn :: a2 calc w size A2Ctx Int Bool` | `Int` |
| `68` | `fn :: a2 fill segment A2Mem A2Ctx Int Tensor[U64 * 8 * 16]` | `A2Mem` |
| `69` | `fn :: a2 run lanes A2Mem A2Ctx Int` | `A2Mem` |
| `70` | `fn :: a2 run slices A2Mem A2Ctx Int` | `A2Mem` |
| `71` | `fn :: a2 run passes A2Mem A2Ctx Int` | `A2Mem` |
| `72` | `fn :: a2 bitxor final lanes A2Mem Int Int Int Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `73` | `fn :: derive raw tag ctx [Int] [Int] String String Argon2Params` | `[Int]` |
| `74` | `fn :: derive raw tag [Int] [Int] Argon2Params` | `[Int]` |
| `75` | `fn :: b64 alphabet` | `String` |
| `76` | `fn :: b64 char Int` | `String` |
| `77` | `fn :: b64 encode nopad [Int]` | `String` |
| `78` | `fn :: b64 char val Int` | `Int` |
| `79` | `fn :: valid b64 chars String Int Int` | `Bool` |
| `80` | `fn :: is valid b64 nopad String` | `Bool` |
| `81` | `fn :: b64 decode rem String Int Int Int` | `[Int]` |
| `82` | `fn :: b64 decode loop String Int Int` | `[Int]` |
| `83` | `fn :: b64 decode nopad String` | `[Int]` |
| `84` | `fn :: default argon2 params` | `Argon2Params` |
| `85` | `fn :: argon2 interactive params` | `Argon2Params` |
| `86` | `fn :: argon2 moderate params` | `Argon2Params` |
| `87` | `fn :: argon2 sensitive params` | `Argon2Params` |
| `88` | `fn :: argon2 params Int Int Int Int` | `Argon2Params` |
| `89` | `fn :: clamp salt len Int` | `Int` |
| `90` | `fn :: a2 getrandom call Int Int Int` | `Int` |
| `91` | `fn :: a2 getrandom step Int Int Int` | `Int` |
| `92` | `fn :: a2 getrandom loop Int Int` | `Int` |
| `93` | `fn :: argon2id generate salt Int` | `String` |
| `94` | `fn :: validate argon2 params Argon2Params [Int]` | `String` |
| `95` | `fn :: finish derive key checked [Int] Int` | `Argon2KeyRes` |
| `96` | `fn :: finish derive key String [Int] Argon2Params String` | `Argon2KeyRes` |
| `97` | `fn :: argon2id derive key String String Argon2Params` | `Argon2KeyRes` |
| `98` | `fn :: key res to hex Argon2KeyRes` | `Argon2Res` |
| `99` | `fn :: argon2id derive key hex String String Argon2Params` | `Argon2Res` |
| `100` | `fn :: build phc from tag [Int] [Int] Argon2Params` | `Argon2Res` |
| `101` | `fn :: finish argon2id hash ctx String [Int] String String Argon2Params String` | `Argon2Res` |
| `102` | `fn :: argon2id hash ctx String String String String Argon2Params` | `Argon2Res` |
| `103` | `fn :: argon2id hash bytes String [Int] Argon2Params` | `Argon2Res` |
| `104` | `fn :: argon2id hash params String String Argon2Params` | `Argon2Res` |
| `105` | `fn :: argon2id hash password String Argon2Params` | `Argon2Res` |
| `106` | `fn :: ct diff loop [Int] [Int] Int` | `Int` |
| `107` | `fn :: constant time bytes eq [Int] [Int]` | `Bool` |
| `108` | `fn :: constant time eq String String` | `Bool` |
| `109` | `fn :: split str loop String Int Int Int Int` | `[String]` |
| `110` | `fn :: a2 is digits loop String Int Int` | `Bool` |
| `111` | `fn :: parse kv int String String` | `Int` |
| `112` | `fn :: build parsed phc String String Argon2Params String` | `Argon2PhcRes` |
| `113` | `fn :: decode phc fields String String Int Int Int` | `Argon2PhcRes` |
| `114` | `fn :: parse phc mtp Int Int Int [String]` | `Argon2PhcRes` |
| `115` | `fn :: parse phc kvs [String] [String]` | `Argon2PhcRes` |
| `116` | `fn :: parse phc parts [String]` | `Argon2PhcRes` |
| `117` | `fn :: argon2id parse phc String` | `Argon2PhcRes` |
| `118` | `fn :: check rehash parsed Argon2PhcRes Argon2Params` | `Bool` |
| `119` | `fn :: argon2id needs rehash String Argon2Params` | `Bool` |
| `120` | `fn :: verify parsed ctx Argon2PhcRes String String String` | `Bool` |
| `121` | `fn :: argon2id verify ctx String String String String` | `Bool` |
| `122` | `fn :: argon2id verify String String` | `Bool` |
| `123` | `fn :: unwrap phc res Argon2Res` | `String` |
| `124` | `fn :: argon2id hash String String Int Int Int` | `String` |
| `125` | `fn :: argon2id hash phc String String Int Int Int` | `String` |

---

## 25.3. `argon2id` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `argon2id` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test argon2id.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 25.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `argon2id` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `argon2id` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### 25.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`argon2id` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
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
        _  = assert str eq v1 "b7940bccc95f48f2cc7b36f55ff851c356ca4d3a6bc8cd4986a0692f2aac78ec" "LIB-1 vector m=8,t=1,p=1"
        _  = assert str eq v2 "e6374c2335a815bcd23a5ea4df06a2f6e5377fc2c3f879865d0828d6e84740f2" "LIB-1 vector m=64,t=2,p=1"
        _  = assert str eq v3 "8f65ef99a71b1e98450f2c80d78604af3644276f965db52045bbed139b03b5fd" "LIB-1 vector m=256,t=2,p=1"

        -- LIB-1: RFC 9106 §5.3 official test vector (pwd=32*0x01, salt=16*0x02, secret=8*0x03, ad=12*0x04, m=32, t=3, p=4, tag=32)
        pwd32  = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        salt16 = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        sec8   = a2 bytes to str [3, 3, 3, 3, 3, 3, 3, 3]
        ad12   = a2 bytes to str [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]
        rfc_h  = bytes to hex (derive raw tag ctx pwd32 salt16 sec8 ad12 (argon2 params 32 3 4 32))
        _      = assert str eq rfc_h "0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659" "RFC 9106 §5.3 official vector"

        params   = argon2 params 32 2 2 16
        res1     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res2     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res_diff = argon2id hash params "correct-horse-battery-staple" "othersalt999" params
        _        = assert ok (is a2 ok res1)
        _        = assert ok (is a2 ok res2)
        _        = assert ok (is a2 ok res_diff)
        phc1     = unwrap a2 phc res1
        phc2     = unwrap a2 phc res2
        phc_diff = unwrap a2 phc res_diff
        _        = assert eq phc1 phc2
        _        = assert eq (phc1 == phc_diff) False
        _        = assert ok (str starts with phc1 "$argon2id$v=19$m=32,t=2,p=2$")
        bad_t    = argon2id hash params "password" "somesalt1234" (argon2 params 32 0 2 16)
        bad_p    = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 0 16)
        bad_m    = argon2id hash params "password" "somesalt1234" (argon2 params 8 2 2 16)
        bad_tag  = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 2 2)
        bad_salt = argon2id hash params "password" "short" params
        _        = assert eq (is a2 ok bad_t) False
        _        = assert eq (is a2 ok bad_p) False
        _        = assert eq (is a2 ok bad_m) False
        _        = assert eq (is a2 ok bad_tag) False
        _        = assert eq (is a2 ok bad_salt) False

        -- LIB-7: Fixed (password, phc) argument order; never swaps if password starts with "$argon2id$"
        _          = assert ok (argon2id verify "correct-horse-battery-staple" phc1)
        _          = assert eq (argon2id verify phc1 "correct-horse-battery-staple") False
        _          = assert eq (argon2id verify "wrong-password" phc1) False
        tricky_pwd = "$argon2id$v=19$m=32,t=2,p=2$not-a-hash-just-a-password"
        tricky_phc = argon2id hash tricky_pwd "0123456789abcdef" 32 2 1
        _          = assert ok (argon2id verify tricky_pwd tricky_phc)
        _          = assert eq (argon2id verify tricky_phc tricky_pwd) False
        _          = assert eq (argon2id verify "correct-horse-battery-staple" "$argon2i$v=19$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA") False
        _          = assert eq (argon2id verify "correct-horse-battery-staple" "$argon2id$v=18$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA") False
        _          = assert eq (argon2id verify "correct-horse-battery-staple" "malformed_phc_string") False
        _          = assert ok (constant time eq "abc123xyz" "abc123xyz")
        assert eq (constant time eq "abc123xyz" "abc123xyw") False
```

### 25.3.4. 4. adibidea: Gako bitarren eratorpena (`argon2id derive key`), CSPRNG gatzaren sorrera (`argon2id gen salt`) eta parametroen eguneratze-detekzioa (`argon2id needs rehash`)

Adibide praktiko honetan `argon2id` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test argon2id key derivation salting and rehash => ()
      test argon2id key derivation salting and rehash =
        -- LIB-3: Non-deterministic CSPRNG raw byte salt generation
        salt16    = argon2id generate salt 16
        salt16_b  = argon2id generate salt 16
        salt_min  = argon2id generate salt 2
        _         = assert eq (str len salt16) 16
        _         = assert eq (str len salt16_b) 16
        _         = assert eq (str len salt_min) 16
        _         = assert eq (salt16 == salt16_b) False

        -- LIB-4: Presets at or above OWASP (19456 KiB) and RFC 9106 §4 (65536 KiB)
        p_def     = default argon2 params
        p_inter   = argon2 interactive params
        p_mod     = argon2 moderate params
        p_sens    = argon2 sensitive params
        _         = assert eq (m_cost p_def) 19456
        _         = assert eq (t_cost p_def) 2
        _         = assert eq (lanes p_def) 1
        _         = assert eq (tag_len p_def) 32
        _         = assert eq (m_cost p_inter) 19456
        _         = assert eq (m_cost p_mod) 47104
        _         = assert eq (m_cost p_sens) 65536
        _         = assert eq (t_cost p_sens) 3
        _         = assert eq (lanes p_sens) 4

        p_fast    = argon2 params 64 2 2 32
        auto_res  = argon2id hash password "my-secret-passphrase" p_fast
        _         = assert ok (is a2 ok auto_res)
        auto_phc  = unwrap a2 phc auto_res
        _         = assert ok (argon2id verify "my-secret-passphrase" auto_phc)
        _         = assert eq (argon2id verify "other-passphrase" auto_phc) False
        parsed    = argon2id parse phc auto_phc
        _         = assert ok (is phc parsed ok parsed)
        _         = assert eq (is phc parsed ok (argon2id parse phc "invalid_phc")) False
        _         = assert eq (argon2id needs rehash auto_phc p_fast) False
        _         = assert ok (argon2id needs rehash auto_phc p_inter)
        _         = assert ok (argon2id needs rehash auto_phc (argon2 params 64 3 2 32))
        _         = assert ok (argon2id needs rehash auto_phc (argon2 params 64 2 4 32))
        _         = assert ok (argon2id needs rehash auto_phc (argon2 params 64 2 2 64))
        _         = assert ok (argon2id needs rehash "invalid_phc" p_fast)
        k_res     = argon2id derive key "encryption-passphrase" "1234567890abcdef" p_fast
        kh_res    = argon2id derive key hex "encryption-passphrase" "1234567890abcdef" p_fast
        k_bad     = argon2id derive key "encryption-passphrase" "short" p_fast
        kh_bad    = argon2id derive key hex "encryption-passphrase" "short" p_fast
        _         = assert ok (is key ok k_res)
        _         = assert ok (is a2 ok kh_res)
        _         = assert eq (is key ok k_bad) False
        _         = assert eq (is a2 ok kh_bad) False
        _         = assert eq (a2 list len (unwrap key bytes k_res)) 32
        _         = assert eq (str len (unwrap a2 phc kh_res)) 64
        ctx_res   = argon2id hash ctx "user-password" "1234567890abcdef" "app-pepper-key" "tenant:42" p_fast
        ctx_bad   = argon2id hash ctx "user-password" "short" "app-pepper-key" "tenant:42" p_fast
        _         = assert ok (is a2 ok ctx_res)
        _         = assert eq (is a2 ok ctx_bad) False
        ctx_phc   = unwrap a2 phc ctx_res
        _         = assert ok (argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:42")
        _         = assert eq (argon2id verify ctx "user-password" ctx_phc "wrong-pepper" "tenant:42") False
        _         = assert eq (argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:99") False

        -- RG-051: PHC string with empty tag segment must be rejected by parse & verify
        _         = assert eq (is phc parsed ok (argon2id parse phc "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$")) False
        assert eq (argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$") False
```

### 25.3.5. 5. adibidea: Autentifikazio-fluxu osoa eta segurtasun-politiken migrazio gardena `argon2id verify` eta `argon2id needs rehash` bidez

Adibide praktiko honetan `argon2id` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
import argon2id

fn :: verificar y evaluar politica (password : String) (phc_guardado : String) => (Bool, Bool)
      verificar y evaluar politica password phc_guardado =
        es_valida       = argon2id verify password phc_guardado
        requiere_mejora = argon2id needs rehash phc_guardado (argon2id params moderate)
        (es_valida, requiere_mejora)
```

---

## 25.4. Kaputaren azpian: nola dagoen eraikia `argon2id` Ridgun hutsean (`src/main/ridgun/lib/argon2id.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/argon2id.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 25.4.1. Barne-inplementazioa: Core Implementation Part 1

Ikusi nola `argon2id.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
type Argon2Params = m_cost: Int, t_cost: Int, lanes: Int, tag_len: Int, version: Int
type Argon2Phc    = params: Argon2Params, salt_b64: String, tag_b64: String
type Argon2Res    = Argon2Ok String | Argon2Err String
type Argon2KeyRes = Argon2KeyOk [Int] | Argon2KeyErr String
type Argon2PhcRes = Argon2PhcOk Argon2Phc | Argon2PhcErr String

type A2M16   = mb0: Tensor[U64 * 8 * 16], mb1: Tensor[U64 * 8 * 16], mb2: Tensor[U64 * 8 * 16], mb3: Tensor[U64 * 8 * 16], mb4: Tensor[U64 * 8 * 16], mb5: Tensor[U64 * 8 * 16], mb6: Tensor[U64 * 8 * 16], mb7: Tensor[U64 * 8 * 16], mb8: Tensor[U64 * 8 * 16], mb9: Tensor[U64 * 8 * 16], mb10: Tensor[U64 * 8 * 16], mb11: Tensor[U64 * 8 * 16], mb12: Tensor[U64 * 8 * 16], mb13: Tensor[U64 * 8 * 16], mb14: Tensor[U64 * 8 * 16], mb15: Tensor[U64 * 8 * 16]
type A2M256  = mr0: A2M16, mr1: A2M16, mr2: A2M16, mr3: A2M16, mr4: A2M16, mr5: A2M16, mr6: A2M16, mr7: A2M16, mr8: A2M16, mr9: A2M16, mr10: A2M16, mr11: A2M16, mr12: A2M16, mr13: A2M16, mr14: A2M16, mr15: A2M16
type A2M4096 = mp0: A2M256, mp1: A2M256, mp2: A2M256, mp3: A2M256, mp4: A2M256, mp5: A2M256, mp6: A2M256, mp7: A2M256, mp8: A2M256, mp9: A2M256, mp10: A2M256, mp11: A2M256, mp12: A2M256, mp13: A2M256, mp14: A2M256, mp15: A2M256
type A2Mem   = mt0: A2M4096, mt1: A2M4096, mt2: A2M4096, mt3: A2M4096, mt4: A2M4096, mt5: A2M4096, mt6: A2M4096, mt7: A2M4096, mt8: A2M4096, mt9: A2M4096, mt10: A2M4096, mt11: A2M4096, mt12: A2M4096, mt13: A2M4096, mt14: A2M4096, mt15: A2M4096
type A2Ctx   = r_pass: Int, s_slice: Int, l_lane: Int, p_lanes: Int, q_cols: Int, seg_len: Int, t_iters: Int

-- List, String & 32/64-bit Modular Arithmetic Helpers (Internal)

fn :: a2 list len [Int]    => Int
      a2 list len []       =  0
      a2 list len (_:rest) =  1 + (a2 list len rest)

fn :: a2 str list len [String] => Int
      a2 str list len []       =  0
      a2 str list len (_:rest) =  1 + (a2 str list len rest)

fn :: a2 nth int [Int]    Int => Int
      a2 nth int []       _   =  0
      a2 nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = a2 nth int rest (idx - 1)

fn :: a2 nth str [String] Int => String
      a2 nth str []       _   =  ""
      a2 nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = a2 nth str rest (idx - 1)
```

### 25.4.2. Barne-inplementazioa: Core Implementation Part 9

Ikusi nola `argon2id.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: a2 blamka g U64 U64 U64 U64 => U64 U64 U64 U64
      a2 blamka g a b c d =
        mut a = a2 f blamka a b
        mut d = (d xor a) rotr 32
        mut c = a2 f blamka c d
        mut b = (b xor c) rotr 24
        a = a2 f blamka a b
        d = (d xor a) rotr 16
        c = a2 f blamka c d
        b = (b xor c) rotr 63
        (a, b, c, d)

fn :: a2 blamka p16 Tensor[U64 * 16] => ()
      a2 blamka p16 v                =
        v_(0), v_(4), v_(8),  v_(12) = a2 blamka g v_(0) v_(4) v_(8)  v_(12)
        v_(1), v_(5), v_(9),  v_(13) = a2 blamka g v_(1) v_(5) v_(9)  v_(13)
        v_(2), v_(6), v_(10), v_(14) = a2 blamka g v_(2) v_(6) v_(10) v_(14)
        v_(3), v_(7), v_(11), v_(15) = a2 blamka g v_(3) v_(7) v_(11) v_(15)
        v_(0), v_(5), v_(10), v_(15) = a2 blamka g v_(0) v_(5) v_(10) v_(15)
        v_(1), v_(6), v_(11), v_(12) = a2 blamka g v_(1) v_(6) v_(11) v_(12)
        v_(2), v_(7), v_(8),  v_(13) = a2 blamka g v_(2) v_(7) v_(8)  v_(13)
        v_(3), v_(4), v_(9),  v_(14) = a2 blamka g v_(3) v_(4) v_(9)  v_(14)

fn :: a2 blamka col pair Tensor[U64 * 8 * 16] Int => Tensor[U64 * 8 * 16]
      a2 blamka col pair z j =
        c  = 2 * j
        c1 = c + 1
        z_(0, c),  z_(2, c),  z_(4, c),  z_(6, c)  = a2 blamka g z_(0, c)  z_(2, c)  z_(4, c)  z_(6, c)
        z_(0, c1), z_(2, c1), z_(4, c1), z_(6, c1) = a2 blamka g z_(0, c1) z_(2, c1) z_(4, c1) z_(6, c1)
        z_(1, c),  z_(3, c),  z_(5, c),  z_(7, c)  = a2 blamka g z_(1, c)  z_(3, c)  z_(5, c)  z_(7, c)
        z_(1, c1), z_(3, c1), z_(5, c1), z_(7, c1) = a2 blamka g z_(1, c1) z_(3, c1) z_(5, c1) z_(7, c1)
        z_(0, c),  z_(2, c1), z_(5, c),  z_(7, c1) = a2 blamka g z_(0, c)  z_(2, c1) z_(5, c)  z_(7, c1)
        z_(0, c1), z_(3, c),  z_(5, c1), z_(6, c)  = a2 blamka g z_(0, c1) z_(3, c)  z_(5, c1) z_(6, c)
        z_(1, c),  z_(3, c1), z_(4, c),  z_(6, c1) = a2 blamka g z_(1, c)  z_(3, c1) z_(4, c)  z_(6, c1)
        z_(1, c1), z_(2, c),  z_(4, c1), z_(7, c)  = a2 blamka g z_(1, c1) z_(2, c)  z_(4, c1) z_(7, c)
        z
```

### 25.4.3. Barne-inplementazioa: Core Implementation Part 18

Ikusi nola `argon2id.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: derive raw tag ctx [Int] [Int] String String Argon2Params => [Int]
      derive raw tag ctx pwd_raw salt_bytes secret ad params =
        sec_b = a2 str to bytes secret
        ad_b  = a2 str to bytes ad
        m     = m_cost params
        t     = t_cost params
        p     = lanes params
        tlen  = tag_len params
        h0_in = (a2 u32 to le4 p) :: (a2 u32 to le4 tlen) :: (a2 u32 to le4 m) :: (a2 u32 to le4 t) :: (a2 u32 to le4 19) :: (a2 u32 to le4 2) :: (a2 u32 to le4 (a2 list len pwd_raw)) :: pwd_raw :: (a2 u32 to le4 (a2 list len salt_bytes)) :: salt_bytes :: (a2 u32 to le4 (a2 list len sec_b)) :: sec_b :: (a2 u32 to le4 (a2 list len ad_b)) :: ad_b
        h0    = a2 blake2b h0_in 64
        sl    = m / (4 * p)
        q     = sl * 4
        mem0  = a2 init all lanes h0 0 p q
        ctx   = A2Ctx 0 0 0 p q sl t
        memf  = a2 run passes mem0 ctx 0
        c0    = a2 nth blk memf (q - 1)
        c_fin = a2 bitxor final lanes memf 1 p q c0
        a2 blake2b long (a2 blk8 to bytes c_fin) tlen

fn :: derive raw tag [Int] [Int] Argon2Params => [Int]
      derive raw tag pwd_raw salt_bytes params = derive raw tag ctx pwd_raw salt_bytes "" "" params

-- Unpadded Base64 Encoding & Decoding (PHC Specification)

fn :: b64 alphabet => String
      b64 alphabet =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: b64 char Int => String
      b64 char idx =  str slice (b64 alphabet) (idx % 64) ((idx % 64) + 1)

fn :: b64 encode nopad [Int]           => String
      b64 encode nopad []              =  ""
      b64 encode nopad (b0:[])         =
        c0 = b0 / 4
        c1 = (b0 % 4) * 16
        (b64 char c0) + (b64 char c1)
      b64 encode nopad (b0:b1:[])      =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = (b1 % 16) * 4
        (b64 char c0) + (b64 char c1) + (b64 char c2)
      b64 encode nopad (b0:b1:b2:rest) =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = ((b1 % 16) * 4) + (b2 / 64)
        c3 = b2 % 64
        (b64 char c0) + (b64 char c1) + (b64 char c2) + (b64 char c3) + (b64 encode nopad rest)
```

### 25.4.4. Barne-inplementazioa: Core Implementation Part 26

Ikusi nola `argon2id.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: argon2id needs rehash String Argon2Params => Bool
      argon2id needs rehash phc    target       =  check rehash parsed (argon2id parse phc phc) target

fn :: verify parsed ctx Argon2PhcRes String String String => Bool
      verify parsed ctx (Argon2PhcErr _) _ _ _ = False
      verify parsed ctx (Argon2PhcOk parsed) pwd secret ad =
        salt_bytes = b64 decode nopad (salt_b64 parsed)
        tag_bytes  = b64 decode nopad (tag_b64 parsed)
        computed   = derive raw tag ctx (a2 str to bytes pwd) salt_bytes secret ad (params parsed)
        constant time bytes eq computed tag_bytes

fn :: argon2id verify ctx String String String String => Bool
      argon2id verify ctx pwd phc secret ad = verify parsed ctx (argon2id parse phc phc) pwd secret ad

fn :: argon2id verify String String => Bool
      argon2id verify pwd    phc    =
        | not (str starts with phc "$argon2id$") = False
        | otherwise                              = argon2id verify ctx pwd phc "" ""

fn :: unwrap phc res Argon2Res      => String
      unwrap phc res (Argon2Ok phc) =  phc
      unwrap phc res (Argon2Err _)  =  ""

fn :: argon2id hash String String Int Int Int => String
      argon2id hash pwd salt m_kib t_iters p_lanes =
        unwrap phc res (argon2id hash params pwd salt (Argon2Params m_kib t_iters p_lanes 32 19))

fn :: argon2id hash phc String String Int Int Int => String
      argon2id hash phc pwd salt m_kib t_iters p_lanes =
        argon2id hash pwd salt m_kib t_iters p_lanes
```

---

## 25.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `argon2id`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Bat-etortze zehatza bytez byte RFC 9106 §5.3 eta OpenSSL 3.5 bektore ofizialekin, `Tensor[U64 * 8 * 16]` gainean C lerro bakar bat ere gabe lan eginez.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/argon2id.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test argon2id.rg` suite automatizatuaren bidez.

### `argon2id`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import argon2id` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `argon2id`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `argon2id`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `argon2id` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**26. kapituluan** **`jwt`** lib-a sakonki esploratuko dugu (`jwt` lib-a — RFC 7519 JSON Web Tokenak (`HS256`) eta ChaCha20-Poly1305 Token Zifratuak).
