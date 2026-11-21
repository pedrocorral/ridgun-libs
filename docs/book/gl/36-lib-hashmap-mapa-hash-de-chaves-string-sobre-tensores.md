# Capítulo 36: A lib `hashmap` — Un Mapa Hash de Chaves `String` a Calquera Valor, sobre Tensores e con Semente SipHash

## 36.1. Por que existe a lib `hashmap`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `hashmap` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `hashmap`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: contar palabras ou agrupar cen mil rexistros cunha lista de asociación é cuadrático, e unha árbore ordenada paga un logaritmo e unha asignación de memoria en cada inserción cando o único que necesitas é atopar unha chave.

A lib **`hashmap`** implementa `HashMap V`, un mapa de chaves `String` a valores de calquera tipo, construído sobre tensores: unha táboa de rañuras con direccionamento aberto e sondaxe lineal, chea como máximo ata a metade, apunta a tensores densos de chaves e de valores mantidos en orde de inserción. O hash das chaves calcúlase con SipHash-1-3 (a lib `hash`) cunha semente aleatoria por mapa; `hashmap put`, `hashmap add`, `hashmap get` e `hashmap has` levan tempo esperado constante, e `hashmap pairs` devolve as entradas en orde de inserción.

Nun ecosistema tradicional, resolver as tarefas do dominio **`HASHMAP`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`hashmap`** (`src/main/ridgun/lib/hashmap.ridgun`) aborda o problema con catro principios innegociables:

