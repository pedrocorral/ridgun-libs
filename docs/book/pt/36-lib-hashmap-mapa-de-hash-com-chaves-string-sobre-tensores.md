# Capítulo 36: A lib `hashmap` — Um Mapa de Hash de Chaves `String` para Qualquer Valor, sobre Tensores e com Semente SipHash

## 36.1. Por que existe a lib `hashmap`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `hashmap` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `hashmap`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: contar palavras ou agrupar cem mil registos com uma lista de associação é quadrático, e uma árvore ordenada paga um logaritmo e uma alocação em cada inserção quando tudo o que precisa é de encontrar uma chave.

A lib **`hashmap`** implementa `HashMap V`, um mapa de chaves `String` para valores de qualquer tipo, construído sobre tensores: uma tabela de slots com endereçamento aberto e sondagem linear, no máximo meio cheia, aponta para tensores densos de chaves e de valores mantidos por ordem de inserção. O hash das chaves é calculado com SipHash-1-3 (a lib `hash`) sob uma semente aleatória por mapa; `hashmap put`, `hashmap add`, `hashmap get` e `hashmap has` demoram tempo esperado constante, e `hashmap pairs` devolve as entradas por ordem de inserção.

Num ecossistema tradicional, resolver as tarefas do domínio **`HASHMAP`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`hashmap`** (`src/main/ridgun/lib/hashmap.ridgun`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import hashmap` (ou `import hashmap as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: hashmap` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `hashmap` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 36.2. Artefactos nativos, importação e catálogo completo da API de `hashmap`

No `ridgun-libs`, **`hashmap`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/hashmap.ridgun` (domínio `HASHMAP`). Ao compilar com `stable bundle`, é empacotada num formato nativo:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hashmap.ridgunlib` | Distribuição e importação direta com `import hashmap` |

> Cada lib declara o seu próprio espaço de nomes com `module :: hashmap`: basta escrever `import hashmap` (ou `import hashmap as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 36.2.1. Resumo das famílias funcionais da `hashmap`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `hashmap empty` | Um novo mapa vazio; o tipo dos seus valores é fixado pelo primeiro valor guardado |
| `hashmap put / hashmap get / hashmap has` | Insere ou substitui, lê com um valor por omissão e testa a pertença, em tempo esperado constante |
| `hashmap add` | Soma um `Int` ao valor de uma chave (uma chave em falta começa em 0): um contador numa só sondagem |
| `hashmap size / hashmap pairs` | O número de chaves, e as entradas `[String V]` por ordem de inserção |

### 36.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/hashmap.ridgun`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/hashmap.ridgun` (`1` tipos, `0` operadores e `35` funções):

**Tipos algébricos e registos (`type`) da `hashmap`:**

```ridgun
type HashMap V = fill: [V], vals: [Tensor[V * n]], slots: Tensor[Int * n], keys: Tensor[String * n], cap: Int, room: Int, count: Tensor[Int * k], seed: String
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 36.3. Explorando a `hashmap` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `hashmap` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test hashmap.ridgun`.

### 36.3.1. Exemplo 1: Fluxo principal em estilo tabular com `hashmap`

Repare como em Ridgun os sinais `=` e os passos de transformação com `hashmap` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import hashmap

fn :: contar visitas [String]     (HashMap Int) => HashMap Int
      contar visitas []           m             =  m
      contar visitas (ruta:resto) m             =  contar visitas resto (hashmap add m ruta 1)
```

### 36.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `hashmap` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 38 libs do `ridgun-libs`:

```ridgun
import hashmap

fn :: visitas de (HashMap Int) String => Int
      visitas de m ruta =
        | hashmap has m ruta = hashmap get m ruta 0
        | otherwise          = 0
```

### 36.3.3. Exemplo 3: O mapa vazio, `hashmap put`, substituição, `hashmap get` com valor por omissão e `hashmap pairs`

Neste exemplo prático exploramos de forma exaustiva como a `hashmap` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 36.3.4. Exemplo 4: Contadores com `hashmap add`: somas, chaves em falta e chegada a zero

Neste exemplo prático exploramos de forma exaustiva como a `hashmap` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 36.3.5. Exemplo 5: Chaves invulgares: a cadeia vazia, bytes acima de 127 e chaves de 10 KB que diferem no último byte

Neste exemplo prático exploramos de forma exaustiva como a `hashmap` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 36.3.6. Exemplo 6: Valores de registo: um `HashMap` de registos definidos pelo utilizador

Neste exemplo prático exploramos de forma exaustiva como a `hashmap` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 36.3.7. Exemplo 7: Crescimento: 20 000 chaves, todas as chaves encontradas e ordem de inserção preservada

Neste exemplo prático exploramos de forma exaustiva como a `hashmap` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

## 36.4. Debaixo do capô: como a `hashmap` é construída em Ridgun puro (`src/main/ridgun/lib/hashmap.ridgun`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/hashmap.ridgun` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 36.4.1. Implementação interna: Hash

Observe como `hashmap.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 36.4.2. Implementação interna: Slots

Observe como `hashmap.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 36.4.3. Implementação interna: Table

Observe como `hashmap.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

## 36.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `hashmap`

- **Garantia algorítmica e de segurança**: O mapa é atualizado in-place e cresce por duplicação, pelo que `n` inserções custam $O(n)$ no total; use sempre o mapa que uma operação devolve (`ADR-0009`). Uma semente aleatória por mapa impede um atacante de escolher chaves que colidam.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/hashmap.ridgun` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test hashmap.ridgun`.

### As 5 Regras de Ouro ao programar com a `hashmap`

1. **Declare `import hashmap` no início do ficheiro** e chame as suas funções com espaços, tal como estão declaradas, para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `hashmap` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `hashmap` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `hashmap` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 37** passaremos a explorar em profundidade a lib **`tls`** (A lib `tls` — Cliente TLS 1.3 e TLS 1.2, Validação de Cadeias X.509 e Verificação de Hostname).
