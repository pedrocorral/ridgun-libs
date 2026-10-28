# Capítulo 25: A lib `argon2id` — RFC 9106 Argon2id sobre `Tensor[U64 * 8 * 16]`, Blake2b e Presets OWASP

## 25.1. Por que existe a lib `argon2id`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `argon2id` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `argon2id`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: gardar contrasinais cun simple SHA-256 permite que unha GPU moderna probe miles de millóns de combinacións por segundo, pero enlazar bibliotecas C externas para ter Argon2id adoita traer dores de cabeza de compilación e memoria.

A lib **`argon2id`** implementa **RFC 9106 Argon2id** e **RFC 7693 Blake2b-512** ao 100 % en Ridgun puro operando directamente sobre bloques nativos `Tensor[U64 * 8 * 16]` (1 024 bytes por bloque en memoria contigua RMM2), con xeración de cadeas **PHC** (`$argon2id$v=19$m=...,t=...,p=...$`), perfís **OWASP** (`owaspfirst`, `owaspsecond`), soporte de *pepper* (`argon2id hash ctx`), derivación de chaves (`argon2id derive key`) e detección de actualización de parámetros (`argon2id needs rehash`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`CRYPTO`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`argon2id`** (`src/main/ridgun/lib/argon2id.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import argon2id` (ou `import argon2id as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: argon2id` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `argon2id` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 25.2. Artefactos nativos, importación e catálogo completo da API de `argon2id`

En `ridgun-libs`, **`argon2id`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/argon2id.rg` (dominio `CRYPTO`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/argon2id.rglib` | Distribución e importación directa con `import argon2id` |
| **Ficheiro compilado** | `target/argon2id.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libargon2id.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: argon2id`: abonda con escribir `import argon2id` (ou `import argon2id as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 25.2.1. Resumo de familias funcionais de `argon2id`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `argon2id hash / argon2id verify` | Hashing PHC RFC 9106 de 6 argumentos (`pwd, salt, m_kib, t, p, tag_len`) e verificación en tempo constante |
| `argon2id hash with preset / argon2id params preset` | Perfís con nome: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | Hashing RFC 9106 con segredo `pepper` ($K$) e datos asociados ($X$) |
| `argon2id derive key / argon2id needs rehash` | Derivación de chave binaria crúa e detección de necesidade de rehash en cadeas PHC |
| `blake2b / blake2b hex` | Resumo criptográfico de propósito xeral RFC 7693 Blake2b (`1..64` bytes) |

### 25.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/argon2id.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/argon2id.rg` (`10` tipos, `0` operadores e `134` funcións):

**Tipos alxébricos e rexistros (`type`) de `argon2id`:**

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

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 25.3. Explorando `argon2id` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `argon2id` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test argon2id.rg`.

### 25.3.1. Exemplo 1: Fluxo principal en estilo tabular con `argon2id`

Observa como en Ridgun os signos `=` e os pasos de transformación con `argon2id` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import argon2id

fn :: proteger clave usuario String => String Bool Bool
      proteger clave usuario clave =
        argon2id hash clave "sal-unica-16byte" 32 2 1 -> phc
        argon2id verify clave phc -> valido
        argon2id needs rehash phc (owasp default params) -> rehash
        (phc, valido, rehash)
```

### 25.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `argon2id` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import argon2id

fn :: derivar clave maestra String String => Argon2KeyRes
      derivar clave maestra frase sal =
        -- Deriva 32 bytes listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

### 25.3.3. Exemplo 3: Perfís de seguridade OWASP (`Interactive`, `Moderate`, `Sensitive`), xeración de cadeas PHC `$argon2id$v=19$...` e verificación en tempo constante

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `argon2id` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test argon2id phc hashing and verification => ()
      test argon2id phc hashing and verification =
        -- LIB-1: OpenSSL 3.5 / libsodium reference vectors
        v1 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 8 1 1 32))
        v2 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 64 2 1 32))
        v3 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 256 2 1 32))
        assert str eq v1 "b7940bccc95f48f2cc7b36f55ff851c356ca4d3a6bc8cd4986a0692f2aac78ec" "LIB-1 vector m=8,t=1,p=1"
        assert str eq v2 "e6374c2335a815bcd23a5ea4df06a2f6e5377fc2c3f879865d0828d6e84740f2" "LIB-1 vector m=64,t=2,p=1"
        assert str eq v3 "8f65ef99a71b1e98450f2c80d78604af3644276f965db52045bbed139b03b5fd" "LIB-1 vector m=256,t=2,p=1"

        -- LIB-1: RFC 9106 §5.3 official test vector (pwd=32*0x01, salt=16*0x02, secret=8*0x03, ad=12*0x04, m=32, t=3, p=4, tag=32)
        pwd32  = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        salt16 = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        sec8   = a2 bytes to str [3, 3, 3, 3, 3, 3, 3, 3]
        ad12   = a2 bytes to str [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]
        rfc_h  = bytes to hex (derive raw tag ctx pwd32 salt16 sec8 ad12 (argon2 params 32 3 4 32))
        assert str eq rfc_h "0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659" "RFC 9106 §5.3 official vector"

        params   = argon2 params 32 2 2 16
        res1     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res2     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res_diff = argon2id hash params "correct-horse-battery-staple" "othersalt999" params
        assert ok (is a2 ok res1)
        assert ok (is a2 ok res2)
        assert ok (is a2 ok res_diff)
        phc1     = unwrap a2 phc res1
        phc2     = unwrap a2 phc res2
        phc_diff = unwrap a2 phc res_diff
        assert eq phc1 phc2
        assert eq (phc1 == phc_diff) False
        assert ok (str starts with phc1 "$argon2id$v=19$m=32,t=2,p=2$")
        bad_t    = argon2id hash params "password" "somesalt1234" (argon2 params 32 0 2 16)
        bad_p    = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 0 16)
        bad_m    = argon2id hash params "password" "somesalt1234" (argon2 params 8 2 2 16)
        bad_tag  = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 2 2)
        bad_salt = argon2id hash params "password" "short" params
        assert eq (is a2 ok bad_t) False
        assert eq (is a2 ok bad_p) False
        assert eq (is a2 ok bad_m) False
        assert eq (is a2 ok bad_tag) False
        assert eq (is a2 ok bad_salt) False

        -- LIB-7: Fixed (password, phc) argument order; never swaps if password starts with "$argon2id$"
        assert ok (argon2id verify "correct-horse-battery-staple" phc1)
        assert eq (argon2id verify phc1 "correct-horse-battery-staple") False
        assert eq (argon2id verify "wrong-password" phc1) False
        tricky_pwd = "$argon2id$v=19$m=32,t=2,p=2$not-a-hash-just-a-password"
        tricky_phc = argon2id hash tricky_pwd "0123456789abcdef" 32 2 1
        assert ok (argon2id verify tricky_pwd tricky_phc)
        assert eq (argon2id verify tricky_phc tricky_pwd) False
        assert eq (argon2id verify "correct-horse-battery-staple" "$argon2i$v=19$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA") False
        assert eq (argon2id verify "correct-horse-battery-staple" "$argon2id$v=18$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA") False
        assert eq (argon2id verify "correct-horse-battery-staple" "malformed_phc_string") False
        assert ok (constant time eq "abc123xyz" "abc123xyz")
        assert eq (constant time eq "abc123xyz" "abc123xyw") False