1. **Declara `import hashmap` (ou `import hashmap as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: hashmap` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `hashmap` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 36.2. Artefactos nativos, importación e catálogo completo da API de `hashmap`

En `ridgun-libs`, **`hashmap`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/hashmap.ridgun` (dominio `HASHMAP`). Ao compilar con `stable bundle`, empaquétase nun formato nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hashmap.ridgunlib` | Distribución e importación directa con `import hashmap` |

> Cada lib declara o seu propio espazo de nomes con `module :: hashmap`: abonda con escribir `import hashmap` (ou `import hashmap as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 36.2.1. Resumo de familias funcionais de `hashmap`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `hashmap empty` | Un mapa novo e baleiro; o tipo dos seus valores queda fixado polo primeiro valor gardado |
| `hashmap put / hashmap get / hashmap has` | Insire ou substitúe, le cun valor predeterminado e comproba a pertenza, en tempo esperado constante |
| `hashmap add` | Suma un `Int` ao valor dunha chave (unha chave ausente comeza en 0): un contador nunha soa sondaxe |
| `hashmap size / hashmap pairs` | O número de chaves e as entradas `[String V]` en orde de inserción |

### 36.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/hashmap.ridgun`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/hashmap.ridgun` (`1` tipos, `0` operadores e `35` funcións):

**Tipos alxébricos e rexistros (`type`) de `hashmap`:**

```ridgun
type HashMap V = fill: [V], vals: [Tensor[V * n]], slots: Tensor[Int * n], keys: Tensor[String * n], cap: Int, room: Int, count: Tensor[Int * k], seed: String
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: hm hash String String` | `Int` |
| `2` | `fn :: hm seed16 String` | `String` |
| `3` | `fn :: hm read seed Int` | `String` |
| `4` | `fn :: hm new seed` | `String` |
| `5` | `fn :: hm slot hash Int` | `Int` |
| `6` | `fn :: hm probe Tensor[Int * n] Tensor[String * m] Int String Int Int` | `Int` |
| `7` | `fn :: hm free Tensor[Int * n] Int Int` | `Int` |
| `8` | `fn :: hashmap empty` | `HashMap V` |
| `9` | `fn :: hm size (HashMap V)` | `Int` |
| `10` | `fn :: hm bump Tensor[Int * k]` | `()` |
| `11` | `fn :: hm vt [Tensor[V * n]]` | `Tensor[V * n]` |
| `12` | `fn :: hm rehash Tensor[Int * n] Tensor[Int * m] Int Int Int` | `()` |
| `13` | `fn :: hm grow slots (HashMap V)` | `HashMap V` |
| `14` | `fn :: hm copy Tensor[String * n] Tensor[V * n] Tensor[String * m] Tensor[V * m] Int Int` | `()` |
| `15` | `fn :: hm grow dense (HashMap V) [V]` | `HashMap V` |
| `16` | `fn :: hm make room (HashMap V)` | `HashMap V` |
| `17` | `fn :: hm room slots (HashMap V)` | `HashMap V` |
| `18` | `fn :: hm room dense (HashMap V)` | `HashMap V` |
| `19` | `fn :: hm ensure vals (HashMap V) V` | `HashMap V` |
| `20` | `fn :: hm insert Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] Int Int String V` | `()` |
| `21` | `fn :: hm put go (HashMap V) (HashMap V) String V` | `HashMap V` |
| `22` | `fn :: hm put at (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int` | `HashMap V` |
| `23` | `fn :: hm put slot (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int` | `HashMap V` |
| `24` | `fn :: hashmap put (HashMap V) String V` | `HashMap V` |
| `25` | `fn :: hm add go (HashMap Int) (HashMap Int) String Int` | `HashMap Int` |
| `26` | `fn :: hm add at (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int` | `HashMap Int` |
| `27` | `fn :: hm add slot (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int` | `HashMap Int` |
| `28` | `fn :: hashmap add (HashMap Int) String Int` | `HashMap Int` |
| `29` | `fn :: hm lookup Tensor[Int * c] Tensor[String * r] Int String Int` | `Int` |
| `30` | `fn :: hm get at Tensor[V * n] Int V` | `V` |
| `31` | `fn :: hashmap get (HashMap V) String V` | `V` |
| `32` | `fn :: hashmap has (HashMap V) String` | `Bool` |
| `33` | `fn :: hashmap size (HashMap V)` | `Int` |
| `34` | `fn :: hm pairs loop Tensor[String * n] Tensor[V * n] Int [String V]` | `[String V]` |
| `35` | `fn :: hashmap pairs (HashMap V)` | `[String V]` |

---

## 36.3. Explorando `hashmap` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `hashmap` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test hashmap.ridgun`.

### 36.3.1. Exemplo 1: Fluxo principal en estilo tabular con `hashmap`

Observa como en Ridgun os signos `=` e os pasos de transformación con `hashmap` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import hashmap

fn :: contar visitas [String]     (HashMap Int) => HashMap Int
      contar visitas []           m             =  m
      contar visitas (ruta:resto) m             =  contar visitas resto (hashmap add m ruta 1)
```

### 36.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `hashmap` está deseñada para compoñerse con gardas booleanas `|` e co resto das 38 libs de `ridgun-libs`:

```ridgun
import hashmap

fn :: visitas de (HashMap Int) String => Int
      visitas de m ruta =
        | hashmap has m ruta = hashmap get m ruta 0
        | otherwise          = 0
```

### 36.3.3. Exemplo 3: O mapa baleiro, `hashmap put`, substitución, `hashmap get` cun valor predeterminado e `hashmap pairs`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `hashmap` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test hashmap basics => ()
      test hashmap basics =
        e = hashmap empty
        hashmap get e "a" 7 -> assert int equals 7 "AC1: get on empty gives the default"
        hashmap has e "a" -> assert false "AC1: has on empty"
        hashmap size e -> assert int equals 0 "AC1: size of empty"
        hashmap pairs e -> assert eq []

        m = hashmap put (hashmap put (hashmap put hashmap empty "b" 2) "a" 1) "c" 3
        m2 = hashmap put m "a" 10
        hashmap get m2 "a" 0 -> assert int equals 10 "AC1: put replaces the value"
        hashmap get m2 "b" 0 -> assert int equals 2 "AC1: get b"
        hashmap get m2 "zz" (0 - 1) -> assert int equals (0 - 1) "AC1: missing key gives the default"
        hashmap has m2 "c" -> assert true "AC1: has c"
        hashmap has m2 "zz" -> assert false "AC1: has missing"
        hashmap size m2 -> assert int equals 3 "AC1: replacing does not add a key"
        hashmap pairs m2 -> assert eq [("b", 2), ("a", 10), ("c", 3)]
        ()
```

### 36.3.4. Exemplo 4: Contadores con `hashmap add`: sumas, chaves ausentes e chegada a cero

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `hashmap` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test hashmap add => ()
      test hashmap add =
        m = hashmap add (hashmap add (hashmap add hashmap empty "x" 2) "y" 5) "x" 3
        hashmap get m "x" 0 -> assert int equals 5 "AC2: add sums"
        hashmap get m "y" 0 -> assert int equals 5 "AC2: a missing key starts at 0"
        m2 = hashmap add m "y" (0 - 5)
        hashmap get m2 "y" 99 -> assert int equals 0 "AC2: add can reach 0 and the key stays"
        hashmap has m2 "y" -> assert true "AC2: has after reaching 0"
        hashmap pairs m2 -> assert eq [("x", 5), ("y", 0)]
        ()
```

### 36.3.5. Exemplo 5: Chaves pouco habituais: a cadea baleira, bytes por riba de 127 e chaves de 10 KB que difiren no último byte

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `hashmap` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test hashmap unusual keys => ()
      test hashmap unusual keys =
        hi = (char from code 200) + (char from code 255)
        la = kb10 "a"
        lb = kb10 "b"
        m = hashmap put (hashmap put (hashmap put (hashmap put hashmap empty "" 1) hi 2) la 3) lb 4
        hashmap get m "" 0 -> assert int equals 1 "AC3: empty key"
        hashmap get m hi 0 -> assert int equals 2 "AC3: bytes >= 128"
        hashmap get m la 0 -> assert int equals 3 "AC3: 10 KB key"
        hashmap get m lb 0 -> assert int equals 4 "AC3: 10 KB key differing in the last byte"
        hashmap has m (kb10 "c") -> assert false "AC3: another 10 KB key is missing"
        hashmap has m (char from code 200) -> assert false "AC3: prefix of a key is missing"
        hashmap size m -> assert int equals 4 "AC3: four keys"
        ()
```

### 36.3.6. Exemplo 6: Valores de tipo rexistro: un `HashMap` de rexistros definidos polo usuario

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `hashmap` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test hashmap record values => ()
      test hashmap record values =
        m = hashmap put (hashmap put (hashmap put hashmap empty "/a" (Visit "/a" 3)) "/b" (Visit "/b" 7)) "/a" (Visit "/a" 4)
        hashmap get m "/a" (Visit "" 0) -> assert eq (Visit "/a" 4)
        hashmap get m "/b" (Visit "" 0) -> assert eq (Visit "/b" 7)
        hashmap get m "/c" (Visit "" 0) -> assert eq (Visit "" 0)
        hits (hashmap get m "/a" (Visit "" 0)) -> assert int equals 4 "AC4: record field"
        ()
```

### 36.3.7. Exemplo 7: Crecemento: 20 000 chaves, todas as chaves atopadas e orde de inserción preservada

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `hashmap` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test hashmap growth => ()
      test hashmap growth =
        n = 20000
        m = put many hashmap empty 0 n
        hashmap size m -> assert int equals n "AC1: 20000 keys after growing"
        all found m 0 n -> assert true "AC1: every key found after growing"
        ps = hashmap pairs m
        sum values ps 0 -> assert int equals (n * (n - 1) / 2) "AC1: pairs hold every value"
        first keys ps 3 [] -> assert eq ["key 0", "key 1", "key 2"]
        fill 1 + count [] + str len seed -> assert int equals 7 "Program functions named like fields still work"
        ()
```

---

## 36.4. Baixo o capó: como está construída `hashmap` en Ridgun puro (`src/main/ridgun/lib/hashmap.ridgun`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/hashmap.ridgun` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 36.4.1. Implementación interna: Hash

Fíxate en como `hashmap.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
-- 31 bits of SipHash-1-3 of the key, with the map's 16-byte seed as the hash key (the compiler's native
-- `siphash13 range low`, ridgunc 1.0.44), plus 1 so a used slot is never 0.
-- Keys are always compared when the hashes match.
-- The per-map random seed stops chosen keys from colliding on purpose.
fn :: hm hash String String => Int
      hm hash seed key =  ((siphash13 range low seed key 0 (str len key)) % 2147483648) + 1

-- Exactly 16 bytes: SipHash takes a 128-bit key.
fn :: hm seed16 String => String
      hm seed16 s =
        | (str len s) == 16 = s
        | otherwise         = str slice (s + "ridgun-hashmap-0") 0 16

fn :: hm read seed Int => String
      hm read seed fd =
        | fd < 0    = hm seed16 (int to str (sys time ms))
        | otherwise =
          s = sys read fd fd 16
          sys close fd -> ()
          hm seed16 s

fn :: hm new seed => String
      hm new seed = hm read seed (sys open mode "/dev/urandom" "r")
```

### 36.4.2. Implementación interna: Slots

Fíxate en como `hashmap.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: hm slot hash Int => Int
      hm slot hash s = s / 2147483648

-- Slot of key k with hash h: the slot that holds it, or the free slot where it goes.
-- Hot path: the slot is decoded inline (each call costs about 20 ns).
fn :: hm probe Tensor[Int * n] Tensor[String * m] Int String Int Int => Int
      hm probe slots keys cap k h i =
        | slots_(i) == 0                          = i
        | slots_(i) / 2147483648 != h             = hm probe slots keys cap k h ((i + 1) % cap)
        | keys_(slots_(i) % 2147483648) == k      = i
        | otherwise                               = hm probe slots keys cap k h ((i + 1) % cap)

-- First free slot from i; for rehashing, where every key is known to be new.
fn :: hm free Tensor[Int * n] Int Int => Int
      hm free slots cap i =
        | slots_(i) == 0 = i
        | otherwise      = hm free slots cap ((i + 1) % cap)
```

### 36.4.3. Implementación interna: Table

Fíxate en como `hashmap.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: hashmap empty => HashMap V
      hashmap empty = HashMap [] [] (Tensor[Int * 16]) (Tensor[String * 8]) 16 8 (Tensor[Int * 1]) (hm new seed)

fn :: hm size (HashMap V) => Int
      hm size m = (count m)_(0)

fn :: hm bump Tensor[Int * k] => ()
      hm bump t =
        t_(0) = t_(0) + 1

fn :: hm vt [Tensor[V * n]] => Tensor[V * n]
      hm vt (t:_) = t

-- Copies every used slot to the new table, by its stored hash. Int only.
fn :: hm rehash Tensor[Int * n] Tensor[Int * m] Int Int Int => ()
      hm rehash old new i ocap ncap =
        | i >= ocap     = ()
        | old_(i) == 0  = hm rehash old new (i + 1) ocap ncap
        | otherwise     =
          s = old_(i)
          new_(hm free new ncap ((hm slot hash s) % ncap)) = s
          hm rehash old new (i + 1) ocap ncap

fn :: hm grow slots (HashMap V) => HashMap V
      hm grow slots m =
        ncap = 2 * (cap m)
        ns   = Tensor[Int * ncap]
        hm rehash (slots m) ns 0 (cap m) ncap
        m with slots = ns, cap = ncap

fn :: hm copy Tensor[String * n] Tensor[V * n] Tensor[String * m] Tensor[V * m] Int Int => ()
      hm copy ok ov nk nv i n =
        | i >= n    = ()
        | otherwise =
          nk_(i) = ok_(i)
          nv_(i) = ov_(i)
          hm copy ok ov nk nv (i + 1) n

fn :: hm grow dense (HashMap V) [V] => HashMap V
      hm grow dense m (d:_) =
        nr = 2 * (room m)
        nk = Tensor[String * nr]
        nv = Tensor[V * nr] with d
        hm copy (keys m) (hm vt (vals m)) nk nv 0 (hm size m)
        m with keys = nk, vals = [nv], room = nr

-- Keeps the slot table at most half full and room for one more key.
fn :: hm make room (HashMap V) => HashMap V
      hm make room m = hm room dense (hm room slots m)

fn :: hm room slots (HashMap V) => HashMap V
      hm room slots m =
        | 2 * ((hm size m) + 1) > cap m = hm grow slots m
        | otherwise                      = m

fn :: hm room dense (HashMap V) => HashMap V
      hm room dense m =
        | (hm size m) + 1 > room m = hm grow dense m (fill m)
        | otherwise                  = m

-- The first insert supplies the fill value for the value tensor.
fn :: hm ensure vals (HashMap V) V => HashMap V
      hm ensure vals m v = m with fill = [v], vals = [Tensor[V * (room m)] with v]

-- Puts a new key at the next position and points slot i at it.
fn :: hm insert Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] Int Int String V => ()
      hm insert vt st kt cnt i h k v =
        pos = cnt_(0)
        kt_(pos) = k
        vt_(pos) = v
        st_(i) = h * 2147483648 + pos
        cnt_(0) = pos + 1

-- The hot paths take the record apart once in the clause: each field accessor
-- is a call of about 40 ns.

fn :: hm put go (HashMap V) (HashMap V) String V => HashMap V
      hm put go m (HashMap []   _      _  _  _   _    _   _   ) k v = hashmap put (hm ensure vals m v) k v
      hm put go m (HashMap _ (vt:_) st kt cap room cnt seed) k v =
        | 2 * (cnt_(0) + 1) > cap or cnt_(0) + 1 > room = hashmap put (hm make room m) k v
        | otherwise = hm put at m vt st kt cnt k v (hm hash seed k) cap

fn :: hm put at (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int => HashMap V
      hm put at m vt st kt cnt k v h cap = hm put slot m vt st kt cnt k v h (hm probe st kt cap k h (h % cap))

fn :: hm put slot (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int => HashMap V
      hm put slot m vt st kt cnt k v h i =
        | st_(i) == 0 =
          hm insert vt st kt cnt i h k v
          m
        | otherwise =
          vt_(st_(i) % 2147483648) = v
          m

fn :: hashmap put (HashMap V) String V => HashMap V
      hashmap put m k v = hm put go m m k v

fn :: hm add go (HashMap Int) (HashMap Int) String Int => HashMap Int
      hm add go m (HashMap []   _      _  _  _   _    _   _   ) k d = hashmap add (hm ensure vals m 0) k d
      hm add go m (HashMap _ (vt:_) st kt cap room cnt seed) k d =
        | 2 * (cnt_(0) + 1) > cap or cnt_(0) + 1 > room = hashmap add (hm make room m) k d
        | otherwise = hm add at m vt st kt cnt k d (hm hash seed k) cap

fn :: hm add at (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int => HashMap Int
      hm add at m vt st kt cnt k d h cap = hm add slot m vt st kt cnt k d h (hm probe st kt cap k h (h % cap))

fn :: hm add slot (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int => HashMap Int
      hm add slot m vt st kt cnt k d h i =
        | st_(i) == 0 =
          hm insert vt st kt cnt i h k d
          m
        | otherwise =
          p = st_(i) % 2147483648
          vt_(p) = vt_(p) + d
          m

-- Adds d to the value of k; a missing key starts at 0. For counting.
fn :: hashmap add (HashMap Int) String Int => HashMap Int
      hashmap add m k d = hm add go m m k d

-- Slot content for k: 0 when k is missing, otherwise hash * 2^31 + position.
fn :: hm lookup Tensor[Int * c] Tensor[String * r] Int String Int => Int
      hm lookup st kt cap k h = st_(hm probe st kt cap k h (h % cap))

fn :: hm get at Tensor[V * n] Int V => V
      hm get at vt s d =
        | s == 0    = d
        | otherwise = vt_(s % 2147483648)

-- The value of k, or d when k is missing.
fn :: hashmap get (HashMap V) String V => V
      hashmap get (HashMap _ []     _  _  _   _ _   _   ) k d = d
      hashmap get (HashMap _ (vt:_) st kt cap _ _   seed) k d = hm get at vt (hm lookup st kt cap k (hm hash seed k)) d

fn :: hashmap has (HashMap V) String => Bool
      hashmap has (HashMap _ []     _  _  _   _ _ _   ) k = False
      hashmap has (HashMap _ (vt:_) st kt cap _ _ seed) k = hm lookup st kt cap k (hm hash seed k) != 0

fn :: hashmap size (HashMap V) => Int
      hashmap size m = hm size m

fn :: hm pairs loop Tensor[String * n] Tensor[V * n] Int [String V] => [String V]
      hm pairs loop ks vt i acc =
        | i < 0     = acc
        | otherwise = hm pairs loop ks vt (i - 1) ([(ks_(i), vt_(i))] :: acc)

-- Every (key, value) pair, in the order the keys were first inserted.
fn :: hashmap pairs (HashMap V) => [String V]
      hashmap pairs m =
        | hm size m == 0 = []
        | otherwise      = hm pairs loop (keys m) (hm vt (vals m)) ((hm size m) - 1) []
```

---

## 36.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `hashmap`

- **Garantía algorítmica e de seguridade**: O mapa actualízase no lugar e medra duplicando o seu tamaño, polo que `n` insercións custan $O(n)$ en total; usa sempre o mapa que devolve unha operación (`ADR-0009`). Unha semente aleatoria por mapa impide que un atacante escolla chaves que colidan.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/hashmap.ridgun` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test hashmap.ridgun`.

### As 5 Regras de Ouro ao programar con `hashmap`

1. **Declara `import hashmap` ao inicio do ficheiro** e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `hashmap` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `hashmap` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `hashmap` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 37** pasaremos a explorar en profundidade a lib **`tls`** (A lib `tls` — Cliente TLS 1.3 e TLS 1.2, Validación de Cadeas X.509 e Verificación do Nome de Host).
