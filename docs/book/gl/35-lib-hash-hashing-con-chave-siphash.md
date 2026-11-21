# Capítulo 35: A lib `hash` — Hashing con Chave SipHash-1-3 para Táboas Hash

## 35.1. Por que existe a lib `hash`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `hash` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `hash`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: cando a función hash dunha táboa hash é pública, quen controla as chaves pode enviar miles que caen na mesma rañura, e unha soa petición custa entón o que debería custar un millón (hash flooding).

A lib **`hash`** implementa **SipHash-1-3** (Aumasson & Bernstein) cunha chave de 128 bits e un resultado de 64 bits. `siphash13` calcula o hash dunha cadea enteira; as operacións nativas do compilador `siphash13 range` e `siphash13 range low` (ridgunc 1.0.44) calculan o hash dun rango de bytes nunhas decenas de nanosegundos; `siphash13 reference` é o mesmo hash escrito en Ridgun simple, para lelo e para probar contra el; e `siphash new key` obtén do sistema unha chave aleatoria de 16 bytes.

Nun ecosistema tradicional, resolver as tarefas do dominio **`HASH`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`hash`** (`src/main/ridgun/lib/hash.ridgun`) aborda o problema con catro principios innegociables:

1. **Declara `import hash` (ou `import hash as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: hash` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `hash` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 35.2. Artefactos nativos, importación e catálogo completo da API de `hash`

En `ridgun-libs`, **`hash`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/hash.ridgun` (dominio `HASH`). Ao compilar con `stable bundle`, empaquétase nun formato nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hash.ridgunlib` | Distribución e importación directa con `import hash` |

> Cada lib declara o seu propio espazo de nomes con `module :: hash`: abonda con escribir `import hash` (ou `import hash as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 35.2.1. Resumo de familias funcionais de `hash`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `siphash13` | SipHash-1-3 dunha cadea enteira cunha chave de 16 bytes, como `Int` de 64 bits |
| `siphash13 range / siphash13 range low` | Operacións nativas do compilador: os 64 bits, ou os 32 bits baixos, do hash dun rango de bytes |
| `siphash13 reference` | O mesmo hash en Ridgun simple, sobre metades de 32 bits: a definición contra a que se proba a operación nativa |
| `siphash new key` | Unha chave aleatoria de 16 bytes da fonte de aleatoriedade do sistema (`""` cando non se pode ler) |

### 35.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/hash.ridgun`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/hash.ridgun` (`0` tipos, `0` operadores e `11` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: hs byte String Int` | `Int` |
| `2` | `fn :: hs tail String Int Int` | `Int` |
| `3` | `fn :: hs pick Int Int Int` | `Int` |
| `4` | `fn :: hs key word String Int` | `Int` |
| `5` | `fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `6` | `fn :: siphash13 last String Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `7` | `fn :: siphash13 start String String Int Int Int` | `Int` |
| `8` | `fn :: siphash13 String String` | `Int` |
| `9` | `fn :: siphash13 reference String String Int Int Int` | `Int` |
| `10` | `fn :: siphash new key` | `String` |
| `11` | `fn :: hs key of (Int String)` | `String` |

---

## 35.3. Explorando `hash` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `hash` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test hash.ridgun`.

### 35.3.1. Exemplo 1: Fluxo principal en estilo tabular con `hash`

Observa como en Ridgun os signos `=` e os pasos de transformación con `hash` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import hash

fn :: cubo de clave String String Int => Int
      cubo de clave semilla clave cubos =
        siphash13 range low semilla clave 0 (str len clave) -> h
        h % cubos
```

### 35.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `hash` está deseñada para compoñerse con gardas booleanas `|` e co resto das 38 libs de `ridgun-libs`:

```ridgun
import hash

fn :: huella segura String String => Int
      huella segura semilla dato =
        | (str len semilla) != 16 = 0
        | otherwise               = siphash13 semilla dato
```

### 35.3.3. Exemplo 3: Vectores SipHash-1-3 para entradas de 0 a 64 bytes: as metades baixa e alta de 32 bits

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `hash` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test siphash13 vectors => ()
      test siphash13 vectors =
        key = tensor to str (seq bytes (Tensor[U8 * 16]) 0 16)
        msg = tensor to str (seq bytes (Tensor[U8 * 64]) 0 64)
        siphash13 range low key msg 0 0 -> assert int equals 84919516 "low 32 bits, 0 bytes"
        (siphash13 range key msg 0 0) shr 32 -> assert int equals 2880176472 "high 32 bits, 0 bytes"
        siphash13 range low key msg 0 1 -> assert int equals 2102905491 "low 32 bits, 1 bytes"
        (siphash13 range key msg 0 1) shr 32 -> assert int equals 3388251123 "high 32 bits, 1 bytes"
        siphash13 range low key msg 0 7 -> assert int equals 2612072768 "low 32 bits, 7 bytes"
        (siphash13 range key msg 0 7) shr 32 -> assert int equals 3549592984 "high 32 bits, 7 bytes"
        siphash13 range low key msg 0 8 -> assert int equals 2368313998 "low 32 bits, 8 bytes"
        (siphash13 range key msg 0 8) shr 32 -> assert int equals 915445009 "high 32 bits, 8 bytes"
        siphash13 range low key msg 0 9 -> assert int equals 1812348388 "low 32 bits, 9 bytes"
        (siphash13 range key msg 0 9) shr 32 -> assert int equals 631541427 "high 32 bits, 9 bytes"
        siphash13 range low key msg 0 15 -> assert int equals 709990742 "low 32 bits, 15 bytes"
        (siphash13 range key msg 0 15) shr 32 -> assert int equals 3542145133 "high 32 bits, 15 bytes"
        siphash13 range low key msg 0 16 -> assert int equals 2106624870 "low 32 bits, 16 bytes"
        (siphash13 range key msg 0 16) shr 32 -> assert int equals 3427786010 "high 32 bits, 16 bytes"
        siphash13 range low key msg 0 17 -> assert int equals 1675352076 "low 32 bits, 17 bytes"
        (siphash13 range key msg 0 17) shr 32 -> assert int equals 2633132176 "high 32 bits, 17 bytes"
        siphash13 range low key msg 0 25 -> assert int equals 1885014393 "low 32 bits, 25 bytes"
        (siphash13 range key msg 0 25) shr 32 -> assert int equals 1171085608 "high 32 bits, 25 bytes"
        siphash13 range low key msg 0 63 -> assert int equals 3082531752 "low 32 bits, 63 bytes"
        (siphash13 range key msg 0 63) shr 32 -> assert int equals 2635698274 "high 32 bits, 63 bytes"
        siphash13 range low key msg 0 64 -> assert int equals 1263165541 "low 32 bits, 64 bytes"
        (siphash13 range key msg 0 64) shr 32 -> assert int equals 4051277804 "high 32 bits, 64 bytes"
        (siphash13 range key msg 0 15) == (siphash13 key (str slice msg 0 15)) -> assert true "whole data equals the range"
        siphash13 range low key ("xx" + msg) 2 27 -> assert int equals 1885014393 "a range inside a longer string"
        siphash13 range low "0123456789abcdef" "abc" 0 3 -> assert int equals 1783201848 "printable key"
        siphash13 range "short" msg 0 8 -> assert int equals 0 "a key that is not 16 bytes gives 0"
        siphash13 range key msg 9 8 -> assert int equals 0 "a reversed range gives 0"
        siphash13 range key msg 0 65 -> assert int equals 0 "a range past the data gives 0"
        (siphash13 range low key msg 0 8) != (siphash13 range low "0123456789abcdef" msg 0 8) -> assert true "another key, another hash"
        k1 = siphash new key
        k2 = siphash new key
        str len k1 -> assert int equals 16 "a new key has 16 bytes"
        k1 != k2 -> assert true "two new keys differ"
```

### 35.3.4. Exemplo 4: A operación nativa fronte á referencia en Ridgun simple en calquera desprazamento

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `hash` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test native matches reference => ()
      test native matches reference =
        key = "0123456789abcdef"
        msg = tensor to str (seq bytes (Tensor[U8 * 96]) 0 96)
        same as reference key msg 0 0 0 -> assert int equals 0 "native equals reference, offset 0"
        same as reference key msg 3 0 0 -> assert int equals 0 "native equals reference, offset 3"
        same as reference key msg 25 0 0 -> assert int equals 0 "native equals reference, offset 25"
```

---

## 35.4. Baixo o capó: como está construída `hash` en Ridgun puro (`src/main/ridgun/lib/hash.ridgun`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/hash.ridgun` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 35.4.1. Implementación interna: SipRound on 32-Bit Halves: One Message Word per Turn

Fíxate en como `hash.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
-- The byte at `i` as 0..255.
fn :: hs byte String Int => Int
      hs byte s i =  (str char at s i) and 255

-- The byte at `i`, or 0 at or after `to`.
fn :: hs tail String Int Int => Int
      hs tail s i to =
        | i >= to   = 0
        | otherwise = (str char at s i) and 255

fn :: hs pick Int Int Int => Int
      hs pick want hi lo =
        | want == 0 = lo
        | otherwise = (hi shl 32) or lo

-- Little-endian 32-bit word of the key at `off`.
fn :: hs key word String Int => Int
      hs key word k off =  (hs byte k off) or ((hs byte k (off + 1)) shl 8) or ((hs byte k (off + 2)) shl 16) or ((hs byte k (off + 3)) shl 24)

-- One message word per turn: v3 ^= m, 1 round(s), v0 ^= m. The 8 state values are the halves of v0..v3.
fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int => Int
      siphash13 loop s off full to n want a0 b0 a1 b1 a2 b2 a3 b3 =
        | off >= full = siphash13 last s off to n want a0 b0 a1 b1 a2 b2 a3 b3
        | otherwise   =
          t1 = (hs byte s off) or ((hs byte s (off + 1)) shl 8) or ((hs byte s (off + 2)) shl 16) or ((hs byte s (off + 3)) shl 24)
          t2 = (hs byte s (off + 4)) or ((hs byte s (off + 5)) shl 8) or ((hs byte s (off + 6)) shl 16) or ((hs byte s (off + 7)) shl 24)
          t3 = a3 xor t2
          t4 = b3 xor t1
          t5 = b0 + b1
          t6 = ((a0 + a1) + (t5 shr 32)) and 0xFFFFFFFF
          t7 = t5 and 0xFFFFFFFF
          t8 = ((a1 shl 13) or (b1 shr 19)) and 0xFFFFFFFF
          t9 = ((b1 shl 13) or (a1 shr 19)) and 0xFFFFFFFF
          t10 = t8 xor t6
          t11 = t9 xor t7
          t12 = b2 + t4
          t13 = ((a2 + t3) + (t12 shr 32)) and 0xFFFFFFFF
          t14 = t12 and 0xFFFFFFFF
          t15 = ((t3 shl 16) or (t4 shr 16)) and 0xFFFFFFFF
          t16 = ((t4 shl 16) or (t3 shr 16)) and 0xFFFFFFFF
          t17 = t15 xor t13
          t18 = t16 xor t14
          t19 = t6 + t18
          t20 = ((t7 + t17) + (t19 shr 32)) and 0xFFFFFFFF
          t21 = t19 and 0xFFFFFFFF
          t22 = ((t17 shl 21) or (t18 shr 11)) and 0xFFFFFFFF
          t23 = ((t18 shl 21) or (t17 shr 11)) and 0xFFFFFFFF
          t24 = t22 xor t20
          t25 = t23 xor t21
          t26 = t14 + t11
          t27 = ((t13 + t10) + (t26 shr 32)) and 0xFFFFFFFF
          t28 = t26 and 0xFFFFFFFF
          t29 = ((t10 shl 17) or (t11 shr 15)) and 0xFFFFFFFF
          t30 = ((t11 shl 17) or (t10 shr 15)) and 0xFFFFFFFF
          t31 = t29 xor t27
          t32 = t30 xor t28
          t33 = t20 xor t2
          t34 = t21 xor t1
          siphash13 loop s (off + 8) full to n want t33 t34 t31 t32 t28 t27 t24 t25
```

### 35.4.2. Implementación interna: Public API: `siphash13`, the Plain-Ridgun Reference, and Random Keys

Fíxate en como `hash.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
-- v0..v3 from the key (k0 = bytes 0-7, k1 = bytes 8-15, little-endian) and the constants "somepseudorandomlygeneratedbytes".
fn :: siphash13 start String String Int Int Int => Int
      siphash13 start key s from to want =
        k0l = hs key word key 0
        k0h = hs key word key 4
        k1l = hs key word key 8
        k1h = hs key word key 12
        n   = to - from
        siphash13 loop s from (from + ((n shr 3) shl 3)) to n want (k0h xor 0x736f6d65) (k0l xor 0x70736575) (k1h xor 0x646f7261) (k1l xor 0x6e646f6d) (k0h xor 0x6c796765) (k0l xor 0x6e657261) (k1h xor 0x74656462) (k1l xor 0x79746573)

-- `siphash13 range key data from to` (64 bits) and `siphash13 range low key data from to` (the low 32 bits)
-- are operations of the compiler since ridgunc 1.0.44: native, some tens of ns for a short key. They take
-- a 16-byte key and the bytes `from` (included) to `to` (excluded) of `data`; a key of another length or a
-- range outside `data` gives 0. This lib does not define them, so that the native ones are used.

-- SipHash-1-3 of the whole of `data`.
fn :: siphash13 String String => Int
      siphash13 key data =  siphash13 range key data 0 (str len data)

-- The same hash written in plain Ridgun (about 2 µs for a 25-byte key): the definition the native operation
-- is tested against, and the one to read. `want` 0 gives the low 32 bits, anything else the 64 bits.
fn :: siphash13 reference String String Int Int Int => Int
      siphash13 reference key data from to want =
        | (str len key) != 16 or from < 0 or to < from or to > (str len data) = 0
        | otherwise = siphash13 start key data from to want

-- A new random 16-byte key (from the system random source). "" when it cannot be read.
fn :: siphash new key => String
      siphash new key =  hs key of (sys random bytes 16)

fn :: hs key of (Int String) => String
      hs key of (rc, k) =
        | rc == 0 and (str len k) == 16 = k
        | otherwise                     = ""
```

---

## 35.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `hash`

- **Garantía algorítmica e de seguridade**: Unha chave doutra lonxitude, ou un rango fóra dos datos, dá `0` en vez de ler fóra de límites, e a operación nativa devolve os mesmos 64 bits que a referencia en Ridgun simple para todas as lonxitudes e desprazamentos probados.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/hash.ridgun` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test hash.ridgun`.

### As 5 Regras de Ouro ao programar con `hash`

1. **Declara `import hash` ao inicio do ficheiro** e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `hash` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `hash` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `hash` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 36** pasaremos a explorar en profundidade a lib **`hashmap`** (A lib `hashmap` — Un Mapa Hash de Chaves `String` a Calquera Valor, sobre Tensores e con Semente SipHash).
