# Capítol 36: La lib `hashmap` — Un Mapa Hash de Claus `String` a Qualsevol Valor, sobre Tensors i amb Llavor SipHash

## 36.1. Per què existeix la lib `hashmap`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `hashmap` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `hashmap`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: comptar paraules o agrupar cent mil registres amb una llista d'associació és quadràtic, i un arbre ordenat paga un logaritme i una assignació a cada inserció quan l'únic que necessites és trobar una clau.

La lib **`hashmap`** implementa `HashMap V`, un mapa de claus `String` a valors de qualsevol tipus, construït sobre tensors: una taula de ranures amb adreçament obert i sondeig lineal, plena com a màxim fins a la meitat, apunta a tensors densos de claus i de valors mantinguts en ordre d'inserció. El hash de les claus es calcula amb SipHash-1-3 (la lib `hash`) sota una llavor aleatòria per mapa; `hashmap put`, `hashmap add`, `hashmap get` i `hashmap has` triguen un temps esperat constant, i `hashmap pairs` retorna les entrades en ordre d'inserció.

En un ecosistema tradicional, resoldre les tasques del domini **`HASHMAP`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`hashmap`** (`src/main/ridgun/lib/hashmap.ridgun`) aborda el problema amb quatre principis innegociables:

1. **Declara `import hashmap` (o `import hashmap as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: hashmap` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `hashmap` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 36.2. Artefactes natius, importació i catàleg complet de l'API de `hashmap`

A `ridgun-libs`, **`hashmap`** és una **lib** de primera classe situada a `src/main/ridgun/lib/hashmap.ridgun` (domini `HASHMAP`). En compilar amb `stable bundle`, s'empaqueta en un format natiu:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hashmap.ridgunlib` | Distribució i importació directa amb `import hashmap` |

> Cada lib declara el seu propi espai de noms amb `module :: hashmap`: n'hi ha prou d'escriure `import hashmap` (o `import hashmap as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 36.2.1. Resum de famílies funcionals de `hashmap`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `hashmap empty` | Un mapa nou i buit; el tipus dels seus valors queda fixat pel primer valor desat |
| `hashmap put / hashmap get / hashmap has` | Insereix o substitueix, llegeix amb un valor per defecte i comprova la pertinença, en temps esperat constant |
| `hashmap add` | Suma un `Int` al valor d'una clau (una clau absent comença a 0): un comptador en un sol sondeig |
| `hashmap size / hashmap pairs` | El nombre de claus, i les entrades `[String V]` en ordre d'inserció |

### 36.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/hashmap.ridgun`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/hashmap.ridgun` (`1` tipus, `0` operadors i `35` funcions):

**Tipus algebraics i registres (`type`) de `hashmap`:**

```ridgun
type HashMap V = fill: [V], vals: [Tensor[V * n]], slots: Tensor[Int * n], keys: Tensor[String * n], cap: Int, room: Int, count: Tensor[Int * k], seed: String
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 36.3. Explorant `hashmap` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `hashmap` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test hashmap.ridgun`.

### 36.3.1. Exemple 1: Flux principal en estil tabular amb `hashmap`

Observa com en Ridgun els signes `=` i els passos de transformació amb `hashmap` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import hashmap

fn :: contar visitas [String]     (HashMap Int) => HashMap Int
      contar visitas []           m             =  m
      contar visitas (ruta:resto) m             =  contar visitas resto (hashmap add m ruta 1)
```

### 36.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `hashmap` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 38 libs de `ridgun-libs`:

```ridgun
import hashmap

fn :: visitas de (HashMap Int) String => Int
      visitas de m ruta =
        | hashmap has m ruta = hashmap get m ruta 0
        | otherwise          = 0
```

### 36.3.3. Exemple 3: El mapa buit, `hashmap put`, substitució, `hashmap get` amb un valor per defecte i `hashmap pairs`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `hashmap` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 36.3.4. Exemple 4: Comptadors amb `hashmap add`: sumes, claus absents i arribada a zero

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `hashmap` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 36.3.5. Exemple 5: Claus inusuals: la cadena buida, bytes per sobre de 127 i claus de 10 KB que difereixen en l'últim byte

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `hashmap` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 36.3.6. Exemple 6: Valors de tipus registre: un `HashMap` de registres definits per l'usuari

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `hashmap` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 36.3.7. Exemple 7: Creixement: 20 000 claus, totes les claus trobades i ordre d'inserció preservat

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `hashmap` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 36.4. Sota el capó: com està construïda `hashmap` en Ridgun pur (`src/main/ridgun/lib/hashmap.ridgun`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/hashmap.ridgun` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 36.4.1. Implementació interna: Hash

Fixa't en com `hashmap.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 36.4.2. Implementació interna: Slots

Fixa't en com `hashmap.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 36.4.3. Implementació interna: Table

Fixa't en com `hashmap.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 36.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `hashmap`

- **Garantia algorísmica i de seguretat**: El mapa s'actualitza in situ i creix duplicant la mida, de manera que `n` insercions costen $O(n)$ en total; fes servir sempre el mapa que retorna una operació (`ADR-0009`). Una llavor aleatòria per mapa impedeix que un atacant triï claus que col·lideixin.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/hashmap.ridgun` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test hashmap.ridgun`.

### Les 5 Regles d'Or en programar amb `hashmap`

1. **Declara `import hashmap` a l'inici del fitxer** i crida les seves funcions amb espais, tal com estan declarades, perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `hashmap` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `hashmap` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `hashmap` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 37** passarem a explorar en profunditat la lib **`tls`** (La lib `tls` — Client TLS 1.3 i TLS 1.2, Validació de Cadenes X.509 i Verificació del Hostname).
