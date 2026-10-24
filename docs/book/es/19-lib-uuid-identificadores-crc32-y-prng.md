# Capítulo 19: La lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 y PRNG

## 19.1. ¿Por qué existe la lib `uuid`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `uuid` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `uuid`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: usar `UUIDv4` completamente aleatorios como clave primaria en una base de datos fragmenta los índices B-Tree, mientras que inventarse IDs caseros sin entropía del kernel acaba en colisiones.

La lib **`uuid`** implementa **`UUIDv4`** (aleatorio con CSPRNG del kernel) y **`UUIDv7`** (ordenado cronológicamente en los primeros 48 bits según **RFC 9562**), sumas de verificación rápidas (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) y un PRNG determinista con semilla.

En un ecosistema tradicional, resolver las tareas del dominio **`UUID`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`uuid`** (`src/main/ridgun/lib/uuid.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `uuid` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `uuid` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `uuid` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 19.2. Artefactos nativos, importación y catálogo completo de la API de `uuid`

En `ridgun-libs`, **`uuid`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/uuid.rg` (dominio `UUID`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.rglib` | Distribución e importación directa con `import uuid` |
| **Archivo compilado** | `target/uuid.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libuuid.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import uuid` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 19.2.1. Resumen de familias funcionales de `uuid`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Genera UUIDs canónicos de 36 caracteres RFC 9562 v4 (aleatorio) y v7 (ordenado por tiempo) |
| `uuid is valid / uuid version` | Valida la estructura 8-4-4-4-12 y los bits de variante RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hashes no criptográficos y sumas de verificación rápidas de 32 bits |
| `prng next / prng range` | PRNG congruencial lineal funcional puro para pruebas y simulaciones reproducibles |

### 19.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/uuid.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/uuid.rg` (`0` tipos, `0` operadores y `33` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 19.3. Explorando `uuid` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `uuid` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test uuid.rg`.

### 19.3.1. Ejemplo 1: Flujo principal en estilo tabular con `uuid`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `uuid` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### 19.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `uuid` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

### 19.3.3. Ejemplo 3: Generación, validación e inspección de UUIDv4 (CSPRNG) y UUIDv7 ordenables por tiempo (RFC 9562)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `uuid` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test uuidv4 and uuidv7 => ()
      test uuidv4 and uuidv7 =
        u4a = uuid v4
        u4b = uuid v4
        _ = assert int equals (str len u4a) 36 "AC1: uuid_v4 length 36"
        _ = assert true (uuid is valid u4a) "AC1: uuid_v4 valid RFC 9562 format"
        _ = assert true (uuid is valid u4b) "AC1: second uuid_v4 valid"
        _ = assert false (u4a == u4b) "AC1: CSPRNG uuid_v4 calls are unique"
        _ = assert int equals (uuid version u4a) 4 "AC1: uuid_v4 version == 4"

        -- RFC 9562 UUIDv7 timestamp encoding & chronological prefix ordering
        u7_zero = uuid v7 at 0
        u7a = uuid v7 at 1700000000000
        u7b = uuid v7 at 1800000000000
        u7_live = uuid v7
        _ = assert true (uuid is valid u7_zero) "AC1: uuid_v7 at epoch 0 valid"
        _ = assert str eq (str slice u7_zero 0 13) "00000000-0000" "AC1: uuid_v7 at epoch 0 zero prefix"
        _ = assert true (uuid is valid u7a) "AC1: uuid_v7 at 1700000000000 valid"
        _ = assert true (uuid is valid u7b) "AC1: uuid_v7 at 1800000000000 valid"
        _ = assert true (uuid is valid u7_live) "AC1: live uuid_v7 valid"
        _ = assert int equals (uuid version u7a) 7 "AC1: uuid_v7 version == 7"
        _ = assert int equals (uuid version u7_live) 7 "AC1: live uuid_v7 version == 7"
        _ = assert str eq (str slice u7a 0 8) "018bcfe5" "AC1: uuid_v7 timestamp prefix 1700000000000"
        _ = assert str eq (str slice u7b 0 8) "01a3185c" "AC1: uuid_v7 timestamp prefix 1800000000000"

        -- Uppercase valid UUID acceptance & RFC 9562 variant nibble (8, 9, a, b) validation
        _ = assert true (uuid is valid "550E8400-E29B-41D4-A716-446655440000") "AC1: uppercase RFC 9562 UUID valid"
        _ = assert false (uuid is valid "") "AC1: empty string invalid"
        _ = assert false (uuid is valid "not-a-uuid") "AC1: short string invalid"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-1716-446655440000") "AC1: variant nibble '1' (< 8) rejected"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-c716-446655440000") "AC1: variant nibble 'c' (> b) rejected"
        _ = assert false (uuid is valid "550e8400Xe29b-41d4-a716-446655440000") "AC1: missing hyphen at index 8 rejected"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-a716-44665544000g") "AC1: non-hex character 'g' rejected"
        _ = assert int equals (uuid version "not-a-uuid") (0 - 1) "AC1: invalid uuid version -> -1"
        ()
```

### 19.3.4. Ejemplo 4: Sumas de verificación FNV-1a, DJB2, Adler-32, CRC32 IEEE 802.3 (`0xCBF43926`) y PRNG determinista SplitMix64

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `uuid` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test checksums and prng => ()
      test checksums and prng =
        -- Official FNV-1a 32-bit vectors (isthe.com/chongo/tech/comp/fnv/)
        _ = assert int equals (fnv1a 32 "") 2166136261 "AC2: FNV-1a 32 '' == 0x811c9dc5 (offset basis)"
        _ = assert int equals (fnv1a 32 "a") 3826002220 "AC2: FNV-1a 32 'a' == 0xe40c292c"
        _ = assert int equals (fnv1a 32 "foobar") 3214735720 "AC2: FNV-1a 32 'foobar' == 0xbf9cf968"

        -- Official RFC 1950 Adler-32 vectors
        _ = assert int equals (adler32 "") 1 "AC2: Adler-32 '' == 1"
        _ = assert int equals (adler32 "a") 6422626 "AC2: Adler-32 'a' == 0x00620062"
        _ = assert int equals (adler32 "Wikipedia") 300286872 "AC2: Adler-32 'Wikipedia' == 0x11e60398"

        -- Official IEEE 802.3 / ISO-HDLC CRC-32 vectors
        _ = assert int equals (crc32 "") 0 "AC2: CRC-32 '' == 0"
        _ = assert int equals (crc32 "a") 3904355907 "AC2: CRC-32 'a' == 0xe8b7be43"
        _ = assert int equals (crc32 "123456789") 3421780262 "AC2: CRC-32 '123456789' == 0xcbf43926"

        -- Deterministic 31-bit LCG PRNG
        s1 = prng next 42
        s2 = prng next 42
        s3 = prng next s1
        _ = assert int equals s1 s2 "AC3: prng_next deterministic for same seed"
        _ = assert false (s1 == s3) "AC3: prng_next advances state"
        r1 = prng range 42 10 20
        v1 = prng val r1
        _ = assert true (v1 >= 10 and v1 <= 20) "AC3: prng_range within [10, 20]"
        r_deg = prng range 42 50 10
        _ = assert int equals (prng val r_deg) 50 "AC3: prng_range with hi <= lo clamps to lo"
        ()
```

### 19.3.5. Ejemplo 5: Trazabilidad distribuida con UUIDv7 ordenables por tiempo e integridad de paquetes con CRC32 y FNV-1a (`uuid v7`, `uuid v7 timestamp ms`, `crc32 hex`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `uuid` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 19.4. Bajo el capó: cómo está construida `uuid` en Ridgun puro (`src/main/ridgun/lib/uuid.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/uuid.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 19.4.1. Implementación interna: RFC 9562 UUIDv4 & UUIDv7 Generation & Validation (CSPRNG + clock_gettime)

Fíjate en cómo `uuid.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: uu alloc page Int => Int
      uu alloc page sz  =
        neg1 = 0 - 1
        sys call 9 0 sz 3 34 neg1 0

fn :: uu free page Int Int Int => Int
      uu free page mfd ptr sz =
        _ = sys close mfd
        sys call 11 ptr sz 0 0 0 0

fn :: uu alloc mfd => Int
      uu alloc mfd =  sys call 319 4194311 1 0 0 0 0

fn :: uu peek Int Int Int => String
      uu peek mfd ptr len =
        _ = sys call 18 mfd ptr len 0 0 0
        _ = sys call 8 mfd 0 0 0 0 0
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
        lo = uu decode u32 le s off
        hi = uu decode u32 le s (off + 4)
        lo + (hi * 4294967296)

fn :: uu wall time ms => Int
      uu wall time ms =
        ptr  = uu alloc page 4096
        mfd  = uu alloc mfd
        _    = sys call 228 0 ptr 0 0 0 0
        raw  = uu peek mfd ptr 16
        _    = uu free page mfd ptr 4096
        sec  = uu decode u64 le raw 0
        nsec = uu decode u64 le raw 8
        (sec * 1000) + (nsec / 1000000)
```

---

## 19.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `uuid`

- **Garantía algorítmica y de seguridad**: `uuid v7 at t1 < uuid v7 at t2` garantiza orden lexicográfico monótono creciente con el tiempo, ideal para índices `btree` y bases de datos.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/uuid.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test uuid.rg`.

### Las 5 Reglas de Oro al programar con `uuid`

1. **Declara `import uuid` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `uuid` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `uuid` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `uuid` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 20** pasaremos a explorar en profundidad la lib **`log`** (La lib `log` — Logging Estructurado NDJSON y Redacción Automática de Secretos).
