# Capítulo 03: A lib `list` — Listas, Mergesort $O(N \log N)$ e Mapas Chave-Valor

## 03.1. Por que existe a lib `list`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `list` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `list`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: aceder a um índice fora de limites (`IndexError` / `panic!`) ou mutar acidentalmente uma lista partilhada são dois dos erros mais comuns ao processar coleções.

A lib **`list`** fornece indexação segura com valor padrão, fatiamento (`take`, `drop`, `slice`), intervalos com passo, desduplicação estável, ordenação **mergesort $O(N \log N)$** para `[Int]` e `[String]`, e mapas associativos imutáveis `[String String]` (`kv get`, `kv put`, `kv merge`).

Num ecossistema tradicional, resolver as tarefas do domínio **`LIST`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`list`** (`src/main/ridgun/lib/list.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `list` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `list` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `list` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 03.2. Artefactos nativos, importação e catálogo completo da API de `list`

No `ridgun-libs`, **`list`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/list.rg` (domínio `LIST`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/list.rglib` | Distribuição e importação direta com `import list` |
| **Ficheiro compilado** | `target/list.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/liblist.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import list` no topo e invocar as suas funções com espaços ou underscores.

### 03.2.1. Resumo das famílias funcionais da `list`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `list nth or / list str nth or` | Leitura segura por índice devolvendo `default_val` se fora de limites |
| `list take / list drop / list slice / list reverse` | Prefixo, sufixo, subintervalo `[start, end)` e inversão recursiva de cauda |
| `list range / list range step` | Gera sequências aritméticas (`step == 0` devolve `[]` em segurança) |
| `list sort / list str sort / list dedup / list str dedup` | Ordenação mergesort $O(N \log N)$ estável e desduplicação pela primeira ocorrência |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operações sobre dicionários associativos ordenados `[String String]` |

### 03.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/list.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/list.rg` (`0` tipos, `0` operadores e `59` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: list len [Int]` | `Int` |
| `2` | `fn :: list str len [String]` | `Int` |
| `3` | `fn :: list is empty [Int]` | `Bool` |
| `4` | `fn :: list str is empty [String]` | `Bool` |
| `5` | `fn :: list nth or [Int] Int Int` | `Int` |
| `6` | `fn :: list nth [Int] Int` | `Int` |
| `7` | `fn :: list str nth or [String] Int String` | `String` |
| `8` | `fn :: list str nth [String] Int` | `String` |
| `9` | `fn :: list head [Int] Int` | `Int` |
| `10` | `fn :: list last [Int] Int` | `Int` |
| `11` | `fn :: list take [Int] Int` | `[Int]` |
| `12` | `fn :: list str take [String] Int` | `[String]` |
| `13` | `fn :: list drop [Int] Int` | `[Int]` |
| `14` | `fn :: list str drop [String] Int` | `[String]` |
| `15` | `fn :: l clamp nonneg Int` | `Int` |
| `16` | `fn :: l slice ints from [Int] Int Int` | `[Int]` |
| `17` | `fn :: list slice [Int] Int Int` | `[Int]` |
| `18` | `fn :: l slice strs from [String] Int Int` | `[String]` |
| `19` | `fn :: list str slice [String] Int Int` | `[String]` |
| `20` | `fn :: l rev ints [Int] [Int]` | `[Int]` |
| `21` | `fn :: list reverse [Int]` | `[Int]` |
| `22` | `fn :: l rev strs [String] [String]` | `[String]` |
| `23` | `fn :: list str reverse [String]` | `[String]` |
| `24` | `fn :: list range step Int Int Int` | `[Int]` |
| `25` | `fn :: list range Int Int` | `[Int]` |
| `26` | `fn :: list replicate Int Int` | `[Int]` |
| `27` | `fn :: l idx int [Int] Int Int` | `Int` |
| `28` | `fn :: list index of [Int] Int` | `Int` |
| `29` | `fn :: list contains [Int] Int` | `Bool` |
| `30` | `fn :: l idx str [String] String Int` | `Int` |
| `31` | `fn :: list str index of [String] String` | `Int` |
| `32` | `fn :: list str contains [String] String` | `Bool` |
| `33` | `fn :: list count [Int] Int` | `Int` |
| `34` | `fn :: list str count [String] String` | `Int` |
| `35` | `fn :: l dedup ints [Int] [Int]` | `[Int]` |
| `36` | `fn :: list dedup [Int]` | `[Int]` |
| `37` | `fn :: l dedup strs [String] [String]` | `[String]` |
| `38` | `fn :: list str dedup [String]` | `[String]` |
| `39` | `fn :: l merge ints [Int] [Int]` | `[Int]` |
| `40` | `fn :: l sort ints len [Int] Int` | `[Int]` |
| `41` | `fn :: list sort [Int]` | `[Int]` |
| `42` | `fn :: list is sorted [Int]` | `Bool` |
| `43` | `fn :: l str le loop String String Int Int Int` | `Bool` |
| `44` | `fn :: l str le String String` | `Bool` |
| `45` | `fn :: l merge strs [String] [String]` | `[String]` |
| `46` | `fn :: l sort strs len [String] Int` | `[String]` |
| `47` | `fn :: list str sort [String]` | `[String]` |
| `48` | `fn :: l kv key (String String)` | `String` |
| `49` | `fn :: l kv val (String String)` | `String` |
| `50` | `fn :: kv empty` | `[String String]` |
| `51` | `fn :: kv len [String String]` | `Int` |
| `52` | `fn :: kv has [String String] String` | `Bool` |
| `53` | `fn :: kv get or [String String] String String` | `String` |
| `54` | `fn :: kv get [String String] String` | `String` |
| `55` | `fn :: kv put [String String] String String` | `[String String]` |
| `56` | `fn :: kv remove [String String] String` | `[String String]` |
| `57` | `fn :: kv keys [String String]` | `[String]` |
| `58` | `fn :: kv values [String String]` | `[String]` |
| `59` | `fn :: kv merge [String String] [String String]` | `[String String]` |

---

## 03.3. Explorando a `list` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `list` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test list.rg`.

### 03.3.1. Exemplo 1: Fluxo principal em estilo tabular com `list`

Repare como em Ridgun os sinais `=` e os passos de transformação com `list` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### 03.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `list` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno (base : [String String]) => (String, [String])
      configurar entorno base =
        cfg1 = kv put base "host" "0.0.0.0"
        cfg2 = kv put cfg1 "port" "8080"
        host = kv get or cfg2 "host" "127.0.0.1"
        (host, kv keys cfg2)
```

### 03.3.3. Exemplo 3: Indexação segura (`nth or`, `head or`, `last or`), fatiamento (`take`, `drop`, `slice`), intervalos (`range`, `iota`, `replicate`) e deduplicação (`dedup`, `count eq`)

Neste exemplo prático exploramos de forma exaustiva como a `list` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        ss = ["aa", "bb", "cc", "dd"]
        _ = assert int equals (list len xs) 5 "AC1: list_len 5"
        _ = assert int equals (list str len ss) 4 "AC1: list_str_len 4"
        _ = assert true (list is empty []) "AC1: list_is_empty []"
        _ = assert false (list is empty xs) "AC1: list_is_empty non-empty"
        _ = assert true (list str is empty []) "AC1: list_str_is_empty []"
        _ = assert false (list str is empty ss) "AC1: list_str_is_empty non-empty"

        _ = assert int equals (list nth xs 0) 10 "AC1: list_nth 0"
        _ = assert int equals (list nth xs 4) 50 "AC1: list_nth 4"
        _ = assert int equals (list nth or xs 99 (0 - 1)) (0 - 1) "AC1: list_nth_or out of bounds"
        _ = assert int equals (list nth or xs (0 - 1) (0 - 1)) (0 - 1) "AC1: list_nth_or negative"
        _ = assert str eq (list str nth ss 2) "cc" "AC1: list_str_nth 2"
        _ = assert str eq (list str nth or ss 99 "oob") "oob" "AC1: list_str_nth_or out of bounds"
        _ = assert int equals (list head xs 0) 10 "AC1: list_head"
        _ = assert int equals (list head [] 99) 99 "AC1: list_head empty fallback"
        _ = assert int equals (list last xs 0) 50 "AC1: list_last"
        _ = assert int equals (list last [] 99) 99 "AC1: list_last empty fallback"

        _ = assert eq (list take xs 3) [10, 20, 30]
        _ = assert eq (list take xs 0) []
        _ = assert eq (list take xs (0 - 2)) []
        _ = assert eq (list take xs 99) [10, 20, 30, 40, 50]
        _ = assert eq (list drop xs 3) [40, 50]
        _ = assert eq (list drop xs 0) xs
        _ = assert eq (list drop xs 99) []
        _ = assert eq (list slice xs 1 4) [20, 30, 40]
        _ = assert eq (list slice xs (0 - 3) 2) [10, 20]
        _ = assert eq (list slice xs 4 2) []
        _ = assert eq (list str slice ss 1 3) ["bb", "cc"]

        _ = assert eq (list reverse xs) [50, 40, 30, 20, 10]
        _ = assert eq (list str reverse ss) ["dd", "cc", "bb", "aa"]

        _ = assert eq (list range 1 5) [1, 2, 3, 4, 5]
        _ = assert eq (list range 3 3) [3]
        _ = assert eq (list range 5 1) []
        _ = assert eq (list range step 0 6 2) [0, 2, 4, 6]
        _ = assert eq (list range step 6 0 (0 - 2)) [6, 4, 2, 0]
        _ = assert eq (list range step 1 5 0) []
        _ = assert eq (list replicate 3 7) [7, 7, 7]
        _ = assert eq (list replicate 0 7) []

        _ = assert true (list contains xs 30) "AC1: list_contains 30"
        _ = assert false (list contains xs 99) "AC1: list_contains 99"
        _ = assert true (list str contains ss "cc") "AC1: list_str_contains cc"
        _ = assert false (list str contains ss "zz") "AC1: list_str_contains zz"
        _ = assert int equals (list index of xs 30) 2 "AC1: list_index_of 30"
        _ = assert int equals (list index of xs 99) (0 - 1) "AC1: list_index_of missing"
        _ = assert int equals (list str index of ss "dd") 3 "AC1: list_str_index_of dd"
        _ = assert int equals (list count [1, 2, 1, 3, 1] 1) 3 "AC1: list_count"
        _ = assert int equals (list str count ["a", "b", "a"] "a") 2 "AC1: list_str_count"
        _ = assert eq (list dedup [3, 1, 3, 2, 1, 3]) [3, 1, 2]
        _ = assert eq (list str dedup ["b", "a", "b", "c", "a"]) ["b", "a", "c"]
        ()
```

### 03.3.4. Exemplo 4: Ordenação determinística $O(N \log N)$ (`list sort int`, `list sort desc`, `list sort str`, `list is sorted`)

Neste exemplo prático exploramos de forma exaustiva como a `list` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3, (0 - 50)]
        sorted = list sort unsorted
        _ = assert eq sorted [(0 - 50), (0 - 5), 0, 3, 7, 7, 19, 42, 100]
        _ = assert true (list is sorted sorted) "AC2: list_is_sorted after sort"
        _ = assert false (list is sorted unsorted) "AC2: list_is_sorted false on unsorted"
        _ = assert true (list is sorted []) "AC2: empty list is sorted"
        _ = assert true (list is sorted [1]) "AC2: singleton list is sorted"
        _ = assert eq (list sort []) []
        _ = assert eq (list sort [1]) [1]
        _ = assert eq (list sort [5, 4, 3, 2, 1]) [1, 2, 3, 4, 5]
        s_strs = list str sort ["delta", "alpha", "charlie", "bravo", "alpha", "al", ""]
        _ = assert eq s_strs ["", "al", "alpha", "alpha", "bravo", "charlie", "delta"]
        ()
```

### 03.3.5. Exemplo 5: Mapas associativos chave-valor imutáveis (`kv put`, `kv get or`, `kv has`, `kv remove`, `kv keys`, `kv values`, `kv len`)

Neste exemplo prático exploramos de forma exaustiva como a `list` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test kv associative map => ()
      test kv associative map =
        m0 = kv empty
        _ = assert int equals (kv len m0) 0 "AC3: kv_empty len 0"
        m1 = kv put m0 "host" "127.0.0.1"
        m2 = kv put m1 "port" "8080"
        m3 = kv put m2 "port" "9090"
        _ = assert int equals (kv len m3) 2 "AC3: kv_put updates in-place without duplicating key"
        _ = assert true (kv has m3 "host") "AC3: kv_has host"
        _ = assert false (kv has m3 "missing") "AC3: kv_has missing"
        _ = assert str eq (kv get m3 "port") "9090" "AC3: kv_get updated port"
        _ = assert str eq (kv get m3 "missing") "" "AC3: kv_get missing returns empty"
        _ = assert str eq (kv get or m3 "mode" "prod") "prod" "AC3: kv_get_or default"
        _ = assert eq (kv keys m3) ["host", "port"]
        _ = assert eq (kv values m3) ["127.0.0.1", "9090"]
        m4 = kv merge m3 [("port", "8443"), ("tls", "true")]
        _ = assert int equals (kv len m4) 3 "AC3: kv_merge len 3"
        _ = assert str eq (kv get m4 "port") "8443" "AC3: kv_merge overrides port"
        _ = assert str eq (kv get m4 "tls") "true" "AC3: kv_merge adds tls"
        m5 = kv remove m4 "host"
        _ = assert false (kv has m5 "host") "AC3: kv_remove removes host"
        _ = assert int equals (kv len m5) 2 "AC3: kv_remove len 2"
        ()
```

---

## 03.4. Debaixo do capô: como a `list` é construída em Ridgun puro (`src/main/ridgun/lib/list.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/list.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 03.4.1. Implementação interna: List Length & Emptiness

Observe como `list.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: list len [Int]    => Int
      list len []       =  0
      list len (_:rest) =  1 + (list len rest)

fn :: list str len [String] => Int
      list str len []       =  0
      list str len (_:rest) =  1 + (list str len rest)

fn :: list is empty [Int] => Bool
      list is empty []    =  True
      list is empty _     =  False

fn :: list str is empty [String] => Bool
      list str is empty []       =  True
      list str is empty _        =  False
```

### 03.4.2. Implementação interna: Slicing (`take`, `drop`, `slice`) & Reversal

Observe como `list.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: list take [Int]    Int => [Int]
      list take []       _   =  []
      list take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list take rest (n - 1))

fn :: list str take [String] Int => [String]
      list str take []       _   =  []
      list str take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list str take rest (n - 1))

fn :: list drop [Int]    Int => [Int]
      list drop []       _   =  []
      list drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list drop rest (n - 1)

fn :: list str drop [String] Int => [String]
      list str drop []       _   =  []
      list str drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list str drop rest (n - 1)

fn :: l clamp nonneg Int => Int
      l clamp nonneg x   =
        | x < 0     = 0
        | otherwise = x

fn :: l slice ints from [Int] Int Int => [Int]
      l slice ints from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list take (list drop xs s0) (end_idx - s0)

fn :: list slice [Int] Int   Int     => [Int]
      list slice xs    start end_idx =  l slice ints from xs (l clamp nonneg start) end_idx

fn :: l slice strs from [String] Int Int => [String]
      l slice strs from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list str take (list str drop xs s0) (end_idx - s0)

fn :: list str slice [String] Int Int => [String]
      list str slice xs start end_idx = l slice strs from xs (l clamp nonneg start) end_idx

fn :: l rev ints [Int]    [Int] => [Int]
      l rev ints []       acc   =  acc
      l rev ints (x:rest) acc   =  l rev ints rest ([x] :: acc)
```

### 03.4.3. Implementação interna: Search, Count & Deduplication

Observe como `list.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: l idx int [Int] Int Int => Int
      l idx int [] _ _ = 0 - 1
      l idx int (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx int rest tgt (idx + 1)

fn :: list index of [Int] Int => Int
      list index of xs    tgt =  l idx int xs tgt 0

fn :: list contains [Int] Int => Bool
      list contains xs    tgt =  (list index of xs tgt) >= 0

fn :: l idx str [String] String Int => Int
      l idx str [] _ _ = 0 - 1
      l idx str (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx str rest tgt (idx + 1)

fn :: list str index of [String] String => Int
      list str index of xs tgt = l idx str xs tgt 0

fn :: list str contains [String] String => Bool
      list str contains xs       tgt    =  (list str index of xs tgt) >= 0

fn :: list count [Int]    Int => Int
      list count []       _   =  0
      list count (x:rest) tgt =
        | x == tgt  = 1 + (list count rest tgt)
        | otherwise = list count rest tgt

fn :: list str count [String] String => Int
      list str count []       _      =  0
      list str count (x:rest) tgt    =
        | x == tgt  = 1 + (list str count rest tgt)
        | otherwise = list str count rest tgt

fn :: l dedup ints [Int]    [Int] => [Int]
      l dedup ints []       seen  =  list reverse seen
      l dedup ints (x:rest) seen  =
        | list contains seen x = l dedup ints rest seen
        | otherwise            = l dedup ints rest ([x] :: seen)

fn :: list dedup [Int] => [Int]
      list dedup xs    =  l dedup ints xs []

fn :: l dedup strs [String] [String] => [String]
      l dedup strs []       seen     =  list str reverse seen
      l dedup strs (x:rest) seen     =
        | list str contains seen x = l dedup strs rest seen
        | otherwise                = l dedup strs rest ([x] :: seen)
```

### 03.4.4. Implementação interna: Associative Key-Value Map (`[(String, String)]`)

Observe como `list.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: l kv key (String String) => String
      l kv key (k, _)          =  k

fn :: l kv val (String String) => String
      l kv val (_, v)          =  v

fn :: kv empty => [String String]
      kv empty =  []

fn :: kv len [String String] => Int
      kv len []              =  0
      kv len (_:rest)        =  1 + (kv len rest)

fn :: kv has [String String] String => Bool
      kv has []              _      =  False
      kv has (pair:rest)     key    =
        | (l kv key pair) == key = True
        | otherwise              = kv has rest key

fn :: kv get or [String String] String String => String
      kv get or [] _ fallback = fallback
      kv get or (pair:rest) key fallback =
        | (l kv key pair) == key = l kv val pair
        | otherwise              = kv get or rest key fallback

fn :: kv get [String String] String => String
      kv get pairs           key    =  kv get or pairs key ""

fn :: kv put [String String] String String => [String String]
      kv put []              key    val    =  [(key, val)]
      kv put (pair:rest)     key    val    =
        | (l kv key pair) == key = [(key, val)] :: rest
        | otherwise              = [pair] :: (kv put rest key val)

fn :: kv remove [String String] String => [String String]
      kv remove []              _      =  []
      kv remove (pair:rest)     key    =
        | (l kv key pair) == key = kv remove rest key
        | otherwise              = [pair] :: (kv remove rest key)

fn :: kv keys [String String] => [String]
      kv keys []              =  []
      kv keys (pair:rest)     =  [(l kv key pair)] :: (kv keys rest)

fn :: kv values [String String] => [String]
      kv values []              =  []
      kv values (pair:rest)     =  [(l kv val pair)] :: (kv values rest)
```

---

## 03.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `list`

- **Garantia algorítmica e de segurança**: Ordenação determinística $O(N \log N)$ no pior caso (sem o $O(N^2)$ patológico do Quicksort) e preservação da ordem de inserção nos mapas `kv`.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/list.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test list.rg`.

### As 5 Regras de Ouro ao programar com a `list`

1. **Declare `import list` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `list` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `list` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `list` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 04** passaremos a explorar em profundidade a lib **`btree`** (A lib `btree` — Árvores AVL Persistentes $O(\log N)$, Conjuntos e Heaps).