```

### 25.3.4. Exemplo 4: Derivación de claves binarias (`argon2id derive key`), xeración de sal CSPRNG (`argon2id gen salt`) e detección de actualización de parámetros (`argon2id needs rehash`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `argon2id` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test argon2id key derivation salting and rehash => ()
      test argon2id key derivation salting and rehash =
        -- LIB-3: Non-deterministic CSPRNG raw byte salt generation
        salt16    = argon2id generate salt 16
        salt16_b  = argon2id generate salt 16
        salt_min  = argon2id generate salt 2
        assert eq (str len salt16) 16
        assert eq (str len salt16_b) 16
        assert eq (str len salt_min) 16
        assert eq (salt16 == salt16_b) False

        -- LIB-4: Presets at or above OWASP (19456 KiB) and RFC 9106 §4 (65536 KiB)
        p_def     = default argon2 params
        p_inter   = argon2 interactive params
        p_mod     = argon2 moderate params
        p_sens    = argon2 sensitive params
        assert eq (m_cost p_def) 19456
        assert eq (t_cost p_def) 2
        assert eq (lanes p_def) 1
        assert eq (tag_len p_def) 32
        assert eq (m_cost p_inter) 19456
        assert eq (m_cost p_mod) 47104
        assert eq (m_cost p_sens) 65536
        assert eq (t_cost p_sens) 3
        assert eq (lanes p_sens) 4

        p_fast    = argon2 params 64 2 2 32
        auto_res  = argon2id hash password "my-secret-passphrase" p_fast
        assert ok (is a2 ok auto_res)
        auto_phc  = unwrap a2 phc auto_res
        assert ok (argon2id verify "my-secret-passphrase" auto_phc)
        assert eq (argon2id verify "other-passphrase" auto_phc) False
        parsed    = argon2id parse phc auto_phc
        assert ok (is phc parsed ok parsed)
        assert eq (is phc parsed ok (argon2id parse phc "invalid_phc")) False
        assert eq (argon2id needs rehash auto_phc p_fast) False
        assert ok (argon2id needs rehash auto_phc p_inter)
        assert ok (argon2id needs rehash auto_phc (argon2 params 64 3 2 32))
        assert ok (argon2id needs rehash auto_phc (argon2 params 64 2 4 32))
        assert ok (argon2id needs rehash auto_phc (argon2 params 64 2 2 64))
        assert ok (argon2id needs rehash "invalid_phc" p_fast)
        k_res     = argon2id derive key "encryption-passphrase" "1234567890abcdef" p_fast
        kh_res    = argon2id derive key hex "encryption-passphrase" "1234567890abcdef" p_fast
        k_bad     = argon2id derive key "encryption-passphrase" "short" p_fast
        kh_bad    = argon2id derive key hex "encryption-passphrase" "short" p_fast
        assert ok (is key ok k_res)
        assert ok (is a2 ok kh_res)
        assert eq (is key ok k_bad) False
        assert eq (is a2 ok kh_bad) False
        assert eq (a2 list len (unwrap key bytes k_res)) 32
        assert eq (str len (unwrap a2 phc kh_res)) 64
        ctx_res   = argon2id hash ctx "user-password" "1234567890abcdef" "app-pepper-key" "tenant:42" p_fast
        ctx_bad   = argon2id hash ctx "user-password" "short" "app-pepper-key" "tenant:42" p_fast
        assert ok (is a2 ok ctx_res)
        assert eq (is a2 ok ctx_bad) False
        ctx_phc   = unwrap a2 phc ctx_res
        assert ok (argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:42")
        assert eq (argon2id verify ctx "user-password" ctx_phc "wrong-pepper" "tenant:42") False
        assert eq (argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:99") False

        -- RG-051: PHC string with empty tag segment must be rejected by parse & verify
        assert eq (is phc parsed ok (argon2id parse phc "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$")) False
        assert eq (argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$") False
```

### 25.3.5. Exemplo 5: Fluxo completo de autenticación e migración transparente de políticas de seguridade con `argon2id verify` e `argon2id needs rehash`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `argon2id` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
import argon2id

fn :: verificar y evaluar politica (password : String) (phc_guardado : String) => (Bool, Bool)
      verificar y evaluar politica password phc_guardado =
        es_valida       = argon2id verify password phc_guardado
        requiere_mejora = argon2id needs rehash phc_guardado (argon2id params moderate)
        (es_valida, requiere_mejora)
```

---

## 25.4. Baixo o capó: como está construída `argon2id` en Ridgun puro (`src/main/ridgun/lib/argon2id.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/argon2id.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 25.4.1. Implementación interna: Core Implementation Part 1

