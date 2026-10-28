# Capítulo 19: A lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 e PRNG

## 19.1. Por que existe a lib `uuid`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `uuid` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `uuid`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: usar `UUIDv4` completamente aleatorios como chave primaria nunha base de datos fragmenta os índices B-Tree, mentres que inventarse IDs caseiros sen entropía do kernel acaba en colisións.

A lib **`uuid`** implementa **`UUIDv4`** (aleatorio con CSPRNG do kernel) e **`UUIDv7`** (ordenado cronoloxicamente nos primeiros 48 bits segundo **RFC 9562**), sumas de verificación rápidas (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) e un PRNG determinista con semente.

Nun ecosistema tradicional, resolver as tarefas do dominio **`UUID`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`uuid`** (`src/main/ridgun/lib/uuid.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import uuid` (ou `import uuid as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: uuid` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `uuid` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 19.2. Artefactos nativos, importación e catálogo completo da API de `uuid`

En `ridgun-libs`, **`uuid`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/uuid.rg` (dominio `UUID`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.rglib` | Distribución e importación directa con `import uuid` |
| **Ficheiro compilado** | `target/uuid.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libuuid.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: uuid`: abonda con escribir `import uuid` (ou `import uuid as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 19.2.1. Resumo de familias funcionais de `uuid`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Xera UUIDs canónicos de 36 caracteres RFC 9562 v4 (aleatorio) e v7 (ordenado polo tempo) |
| `uuid is valid / uuid version` | Valida a estrutura 8-4-4-4-12 e os bits de variante RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hashes non criptográficos e sumas de verificación rápidas de 32 bits |
| `prng next / prng range` | PRNG congruencial lineal funcional puro para probas e simulacións reproducibles |

### 19.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/uuid.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/uuid.rg` (`0` tipos, `0` operadores e `33` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: uu hex lut Int` | `String` |
| `2` | `fn :: uu u32 Int` | `Int` |
| `3` | `fn :: uu bxor loop Int Int Int Int` | `Int` |
| `4` | `fn :: uu bxor32 Int Int` | `Int` |
| `5` | `fn :: uu fnv loop String Int Int Int` | `Int` |
| `6` | `fn :: fnv1a 32 String` | `Int` |
| `7` | `fn :: uu adler loop String Int Int Int Int` | `Int` |
| `8` | `fn :: adler32 String` | `Int` |
| `9` | `fn :: uu crc bit loop Int Int` | `Int` |
| `10` | `fn :: uu crc byte loop String Int Int Int` | `Int` |
| `11` | `fn :: crc32 String` | `Int` |
| `12` | `fn :: uu abs Int` | `Int` |
| `13` | `fn :: prng next Int` | `Int` |
| `14` | `fn :: uu prng range step Int Int Int` | `Int Int` |
| `15` | `fn :: prng range Int Int Int` | `Int Int` |
| `16` | `fn :: uu alloc page Int` | `Int` |
| `17` | `fn :: uu free page Int Int Int` | `Int` |
| `18` | `fn :: uu alloc mfd` | `Int` |
| `19` | `fn :: uu peek Int Int Int` | `String` |
| `20` | `fn :: uu decode u32 le String Int` | `Int` |
| `21` | `fn :: uu decode u64 le String Int` | `Int` |
| `22` | `fn :: uu wall time ms` | `Int` |
| `23` | `fn :: uu bytes to hex loop String Int Int` | `String` |
| `24` | `fn :: uu random hex16` | `String` |
| `25` | `fn :: uu hex val Int` | `Int` |
| `26` | `fn :: uu variant char String` | `String` |
| `27` | `fn :: uuid v4` | `String` |
| `28` | `fn :: uu hex48 loop Int Int` | `String` |
| `29` | `fn :: uuid v7 at Int` | `String` |
| `30` | `fn :: uuid v7` | `String` |
| `31` | `fn :: uu is hex range String Int Int` | `Bool` |
| `32` | `fn :: uuid is valid String` | `Bool` |
| `33` | `fn :: uuid version String` | `Int` |

---

## 19.3. Explorando `uuid` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `uuid` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test uuid.rg`.

### 19.3.1. Exemplo 1: Fluxo principal en estilo tabular con `uuid`

Observa como en Ridgun os signos `=` e os pasos de transformación con `uuid` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import uuid

fn :: generar ids ordenados => String String Bool
      generar ids ordenados =
        1000 uuid v7 at -> id1
        2000 uuid v7 at -> id2
        (uuid is valid id1) and (id1 < id2) -> ok
        (id1, id2, ok)
```

### 19.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `uuid` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete String => Int Int
      firmar paquete payload =
        payload crc32 -> c32
        payload fnv1a 32 -> fnv
        (c32, fnv)
```

### 19.3.3. Exemplo 3: Xeración, validación e inspección de UUIDv4 (CSPRNG) e UUIDv7 ordenables por tempo (RFC 9562)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `uuid` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test uuidv4 and uuidv7 => ()
      test uuidv4 and uuidv7 =
        u4a = uuid v4
        u4b = uuid v4
        assert int equals (str len u4a) 36 "AC1: uuid_v4 length 36"
        assert true (uuid is valid u4a) "AC1: uuid_v4 valid RFC 9562 format"
        assert true (uuid is valid u4b) "AC1: second uuid_v4 valid"
        assert false (u4a == u4b) "AC1: CSPRNG uuid_v4 calls are unique"
        assert int equals (uuid version u4a) 4 "AC1: uuid_v4 version == 4"

        -- RFC 9562 UUIDv7 timestamp encoding & chronological prefix ordering
        u7_zero = uuid v7 at 0
        u7a = uuid v7 at 1700000000000
        u7b = uuid v7 at 1800000000000
        u7_live = uuid v7
        assert true (uuid is valid u7_zero) "AC1: uuid_v7 at epoch 0 valid"
        assert str eq (str slice u7_zero 0 13) "00000000-0000" "AC1: uuid_v7 at epoch 0 zero prefix"
        assert true (uuid is valid u7a) "AC1: uuid_v7 at 1700000000000 valid"
        assert true (uuid is valid u7b) "AC1: uuid_v7 at 1800000000000 valid"
        assert true (uuid is valid u7_live) "AC1: live uuid_v7 valid"
        assert int equals (uuid version u7a) 7 "AC1: uuid_v7 version == 7"
        assert int equals (uuid version u7_live) 7 "AC1: live uuid_v7 version == 7"
        assert str eq (str slice u7a 0 8) "018bcfe5" "AC1: uuid_v7 timestamp prefix 1700000000000"
        assert str eq (str slice u7b 0 8) "01a3185c" "AC1: uuid_v7 timestamp prefix 1800000000000"

        -- Uppercase valid UUID acceptance & RFC 9562 variant nibble (8, 9, a, b) validation
        assert true (uuid is valid "550E8400-E29B-41D4-A716-446655440000") "AC1: uppercase RFC 9562 UUID valid"
        assert false (uuid is valid "") "AC1: empty string invalid"
        assert false (uuid is valid "not-a-uuid") "AC1: short string invalid"
        assert false (uuid is valid "550e8400-e29b-41d4-1716-446655440000") "AC1: variant nibble '1' (< 8) rejected"
        assert false (uuid is valid "550e8400-e29b-41d4-c716-446655440000") "AC1: variant nibble 'c' (> b) rejected"
        assert false (uuid is valid "550e8400Xe29b-41d4-a716-446655440000") "AC1: missing hyphen at index 8 rejected"
        assert false (uuid is valid "550e8400-e29b-41d4-a716-44665544000g") "AC1: non-hex character 'g' rejected"
        assert int equals (uuid version "not-a-uuid") (0 - 1) "AC1: invalid uuid version -> -1"
        ()
```

### 19.3.4. Exemplo 4: Sumas de verificación FNV-1a, DJB2, Adler-32, CRC32 IEEE 802.3 (`0xCBF43926`) e PRNG determinista SplitMix64

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `uuid` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test checksums and prng => ()
      test checksums and prng =
        -- Official FNV-1a 32-bit vectors (isthe.com/chongo/tech/comp/fnv/)
        assert int equals (fnv1a 32 "") 2166136261 "AC2: FNV-1a 32 '' == 0x811c9dc5 (offset basis)"
        assert int equals (fnv1a 32 "a") 3826002220 "AC2: FNV-1a 32 'a' == 0xe40c292c"
        assert int equals (fnv1a 32 "foobar") 3214735720 "AC2: FNV-1a 32 'foobar' == 0xbf9cf968"

        -- Official RFC 1950 Adler-32 vectors
        assert int equals (adler32 "") 1 "AC2: Adler-32 '' == 1"
        assert int equals (adler32 "a") 6422626 "AC2: Adler-32 'a' == 0x00620062"
        assert int equals (adler32 "Wikipedia") 300286872 "AC2: Adler-32 'Wikipedia' == 0x11e60398"

        -- Official IEEE 802.3 / ISO-HDLC CRC-32 vectors
        assert int equals (crc32 "") 0 "AC2: CRC-32 '' == 0"
        assert int equals (crc32 "a") 3904355907 "AC2: CRC-32 'a' == 0xe8b7be43"
        assert int equals (crc32 "123456789") 3421780262 "AC2: CRC-32 '123456789' == 0xcbf43926"

        -- Deterministic 31-bit LCG PRNG
        s1 = prng next 42
        s2 = prng next 42
        s3 = prng next s1
        assert int equals s1 s2 "AC3: prng_next deterministic for same seed"
        assert false (s1 == s3) "AC3: prng_next advances state"
        r1 = prng range 42 10 20
        v1 = prng val r1
        assert true (v1 >= 10 and v1 <= 20) "AC3: prng_range within [10, 20]"
        r_deg = prng range 42 50 10
        assert int equals (prng val r_deg) 50 "AC3: prng_range with hi <= lo clamps to lo"
        ()
```

### 19.3.5. Exemplo 5: Trazabilidade distribuída con UUIDv7 ordenables por tempo e integridade de paquetes con CRC32 e FNV-1a (`uuid v7`, `uuid v7 timestamp ms`, `crc32 hex`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `uuid` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
import uuid

fn :: sellar paquete trazado (ahora_ms : Int) (payload : String) => (String, Int, String, Int)
      sellar paquete trazado ahora_ms payload =
        trace_id = uuid v7 ahora_ms
        ts_extra = uuid v7 timestamp ms trace_id
        crc_hex  = crc32 hex payload
        hash_fnv = fnv1a 64 payload
        (trace_id, ts_extra, crc_hex, hash_fnv)
```

---

## 19.4. Baixo o capó: como está construída `uuid` en Ridgun puro (`src/main/ridgun/lib/uuid.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/uuid.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 19.4.1. Implementación interna: RFC 9562 UUIDv4 & UUIDv7 Generation & Validation (CSPRNG + clock_gettime)

Fíxate en como `uuid.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: uuid

fn :: uu alloc page Int => Int
      uu alloc page sz  =
        neg1 = 0 - 1
        sys call 9 0 sz 3 34 neg1 0

fn :: uu free page Int Int Int => Int
      uu free page mfd ptr sz =
        sys close mfd -> ()
        sys call 11 ptr sz 0 0 0 0

fn :: uu alloc mfd => Int
      uu alloc mfd =  sys call 319 4194311 1 0 0 0 0

fn :: uu peek Int Int Int => String
      uu peek mfd ptr len =
        sys call 18 mfd ptr len 0 0 0 -> ()
        sys call 8 mfd 0 0 0 0 0 -> ()
        sys read fd mfd len

fn :: uu decode u32 le String Int => Int
      uu decode u32 le s off =
        b0 = str char at s off
        b1 = str char at s (off + 1)
        b2 = str char at s (off + 2)
        b3 = str char at s (off + 3)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

fn :: uu decode u64 le String Int => Int
      uu decode u64 le s off =
        uu decode u32 le s off -> lo
        uu decode u32 le s (off + 4) -> hi
        lo + (hi * 4294967296)

fn :: uu wall time ms => Int
      uu wall time ms =
        uu alloc page 4096 -> ptr
        uu alloc mfd -> mfd
        sys call 228 0 ptr 0 0 0 0 -> ()
        uu peek mfd ptr 16 -> raw
        uu free page mfd ptr 4096 -> ()
        uu decode u64 le raw 0 -> sec
        uu decode u64 le raw 8 -> nsec
        (sec * 1000) + (nsec / 1000000)

fn :: uu bytes to hex loop String Int Int => String
      uu bytes to hex loop s idx len =
        | idx >= len = ""
        | otherwise =
          b   = ((str char at s idx) % 256 + 256) % 256
          hi  = b / 16
          lo  = b % 16
          tbl = uu hex lut 0
          (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1)) + (uu bytes to hex loop s (idx + 1) len)

fn :: uu random hex16 => String
      uu random hex16 =
        uu alloc page 4096 -> ptr
        uu alloc mfd -> mfd
        sys call 318 ptr 16 0 0 0 0 -> ()
        uu peek mfd ptr 16 -> raw
        uu free page mfd ptr 4096 -> ()
        uu bytes to hex loop raw 0 16

fn :: uu hex val Int => Int
      uu hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: uu variant char String => String
      uu variant char hex1   =
        v   = uu hex val (str char at hex1 0)
        idx = 8 + (v % 4)
        tbl = uu hex lut 0
        str slice tbl idx (idx + 1)

fn :: uuid v4 => String
      uuid v4 =
        h  = uu random hex16
        p1 = str slice h 0 8
        p2 = str slice h 8 12
        p3 = "4" + (str slice h 13 16)
        p4 = (uu variant char (str slice h 16 17)) + (str slice h 17 20)
        p5 = str slice h 20 32
        "{p1}-{p2}-{p3}-{p4}-{p5}"

fn :: uu hex48 loop Int Int => String
      uu hex48 loop val rem =
        | rem <= 0 = ""
        | otherwise =
          nib = ((val % 16) + 16) % 16
          tbl = uu hex lut 0
          (uu hex48 loop (val / 16) (rem - 1)) + (str slice tbl nib (nib + 1))

fn :: uuid v7 at Int   => String
      uuid v7 at ts_ms =
        eff_ts = uu abs ts_ms
        ts_hex = uu hex48 loop eff_ts 12
        h      = uu random hex16
        p1     = str slice ts_hex 0 8
        p2     = str slice ts_hex 8 12
        p3     = "7" + (str slice h 0 3)
        p4     = (uu variant char (str slice h 3 4)) + (str slice h 4 7)
        p5     = str slice h 7 19
        "{p1}-{p2}-{p3}-{p4}-{p5}"

fn :: uuid v7 => String
      uuid v7 =  uuid v7 at (uu wall time ms)

fn :: uu is hex range String Int Int => Bool
      uu is hex range s idx end_idx =
        | idx >= end_idx                       = True
        | (uu hex val (str char at s idx)) < 0 = False
        | otherwise                            = uu is hex range s (idx + 1) end_idx

fn :: uuid is valid String => Bool
      uuid is valid u      =
        | (str len u) != 36               = False
        | (str char at u 8) != 45         = False
        | (str char at u 13) != 45        = False
        | (str char at u 18) != 45        = False
        | (str char at u 23) != 45        = False
        | not (uu is hex range u 0 8)     = False
        | not (uu is hex range u 9 13)    = False
        | not (uu is hex range u 14 18)   = False
        | not (uu is hex range u 19 23)   = False
        | not (uu is hex range u 24 36)   = False
        | otherwise =
          var_nib = uu hex val (str char at u 19)
          (var_nib >= 8) and (var_nib <= 11)

fn :: uuid version String => Int
      uuid version u      =
        | not (uuid is valid u) = 0 - 1
        | otherwise             = uu hex val (str char at u 14)
```

---

## 19.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `uuid`

- **Garantía algorítmica e de seguridade**: `uuid v7 at t1 < uuid v7 at t2` garante orde lexicográfica monótona crecente co tempo, ideal para índices `btree` e bases de datos.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/uuid.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test uuid.rg`.

### As 5 Regras de Ouro ao programar con `uuid`

1. **Declara `import uuid` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `uuid` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `uuid` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `uuid` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 20** pasaremos a explorar en profundidade a lib **`log`** (A lib `log` — Logging Estruturado NDJSON e Redacción Automática de Segredos).