Fíxate en como `argon2id.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: argon2id

type Argon2Params = m_cost: Int, t_cost: Int, lanes: Int, tag_len: Int, version: Int
type Argon2Phc    = params: Argon2Params, salt_b64: String, tag_b64: String
type Argon2Res    = Argon2Ok String | Argon2Err String
type Argon2KeyRes = Argon2KeyOk [Int] | Argon2KeyErr String
type Argon2PhcRes = Argon2PhcOk Argon2Phc | Argon2PhcErr String

type A2M16   = mb0: Tensor[U64 * 256], mb1: Tensor[U64 * 256], mb2: Tensor[U64 * 256], mb3: Tensor[U64 * 256], mb4: Tensor[U64 * 256], mb5: Tensor[U64 * 256], mb6: Tensor[U64 * 256], mb7: Tensor[U64 * 256], mb8: Tensor[U64 * 256], mb9: Tensor[U64 * 256], mb10: Tensor[U64 * 256], mb11: Tensor[U64 * 256], mb12: Tensor[U64 * 256], mb13: Tensor[U64 * 256], mb14: Tensor[U64 * 256], mb15: Tensor[U64 * 256]
type A2M256  = mr0: A2M16, mr1: A2M16, mr2: A2M16, mr3: A2M16, mr4: A2M16, mr5: A2M16, mr6: A2M16, mr7: A2M16, mr8: A2M16, mr9: A2M16, mr10: A2M16, mr11: A2M16, mr12: A2M16, mr13: A2M16, mr14: A2M16, mr15: A2M16
type A2M4096 = mp0: A2M256, mp1: A2M256, mp2: A2M256, mp3: A2M256, mp4: A2M256, mp5: A2M256, mp6: A2M256, mp7: A2M256, mp8: A2M256, mp9: A2M256, mp10: A2M256, mp11: A2M256, mp12: A2M256, mp13: A2M256, mp14: A2M256, mp15: A2M256
type A2Mem   = mt0: A2M4096, mt1: A2M4096, mt2: A2M4096, mt3: A2M4096, mt4: A2M4096, mt5: A2M4096, mt6: A2M4096, mt7: A2M4096, mt8: A2M4096, mt9: A2M4096, mt10: A2M4096, mt11: A2M4096, mt12: A2M4096, mt13: A2M4096, mt14: A2M4096, mt15: A2M4096
type A2Ctx   = r_pass: Int, s_slice: Int, l_lane: Int, p_lanes: Int, q_cols: Int, seg_len: Int, t_iters: Int

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

fn :: a2 take ints [Int]    Int => [Int]
      a2 take ints []       _   =  []
      a2 take ints (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (a2 take ints rest (n - 1))

fn :: a2 drop ints [Int]    Int => [Int]
      a2 drop ints []       _   =  []
      a2 drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = a2 drop ints rest (n - 1)

fn :: a2 pad zeroes Int => [Int]
      a2 pad zeroes n   =
        | n <= 0    = []
        | otherwise = [0] :: (a2 pad zeroes (n - 1))

fn :: a2 raw byte ub Int => String
      a2 raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | ub == 0 = str slice (sha256 raw "00679") 0 1
        | otherwise =
          idx = (ub - 128) * 5
          lut = "0056400101002080010000179000010024100109003430040100361007870009100353001870030400471000870020200071002360012501171004140236900275001810016001398004440080400017005250027000314001400024700004006350015700183005940027600207007720028400601003400038000839006850084900617003060113500277000320006900483000580019200151008700008500193000100057000070002880002600326006460038800018009190028900103006000043900073011700038900628007210077300074004740006000041001410019900066003680001900383001730005700558000670024500065002030031900000008250001100128001360034900030003750039600228002380008400618005900031800062001770087900076002570009600034002200001600161"
          str slice (sha256 raw (str slice lut idx (idx + 5))) 0 1

fn :: a2 raw byte Int => String
      a2 raw byte b   =  a2 raw byte ub (((b % 256) + 256) % 256)

fn :: a2 lb append2 [Int] [Int] Int => [Int] [Int] [Int] Int
      a2 lb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: a2 lb append1 [Int] [Int] [Int] Int => [Int] [Int] [Int] Int
      a2 lb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = a2 lb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: a2 lb append Int [Int] [Int] [Int] Int => [Int] [Int] [Int] Int
      a2 lb append item l0 l1 l2 cnt =
        a2 lb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: a2 lb finish [Int] [Int] [Int] => [Int]
      a2 lb finish l0 l1 l2 =  l2 :: (l1 :: l0)

fn :: a2 str to bytes loop String Int Int [Int] [Int] [Int] Int => [Int]
      a2 str to bytes loop s idx len l0 l1 l2 cnt =
        | idx >= len = a2 lb finish l0 l1 l2
        | otherwise  =
          n0, n1, n2, ncnt = a2 lb append ((((str char at s idx) % 256) + 256) % 256) l0 l1 l2 cnt
          a2 str to bytes loop s (idx + 1) len n0 n1 n2 ncnt

fn :: a2 str to bytes String => [Int]
      a2 str to bytes s      =  a2 str to bytes loop s 0 (str len s) [] [] [] 0

fn :: a2 bytes to str loop [Int] String => String
      a2 bytes to str loop []       acc = acc
      a2 bytes to str loop (b:rest) acc = a2 bytes to str loop rest (acc + (a2 raw byte b))

fn :: a2 bytes to str [Int] => String
      a2 bytes to str bs    =  a2 bytes to str loop bs ""

fn :: hex digits => String
      hex digits =  "0123456789abcdef"

fn :: byte to hex Int => String
      byte to hex b   =
        ub = b % 256
        hi = (ub / 16) % 16
        lo = ub % 16
        (str slice (hex digits) hi (hi + 1)) + (str slice (hex digits) lo (lo + 1))

fn :: bytes to hex [Int]    => String
      bytes to hex []       =  ""
      bytes to hex (b:rest) =  (byte to hex b) + (bytes to hex rest)

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

fn :: a2 u32 to le4 Int => [Int]
      a2 u32 to le4 w   =
        uw = u32 norm w
        [uw and 255, (uw shr 8) and 255, (uw shr 16) and 255, (uw shr 24) and 255]

fn :: a2 bytes to u32 le [Int] Int => Int
      a2 bytes to u32 le bs off =
        (a2 nth int bs off) or ((a2 nth int bs (off + 1)) shl 8) or ((a2 nth int bs (off + 2)) shl 16) or ((a2 nth int bs (off + 3)) shl 24)

fn :: a2 zero w16 => Tensor[U64 * 32]
      a2 zero w16 =  Tensor[U64 * 32]

fn :: a2 zero blk8 => Tensor[U64 * 256]
      a2 zero blk8 =  Tensor[U64 * 256]

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
        _  = a2 w16 set iv 0 (a2 u64 lh 4089235720 1779033703)
        _  = a2 w16 set iv 1 (a2 u64 lh 2227873595 3144134277)
        _  = a2 w16 set iv 2 (a2 u64 lh 4271175723 1013904242)
        _  = a2 w16 set iv 3 (a2 u64 lh 1595750129 2773480762)
        _  = a2 w16 set iv 4 (a2 u64 lh 2917565137 1359893119)
        _  = a2 w16 set iv 5 (a2 u64 lh 725511199  2600822924)
        _  = a2 w16 set iv 6 (a2 u64 lh 4215389547 528734635)
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

fn :: a2 b2b sigma Int => [Int]
      a2 b2b sigma r   =
        | (r % 10) == 0 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        | (r % 10) == 1 = [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3]
        | (r % 10) == 2 = [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4]
        | (r % 10) == 3 = [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8]
        | (r % 10) == 4 = [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13]
        | (r % 10) == 5 = [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9]
        | (r % 10) == 6 = [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11]
        | (r % 10) == 7 = [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10]
        | (r % 10) == 8 = [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5]
        | otherwise     = [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0]

fn :: a2 b2b round Tensor[U64 * 32] Tensor[U64 * 32] Int => Tensor[U64 * 32]
      a2 b2b round v m r =
        s       = a2 b2b sigma r
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
        v0, v4, v8,  v12 = a2 b2b g4 v0 v4 v8  v12 (a2 w16 get m (a2 nth int s 0))  (a2 w16 get m (a2 nth int s 1))
        v1, v5, v9,  v13 = a2 b2b g4 v1 v5 v9  v13 (a2 w16 get m (a2 nth int s 2))  (a2 w16 get m (a2 nth int s 3))
        v2, v6, v10, v14 = a2 b2b g4 v2 v6 v10 v14 (a2 w16 get m (a2 nth int s 4))  (a2 w16 get m (a2 nth int s 5))
        v3, v7, v11, v15 = a2 b2b g4 v3 v7 v11 v15 (a2 w16 get m (a2 nth int s 6))  (a2 w16 get m (a2 nth int s 7))
        v0, v5, v10, v15 = a2 b2b g4 v0 v5 v10 v15 (a2 w16 get m (a2 nth int s 8))  (a2 w16 get m (a2 nth int s 9))
        v1, v6, v11, v12 = a2 b2b g4 v1 v6 v11 v12 (a2 w16 get m (a2 nth int s 10)) (a2 w16 get m (a2 nth int s 11))
        v2, v7, v8,  v13 = a2 b2b g4 v2 v7 v8  v13 (a2 w16 get m (a2 nth int s 12)) (a2 w16 get m (a2 nth int s 13))
        v3, v4, v9,  v14 = a2 b2b g4 v3 v4 v9  v14 (a2 w16 get m (a2 nth int s 14)) (a2 w16 get m (a2 nth int s 15))
        _ = a2 w16 set v 0  v0
        _ = a2 w16 set v 1  v1
        _ = a2 w16 set v 2  v2
        _ = a2 w16 set v 3  v3
        _ = a2 w16 set v 4  v4
        _ = a2 w16 set v 5  v5
        _ = a2 w16 set v 6  v6
        _ = a2 w16 set v 7  v7
        _ = a2 w16 set v 8  v8
        _ = a2 w16 set v 9  v9
        _ = a2 w16 set v 10 v10
        _ = a2 w16 set v 11 v11
        _ = a2 w16 set v 12 v12
        _ = a2 w16 set v 13 v13
        _ = a2 w16 set v 14 v14
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
        _   = a2 w16 set v0 0  (a2 w16 get h 0)
        _   = a2 w16 set v0 1  (a2 w16 get h 1)
        _   = a2 w16 set v0 2  (a2 w16 get h 2)
        _   = a2 w16 set v0 3  (a2 w16 get h 3)
        _   = a2 w16 set v0 4  (a2 w16 get h 4)
        _   = a2 w16 set v0 5  (a2 w16 get h 5)
        _   = a2 w16 set v0 6  (a2 w16 get h 6)
        _   = a2 w16 set v0 7  (a2 w16 get h 7)
        _   = a2 w16 set v0 8  (a2 w16 get iv 0)
        _   = a2 w16 set v0 9  (a2 w16 get iv 1)
        _   = a2 w16 set v0 10 (a2 w16 get iv 2)
        _   = a2 w16 set v0 11 (a2 w16 get iv 3)
        _   = a2 w16 set v0 12 ((a2 w16 get iv 4) xor (t and 0xFFFFFFFF))
        _   = a2 w16 set v0 13 (a2 w16 get iv 5)
        _   = a2 w16 set v0 14 v14
        _   = a2 w16 set v0 15 (a2 w16 get iv 7)
        vf  = a2 b2b rounds v0 m 0
        out = Tensor[U64 * 32]
        _   = a2 w16 set out 0 (((a2 w16 get h 0) xor (a2 w16 get vf 0)) xor (a2 w16 get vf 8))
        _   = a2 w16 set out 1 (((a2 w16 get h 1) xor (a2 w16 get vf 1)) xor (a2 w16 get vf 9))
        _   = a2 w16 set out 2 (((a2 w16 get h 2) xor (a2 w16 get vf 2)) xor (a2 w16 get vf 10))
        _   = a2 w16 set out 3 (((a2 w16 get h 3) xor (a2 w16 get vf 3)) xor (a2 w16 get vf 11))
        _   = a2 w16 set out 4 (((a2 w16 get h 4) xor (a2 w16 get vf 4)) xor (a2 w16 get vf 12))
        _   = a2 w16 set out 5 (((a2 w16 get h 5) xor (a2 w16 get vf 5)) xor (a2 w16 get vf 13))
        _   = a2 w16 set out 6 (((a2 w16 get h 6) xor (a2 w16 get vf 6)) xor (a2 w16 get vf 14))
        a2 w16 set out 7 (((a2 w16 get h 7) xor (a2 w16 get vf 7)) xor (a2 w16 get vf 15))

fn :: a2 bytes to u64 [Int] Int => U64
      a2 bytes to u64 bs off =
        a2 u64 lh (a2 bytes to u32 le bs off) (a2 bytes to u32 le bs (off + 4))

fn :: a2 bytes to w16 [Int] Int => Tensor[U64 * 32]
      a2 bytes to w16 bs off =
        w = Tensor[U64 * 32]
        _ = a2 w16 set w 0  (a2 bytes to u64 bs off)
        _ = a2 w16 set w 1  (a2 bytes to u64 bs (off + 8))
        _ = a2 w16 set w 2  (a2 bytes to u64 bs (off + 16))
        _ = a2 w16 set w 3  (a2 bytes to u64 bs (off + 24))
        _ = a2 w16 set w 4  (a2 bytes to u64 bs (off + 32))
        _ = a2 w16 set w 5  (a2 bytes to u64 bs (off + 40))
        _ = a2 w16 set w 6  (a2 bytes to u64 bs (off + 48))
        _ = a2 w16 set w 7  (a2 bytes to u64 bs (off + 56))
        _ = a2 w16 set w 8  (a2 bytes to u64 bs (off + 64))
        _ = a2 w16 set w 9  (a2 bytes to u64 bs (off + 72))
        _ = a2 w16 set w 10 (a2 bytes to u64 bs (off + 80))
        _ = a2 w16 set w 11 (a2 bytes to u64 bs (off + 88))
        _ = a2 w16 set w 12 (a2 bytes to u64 bs (off + 96))
        _ = a2 w16 set w 13 (a2 bytes to u64 bs (off + 104))
        _ = a2 w16 set w 14 (a2 bytes to u64 bs (off + 112))
        a2 w16 set w 15 (a2 bytes to u64 bs (off + 120))

fn :: a2 u64 to le8 U64 => [Int]
      a2 u64 to le8 x   =
        (a2 u32 to le4 (x and 0xFFFFFFFF)) :: (a2 u32 to le4 ((x shr 32) and 0xFFFFFFFF))

fn :: a2 h8 to bytes Tensor[U64 * 32] => [Int]
      a2 h8 to bytes h                =
        (a2 u64 to le8 (a2 w16 get h 0)) :: (a2 u64 to le8 (a2 w16 get h 1)) :: (a2 u64 to le8 (a2 w16 get h 2)) :: (a2 u64 to le8 (a2 w16 get h 3)) :: (a2 u64 to le8 (a2 w16 get h 4)) :: (a2 u64 to le8 (a2 w16 get h 5)) :: (a2 u64 to le8 (a2 w16 get h 6)) :: (a2 u64 to le8 (a2 w16 get h 7))

fn :: a2 b2b loop Tensor[U64 * 32] [Int] Int => Tensor[U64 * 32]
      a2 b2b loop h rem t =
        | (a2 list len rem) <= 128 =
          rlen   = a2 list len rem
          padded = rem :: (a2 pad zeroes (128 - rlen))
          a2 b2b compress h (a2 bytes to w16 padded 0) (t + rlen) True
        | otherwise =
          blk  = a2 take ints rem 128
          rest = a2 drop ints rem 128
          h1   = a2 b2b compress h (a2 bytes to w16 blk 0) (t + 128) False
          a2 b2b loop h1 rest (t + 128)

fn :: a2 blake2b [Int] Int    => [Int]
      a2 blake2b msg   outlen =
        h_in = a2 b2b iv w16
        _    = a2 w16 set h_in 0 ((a2 w16 get h_in 0) xor ((16842752 + outlen) and 0xFFFFFFFF))
        h_fi = a2 b2b loop h_in msg 0
        a2 take ints (a2 h8 to bytes h_fi) outlen

fn :: a2 b2b long loop [Int] Int Int Int => [Int]
      a2 b2b long loop v idx r outlen =
        | idx > r =
          rem = outlen - (32 * r)
          a2 blake2b v rem
        | otherwise =
          v_next = a2 blake2b v 64
          (a2 take ints v_next 32) :: (a2 b2b long loop v_next (idx + 1) r outlen)

fn :: a2 blake2b long [Int] Int    => [Int]
      a2 blake2b long data  outlen =
        | outlen <= 64 = a2 blake2b ((a2 u32 to le4 outlen) :: data) outlen
        | otherwise =
          r  = ((outlen + 31) / 32) - 2
          v1 = a2 blake2b ((a2 u32 to le4 outlen) :: data) 64
          (a2 take ints v1 32) :: (a2 b2b long loop v1 2 r outlen)

fn :: a2 blamka g idx Tensor[U64 * 256] Int Int Int Int => Int
      a2 blamka g idx z ia ib ic id =
        mut al = z_(ia)
        mut ah = z_(ia + 1)
        mut bl = z_(ib)
        mut bh = z_(ib + 1)
        mut cl = z_(ic)
        mut ch = z_(ic + 1)
        mut dl = z_(id)
        mut dh = z_(id + 1)
        mut t  = (al and 0x3FFFFFFF) * bl
        mut u  = ((al shr 30) * bl) + (t shr 30)
        t      = al + bl + ((t and 0x3FFFFFFF) shl 1) + ((u and 1) shl 31)
        al     = t and 0xFFFFFFFF
        ah     = (ah + bh + (u shr 1) + (t shr 32)) and 0xFFFFFFFF
        t      = dl xor al
        dl     = dh xor ah
        dh     = t
        t      = (cl and 0x3FFFFFFF) * dl
        u      = ((cl shr 30) * dl) + (t shr 30)
        t      = cl + dl + ((t and 0x3FFFFFFF) shl 1) + ((u and 1) shl 31)
        cl     = t and 0xFFFFFFFF
        ch     = (ch + dh + (u shr 1) + (t shr 32)) and 0xFFFFFFFF
        t      = bl xor cl
        u      = bh xor ch
        bl     = ((t shr 24) or (u shl 8)) and 0xFFFFFFFF
        bh     = ((u shr 24) or (t shl 8)) and 0xFFFFFFFF
        t      = (al and 0x3FFFFFFF) * bl
        u      = ((al shr 30) * bl) + (t shr 30)
        t      = al + bl + ((t and 0x3FFFFFFF) shl 1) + ((u and 1) shl 31)
        al     = t and 0xFFFFFFFF
        ah     = (ah + bh + (u shr 1) + (t shr 32)) and 0xFFFFFFFF
        t      = dl xor al
        u      = dh xor ah
        dl     = ((t shr 16) or (u shl 16)) and 0xFFFFFFFF
        dh     = ((u shr 16) or (t shl 16)) and 0xFFFFFFFF
        t      = (cl and 0x3FFFFFFF) * dl
        u      = ((cl shr 30) * dl) + (t shr 30)
        t      = cl + dl + ((t and 0x3FFFFFFF) shl 1) + ((u and 1) shl 31)
        cl     = t and 0xFFFFFFFF
        ch     = (ch + dh + (u shr 1) + (t shr 32)) and 0xFFFFFFFF
        t      = bl xor cl
        u      = bh xor ch
        bl     = ((t shl 1) or (u shr 31)) and 0xFFFFFFFF
        bh     = ((u shl 1) or (t shr 31)) and 0xFFFFFFFF
        z_(ia)     = al
        z_(ia + 1) = ah
        z_(ib)     = bl
        z_(ib + 1) = bh
        z_(ic)     = cl
        z_(ic + 1) = ch
        z_(id)     = dl
        z_(id + 1) = dh
        0

fn :: a2 blamka rows loop Tensor[U64 * 256] Int => Tensor[U64 * 256]
      a2 blamka rows loop z b =
        | b >= 256  = z
        | otherwise =
          mut k = a2 blamka g idx z b       (b + 8)  (b + 16) (b + 24)
          k     = a2 blamka g idx z (b + 2) (b + 10) (b + 18) (b + 26)
          k     = a2 blamka g idx z (b + 4) (b + 12) (b + 20) (b + 28)
          k     = a2 blamka g idx z (b + 6) (b + 14) (b + 22) (b + 30)
          k     = a2 blamka g idx z b       (b + 10) (b + 20) (b + 30)
          k     = a2 blamka g idx z (b + 2) (b + 12) (b + 22) (b + 24)
          k     = a2 blamka g idx z (b + 4) (b + 14) (b + 16) (b + 26)
          k     = a2 blamka g idx z (b + 6) (b + 8)  (b + 18) (b + 28)
          a2 blamka rows loop z (b + 32 + k)

fn :: a2 blamka cols loop Tensor[U64 * 256] Int => Tensor[U64 * 256]
      a2 blamka cols loop z c =
        | c >= 32   = z
        | otherwise =
          mut k = a2 blamka g idx z c        (c + 64) (c + 128) (c + 192)
          k     = a2 blamka g idx z (c + 2)  (c + 66) (c + 130) (c + 194)
          k     = a2 blamka g idx z (c + 32) (c + 96) (c + 160) (c + 224)
          k     = a2 blamka g idx z (c + 34) (c + 98) (c + 162) (c + 226)
          k     = a2 blamka g idx z c        (c + 66) (c + 160) (c + 226)
          k     = a2 blamka g idx z (c + 2)  (c + 96) (c + 162) (c + 192)
          k     = a2 blamka g idx z (c + 32) (c + 98) (c + 128) (c + 194)
          k     = a2 blamka g idx z (c + 34) (c + 64) (c + 130) (c + 224)
          a2 blamka cols loop z (c + 4 + k)

fn :: a2 bitxor blk8 Tensor[U64 * 256] Tensor[U64 * 256] => Tensor[U64 * 256]
      a2 bitxor blk8 a b = a_ij xor b_ij

fn :: a2 compress blk8 Tensor[U64 * 256] Tensor[U64 * 256] => Tensor[U64 * 256]
      a2 compress blk8 x y =
        r_ij = x_ij xor y_ij
        z_ij = r_ij
        z1   = a2 blamka rows loop z 0
        z2   = a2 blamka cols loop z1 0
        z2_ij xor r_ij

fn :: a2 compress blk8 bxor Tensor[U64 * 256] Tensor[U64 * 256] Tensor[U64 * 256] => Tensor[U64 * 256]
      a2 compress blk8 bxor x y old =
        r_ij  = x_ij xor y_ij
        ro_ij = r_ij xor old_ij
        z1    = a2 blamka rows loop r 0
        z2    = a2 blamka cols loop z1 0
        z2_ij xor ro_ij

fn :: a2 bytes to blk8 loop Tensor[U64 * 256] [Int] Int => Tensor[U64 * 256]
      a2 bytes to blk8 loop blk bs c =
        | c >= 128  = blk
        | otherwise =
          blk_(2 * c)       = a2 bytes to u32 le bs (c * 8)
          blk_((2 * c) + 1) = a2 bytes to u32 le bs ((c * 8) + 4)
          a2 bytes to blk8 loop blk bs (c + 1)

fn :: a2 bytes to blk8 [Int] => Tensor[U64 * 256]
      a2 bytes to blk8 bs    =
        a2 bytes to blk8 loop (Tensor[U64 * 256]) bs 0

fn :: a2 blk8 to bytes loop Tensor[U64 * 256] Int => [Int]
      a2 blk8 to bytes loop b c =
        | c >= 128  = []
        | otherwise = (a2 u32 to le4 b_(2 * c)) :: (a2 u32 to le4 b_((2 * c) + 1)) :: (a2 blk8 to bytes loop b (c + 1))

fn :: a2 blk8 to bytes Tensor[U64 * 256] => [Int]
      a2 blk8 to bytes b                 =
        a2 blk8 to bytes loop b 0

fn :: a2 zero mem => A2Mem
      a2 zero mem =
        zb = a2 zero blk8
        m1 = A2M16 zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb
        m2 = A2M256 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1
        m3 = A2M4096 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2
        A2Mem m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3

fn :: a2 get m16 A2M16 Int => Tensor[U64 * 256]
      a2 get m16 m     i   =
        | i < 8 =
          | i < 4 =
            | i == 0    = mb0 m
            | i == 1    = mb1 m
            | i == 2    = mb2 m
            | otherwise = mb3 m |.
          | otherwise =
            | i == 4    = mb4 m
            | i == 5    = mb5 m
            | i == 6    = mb6 m
            | otherwise = mb7 m |.
        | otherwise =
          | i < 12 =
            | i == 8    = mb8 m
            | i == 9    = mb9 m
            | i == 10   = mb10 m
            | otherwise = mb11 m |.
          | otherwise =
            | i == 12   = mb12 m
            | i == 13   = mb13 m
            | i == 14   = mb14 m
            | otherwise = mb15 m

fn :: a2 get m256 A2M256 Int Int => Tensor[U64 * 256]
      a2 get m256 m i1 i0 =
        | i1 < 8 =
          | i1 < 4 =
            | i1 == 0   = a2 get m16 (mr0 m) i0
            | i1 == 1   = a2 get m16 (mr1 m) i0
            | i1 == 2   = a2 get m16 (mr2 m) i0
            | otherwise = a2 get m16 (mr3 m) i0 |.
          | otherwise =
            | i1 == 4   = a2 get m16 (mr4 m) i0
            | i1 == 5   = a2 get m16 (mr5 m) i0
            | i1 == 6   = a2 get m16 (mr6 m) i0
            | otherwise = a2 get m16 (mr7 m) i0 |.
        | otherwise =
          | i1 < 12 =
            | i1 == 8   = a2 get m16 (mr8 m) i0
            | i1 == 9   = a2 get m16 (mr9 m) i0
            | i1 == 10  = a2 get m16 (mr10 m) i0
            | otherwise = a2 get m16 (mr11 m) i0 |.
          | otherwise =
            | i1 == 12  = a2 get m16 (mr12 m) i0
            | i1 == 13  = a2 get m16 (mr13 m) i0
            | i1 == 14  = a2 get m16 (mr14 m) i0
            | otherwise = a2 get m16 (mr15 m) i0

fn :: a2 get m4096 A2M4096 Int Int Int => Tensor[U64 * 256]
      a2 get m4096 m i2 i1 i0 =
        | i2 < 8 =
          | i2 < 4 =
            | i2 == 0   = a2 get m256 (mp0 m) i1 i0
            | i2 == 1   = a2 get m256 (mp1 m) i1 i0
            | i2 == 2   = a2 get m256 (mp2 m) i1 i0
            | otherwise = a2 get m256 (mp3 m) i1 i0 |.
          | otherwise =
            | i2 == 4   = a2 get m256 (mp4 m) i1 i0
            | i2 == 5   = a2 get m256 (mp5 m) i1 i0
            | i2 == 6   = a2 get m256 (mp6 m) i1 i0
            | otherwise = a2 get m256 (mp7 m) i1 i0 |.
        | otherwise =
          | i2 < 12 =
            | i2 == 8   = a2 get m256 (mp8 m) i1 i0
            | i2 == 9   = a2 get m256 (mp9 m) i1 i0
            | i2 == 10  = a2 get m256 (mp10 m) i1 i0
            | otherwise = a2 get m256 (mp11 m) i1 i0 |.
          | otherwise =
            | i2 == 12  = a2 get m256 (mp12 m) i1 i0
            | i2 == 13  = a2 get m256 (mp13 m) i1 i0
            | i2 == 14  = a2 get m256 (mp14 m) i1 i0
            | otherwise = a2 get m256 (mp15 m) i1 i0

fn :: a2 get mem A2Mem Int Int Int Int => Tensor[U64 * 256]
      a2 get mem m i3 i2 i1 i0 =
        | i3 < 8 =
          | i3 < 4 =
            | i3 == 0   = a2 get m4096 (mt0 m) i2 i1 i0
            | i3 == 1   = a2 get m4096 (mt1 m) i2 i1 i0
            | i3 == 2   = a2 get m4096 (mt2 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt3 m) i2 i1 i0 |.
          | otherwise =
            | i3 == 4   = a2 get m4096 (mt4 m) i2 i1 i0
            | i3 == 5   = a2 get m4096 (mt5 m) i2 i1 i0
            | i3 == 6   = a2 get m4096 (mt6 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt7 m) i2 i1 i0 |.
        | otherwise =
          | i3 < 12 =
            | i3 == 8   = a2 get m4096 (mt8 m) i2 i1 i0
            | i3 == 9   = a2 get m4096 (mt9 m) i2 i1 i0
            | i3 == 10  = a2 get m4096 (mt10 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt11 m) i2 i1 i0 |.
          | otherwise =
            | i3 == 12  = a2 get m4096 (mt12 m) i2 i1 i0
            | i3 == 13  = a2 get m4096 (mt13 m) i2 i1 i0
            | i3 == 14  = a2 get m4096 (mt14 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt15 m) i2 i1 i0

fn :: a2 nth blk A2Mem Int => Tensor[U64 * 256]
      a2 nth blk m     idx =
        a2 get mem m ((idx shr 12) and 15) ((idx shr 8) and 15) ((idx shr 4) and 15) (idx and 15)

fn :: a2 set m16 A2M16 Int Tensor[U64 * 256] => A2M16
      a2 set m16 m i val =
        | i < 8 =
          | i < 4 =
            | i == 0    = m with mb0 = val
            | i == 1    = m with mb1 = val
            | i == 2    = m with mb2 = val
            | otherwise = m with mb3 = val |.
          | otherwise =
            | i == 4    = m with mb4 = val
            | i == 5    = m with mb5 = val
            | i == 6    = m with mb6 = val
            | otherwise = m with mb7 = val |.
        | otherwise =
          | i < 12 =
            | i == 8    = m with mb8 = val
            | i == 9    = m with mb9 = val
            | i == 10   = m with mb10 = val
            | otherwise = m with mb11 = val |.
          | otherwise =
            | i == 12   = m with mb12 = val
            | i == 13   = m with mb13 = val
            | i == 14   = m with mb14 = val
            | otherwise = m with mb15 = val

fn :: a2 set m256 A2M256 Int Int Tensor[U64 * 256] => A2M256
      a2 set m256 m i1 i0 val =
        | i1 < 8 =
          | i1 < 4 =
            | i1 == 0   = m with mr0 = (a2 set m16 (mr0 m) i0 val)
            | i1 == 1   = m with mr1 = (a2 set m16 (mr1 m) i0 val)
            | i1 == 2   = m with mr2 = (a2 set m16 (mr2 m) i0 val)
            | otherwise = m with mr3 = (a2 set m16 (mr3 m) i0 val) |.
          | otherwise =
            | i1 == 4   = m with mr4 = (a2 set m16 (mr4 m) i0 val)
            | i1 == 5   = m with mr5 = (a2 set m16 (mr5 m) i0 val)
            | i1 == 6   = m with mr6 = (a2 set m16 (mr6 m) i0 val)
            | otherwise = m with mr7 = (a2 set m16 (mr7 m) i0 val) |.
        | otherwise =
          | i1 < 12 =
            | i1 == 8   = m with mr8 = (a2 set m16 (mr8 m) i0 val)
            | i1 == 9   = m with mr9 = (a2 set m16 (mr9 m) i0 val)
            | i1 == 10  = m with mr10 = (a2 set m16 (mr10 m) i0 val)
            | otherwise = m with mr11 = (a2 set m16 (mr11 m) i0 val) |.
          | otherwise =
            | i1 == 12  = m with mr12 = (a2 set m16 (mr12 m) i0 val)
            | i1 == 13  = m with mr13 = (a2 set m16 (mr13 m) i0 val)
            | i1 == 14  = m with mr14 = (a2 set m16 (mr14 m) i0 val)
            | otherwise = m with mr15 = (a2 set m16 (mr15 m) i0 val)

fn :: a2 set m4096 A2M4096 Int Int Int Tensor[U64 * 256] => A2M4096
      a2 set m4096 m i2 i1 i0 val =
        | i2 < 8 =
          | i2 < 4 =
            | i2 == 0   = m with mp0 = (a2 set m256 (mp0 m) i1 i0 val)
            | i2 == 1   = m with mp1 = (a2 set m256 (mp1 m) i1 i0 val)
            | i2 == 2   = m with mp2 = (a2 set m256 (mp2 m) i1 i0 val)
            | otherwise = m with mp3 = (a2 set m256 (mp3 m) i1 i0 val) |.
          | otherwise =
            | i2 == 4   = m with mp4 = (a2 set m256 (mp4 m) i1 i0 val)
            | i2 == 5   = m with mp5 = (a2 set m256 (mp5 m) i1 i0 val)
            | i2 == 6   = m with mp6 = (a2 set m256 (mp6 m) i1 i0 val)
            | otherwise = m with mp7 = (a2 set m256 (mp7 m) i1 i0 val) |.
        | otherwise =
          | i2 < 12 =
            | i2 == 8   = m with mp8 = (a2 set m256 (mp8 m) i1 i0 val)
            | i2 == 9   = m with mp9 = (a2 set m256 (mp9 m) i1 i0 val)
            | i2 == 10  = m with mp10 = (a2 set m256 (mp10 m) i1 i0 val)
            | otherwise = m with mp11 = (a2 set m256 (mp11 m) i1 i0 val) |.
          | otherwise =
            | i2 == 12  = m with mp12 = (a2 set m256 (mp12 m) i1 i0 val)
            | i2 == 13  = m with mp13 = (a2 set m256 (mp13 m) i1 i0 val)
            | i2 == 14  = m with mp14 = (a2 set m256 (mp14 m) i1 i0 val)
            | otherwise = m with mp15 = (a2 set m256 (mp15 m) i1 i0 val)

fn :: a2 set mem A2Mem Int Int Int Int Tensor[U64 * 256] => A2Mem
      a2 set mem m i3 i2 i1 i0 val =
        | i3 < 8 =
          | i3 < 4 =
            | i3 == 0   = m with mt0 = (a2 set m4096 (mt0 m) i2 i1 i0 val)
            | i3 == 1   = m with mt1 = (a2 set m4096 (mt1 m) i2 i1 i0 val)
            | i3 == 2   = m with mt2 = (a2 set m4096 (mt2 m) i2 i1 i0 val)
            | otherwise = m with mt3 = (a2 set m4096 (mt3 m) i2 i1 i0 val) |.
          | otherwise =
            | i3 == 4   = m with mt4 = (a2 set m4096 (mt4 m) i2 i1 i0 val)
            | i3 == 5   = m with mt5 = (a2 set m4096 (mt5 m) i2 i1 i0 val)
            | i3 == 6   = m with mt6 = (a2 set m4096 (mt6 m) i2 i1 i0 val)
            | otherwise = m with mt7 = (a2 set m4096 (mt7 m) i2 i1 i0 val) |.
        | otherwise =
          | i3 < 12 =
            | i3 == 8   = m with mt8 = (a2 set m4096 (mt8 m) i2 i1 i0 val)
            | i3 == 9   = m with mt9 = (a2 set m4096 (mt9 m) i2 i1 i0 val)
            | i3 == 10  = m with mt10 = (a2 set m4096 (mt10 m) i2 i1 i0 val)
            | otherwise = m with mt11 = (a2 set m4096 (mt11 m) i2 i1 i0 val) |.
          | otherwise =
            | i3 == 12  = m with mt12 = (a2 set m4096 (mt12 m) i2 i1 i0 val)
            | i3 == 13  = m with mt13 = (a2 set m4096 (mt13 m) i2 i1 i0 val)
            | i3 == 14  = m with mt14 = (a2 set m4096 (mt14 m) i2 i1 i0 val)
            | otherwise = m with mt15 = (a2 set m4096 (mt15 m) i2 i1 i0 val)
```

### 25.4.2. Implementación interna: Core Implementation Part 9

Fíxate en como `argon2id.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 25.4.3. Implementación interna: Core Implementation Part 18

Fíxate en como `argon2id.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 25.4.4. Implementación interna: Core Implementation Part 26

Fíxate en como `argon2id.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 25.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `argon2id`

- **Garantía algorítmica e de seguridade**: Coincidencia byte a byte cos vectores oficiais RFC 9106 §5.3 e OpenSSL 3.5, operando sobre `Tensor[U64 * 8 * 16]` sen unha soa liña de C.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/argon2id.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test argon2id.rg`.

### As 5 Regras de Ouro ao programar con `argon2id`

1. **Declara `import argon2id` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `argon2id` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `argon2id` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `argon2id` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 26** pasaremos a explorar en profundidade a lib **`jwt`** (A lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) e Tokens Cifrados ChaCha20-Poly1305).
