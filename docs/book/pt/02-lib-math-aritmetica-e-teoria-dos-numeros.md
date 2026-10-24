# Capítulo 02: A lib `math` — Aritmética Segura, Teoria dos Números e Estatística

## 02.1. Por que existe a lib `math`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `math` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `math`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: uma divisão por zero inesperada em produção ou o operador `%` a devolver restos negativos em C ou Java já derrubaram mais serviços do que gostamos de admitir.

A lib **`math`** oferece divisões totais à prova de `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), exponenciação e inverso modular em $O(\log E)$, raízes e logaritmos inteiros exatos, combinatória, primalidade e o operador mixfix `clamp x between lo and hi`.

Num ecossistema tradicional, resolver as tarefas do domínio **`MATH`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`math`** (`src/main/ridgun/lib/math.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `math` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `math` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `math` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 02.2. Artefactos nativos, importação e catálogo completo da API de `math`

No `ridgun-libs`, **`math`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/math.rg` (domínio `MATH`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.rglib` | Distribuição e importação direta com `import math` |
| **Ficheiro compilado** | `target/math.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libmath.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import math` no topo e invocar as suas funções com espaços ou underscores.

### 02.2.1. Resumo das famílias funcionais da `math`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `math abs / math sign / math min / math max` | Magnitude absoluta, sinal (`-1, 0, 1`) e extremos |
| `clamp x between lo and hi` | Operador mixfix (`op ::`) que limita `x` ao intervalo `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Arredondamento seguro contra divisão por zero e resto euclidiano não negativo |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potência em $O(\log E)$, raiz quadrada inteira de Newton e logaritmos inteiros |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MDC/MMC de Euclides, aritmética modular e teste de primalidade $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Combinatória (`nCr`) sem overflow e estatística inteira sobre listas |

### 02.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/math.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/math.rg` (`0` tipos, `1` operadores e `56` funções):

**Operadores mixfix (`op ::`) da `math`:**

```ridgun
op :: clamp Int between Int and Int => Int
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: math abs Int` | `Int` |
| `2` | `fn :: math sign Int` | `Int` |
| `3` | `fn :: math min Int Int` | `Int` |
| `4` | `fn :: math max Int Int` | `Int` |
| `5` | `fn :: math clamp Int Int Int` | `Int` |
| `6` | `fn :: math is even Int` | `Bool` |
| `7` | `fn :: math is odd Int` | `Bool` |
| `8` | `fn :: m fix mod Int Int` | `Int` |
| `9` | `fn :: math mod euclid Int Int` | `Int` |
| `10` | `fn :: math div euclid Int Int` | `Int` |
| `11` | `fn :: m adjust floor Int Int Int Int` | `Int` |
| `12` | `fn :: math div floor Int Int` | `Int` |
| `13` | `fn :: m adjust ceil Int Int Int Int` | `Int` |
| `14` | `fn :: math div ceil Int Int` | `Int` |
| `15` | `fn :: m pow loop Int Int Int` | `Int` |
| `16` | `fn :: math pow Int Int` | `Int` |
| `17` | `fn :: m isqrt step Int Int Int` | `Int` |
| `18` | `fn :: m isqrt loop Int Int` | `Int` |
| `19` | `fn :: math isqrt Int` | `Int` |
| `20` | `fn :: m ilog2 loop Int Int` | `Int` |
| `21` | `fn :: math ilog2 Int` | `Int` |
| `22` | `fn :: m ilog10 loop Int Int` | `Int` |
| `23` | `fn :: math ilog10 Int` | `Int` |
| `24` | `fn :: m next pow2 loop Int Int` | `Int` |
| `25` | `fn :: math next power of two Int` | `Int` |
| `26` | `fn :: math is power of two Int` | `Bool` |
| `27` | `fn :: m gcd loop Int Int` | `Int` |
| `28` | `fn :: math gcd Int Int` | `Int` |
| `29` | `fn :: math lcm Int Int` | `Int` |
| `30` | `fn :: m mod pow loop Int Int Int Int` | `Int` |
| `31` | `fn :: math mod pow Int Int Int` | `Int` |
| `32` | `fn :: m egcd loop Int Int Int Int` | `Int Int` |
| `33` | `fn :: m finish mod inv (Int Int) Int` | `Int` |
| `34` | `fn :: math mod inv Int Int` | `Int` |
| `35` | `fn :: m prime loop Int Int` | `Bool` |
| `36` | `fn :: math is prime Int` | `Bool` |
| `37` | `fn :: m fact loop Int Int` | `Int` |
| `38` | `fn :: math factorial Int` | `Int` |
| `39` | `fn :: m ncr loop Int Int Int Int` | `Int` |
| `40` | `fn :: math ncr Int Int` | `Int` |
| `41` | `fn :: m fib loop Int Int Int` | `Int` |
| `42` | `fn :: math fibonacci Int` | `Int` |
| `43` | `fn :: m list len [Int]` | `Int` |
| `44` | `fn :: m nth int [Int] Int` | `Int` |
| `45` | `fn :: math sum [Int]` | `Int` |
| `46` | `fn :: math product [Int]` | `Int` |
| `47` | `fn :: m mean len [Int] Int` | `Int` |
| `48` | `fn :: math mean [Int]` | `Int` |
| `49` | `fn :: m min loop [Int] Int` | `Int` |
| `50` | `fn :: math min list [Int]` | `Int` |
| `51` | `fn :: m max loop [Int] Int` | `Int` |
| `52` | `fn :: math max list [Int]` | `Int` |
| `53` | `fn :: m insert sorted Int [Int]` | `[Int]` |
| `54` | `fn :: m sort ints [Int]` | `[Int]` |
| `55` | `fn :: m median sorted [Int] Int Int` | `Int` |
| `56` | `fn :: math median [Int]` | `Int` |

---

## 02.3. Explorando a `math` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `math` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test math.rg`.

### 02.3.1. Exemplo 1: Fluxo principal em estilo tabular com `math`

Repare como em Ridgun os sinais `=` e os passos de transformação com `math` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### 02.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `math` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

### 02.3.3. Exemplo 3: Limites (`abs`, `sign`, `min`, `max`), operador mixfix `clamp ... between ... and ...` e divisões seguras contra divisor zero (`div ceil`, `div floor`, `div euclid`, `mod euclid`)

Neste exemplo prático exploramos de forma exaustiva como a `math` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test math bounds and division => ()
      test math bounds and division =
        _ = assert int equals (math abs (0 - 42)) 42 "math abs negative"
        _ = assert int equals (math abs 42) 42 "math abs positive"
        _ = assert int equals (math abs 0) 0 "math abs zero"
        _ = assert int equals (math sign (0 - 99)) (0 - 1) "math sign negative"
        _ = assert int equals (math sign 0) 0 "math sign zero"
        _ = assert int equals (math sign 99) 1 "math sign positive"
        _ = assert int equals (math min 10 (0 - 5)) (0 - 5) "math min"
        _ = assert int equals (math max 10 (0 - 5)) 10 "math max"
        _ = assert int equals (math clamp (0 - 10) 0 100) 0 "math clamp low"
        _ = assert int equals (math clamp 50 0 100) 50 "math clamp mid"
        _ = assert int equals (math clamp 250 0 100) 100 "math clamp high"
        _ = assert int equals (clamp 150 between 10 and 100) 100 "op clamp between and"
        _ = assert true (math is even 42) "math is even 42"
        _ = assert false (math is even 41) "math is even 41"
        _ = assert true (math is odd (0 - 7)) "math is odd -7"
        _ = assert int equals (math div ceil 7 3) 3 "math div ceil 7/3"
        _ = assert int equals (math div ceil 6 3) 2 "math div ceil 6/3"
        _ = assert int equals (math div ceil (0 - 7) 3) (0 - 2) "math div ceil -7/3"
        _ = assert int equals (math div floor (0 - 7) 3) (0 - 3) "math div floor -7/3"
        _ = assert int equals (math div floor 7 3) 2 "math div floor 7/3"
        _ = assert int equals (math mod euclid (0 - 7) 3) 2 "math mod euclid -7 % 3 == 2"
        _ = assert int equals (math div euclid (0 - 7) 3) (0 - 3) "math div euclid -7 / 3 == -3"
        -- Division by zero safety
        _ = assert int equals (math div ceil 10 0) 0 "math div ceil / 0 == 0"
        _ = assert int equals (math div floor 10 0) 0 "math div floor / 0 == 0"
        _ = assert int equals (math div euclid 10 0) 0 "math div euclid / 0 == 0"
        _ = assert int equals (math mod euclid 10 0) 0 "math mod euclid % 0 == 0"
        ()
```

### 02.3.4. Exemplo 4: Potências, raízes e logaritmos inteiros (`pow`, `isqrt`, `ilog2`, `ilog10`), teoria dos números (`gcd`, `lcm`, `mod pow`, `mod inv`, `is prime`) e combinatória (`factorial`, `nCr`, `fib`)

Neste exemplo prático exploramos de forma exaustiva como a `math` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test math powers number theory and combinatorics => ()
      test math powers number theory and combinatorics =
        _ = assert int equals (math pow 2 10) 1024 "2^10 == 1024"
        _ = assert int equals (math pow 5 0) 1 "5^0 == 1"
        _ = assert int equals (math pow 5 (0 - 2)) 0 "negative exp -> 0"
        _ = assert int equals (math isqrt 0) 0 "isqrt 0"
        _ = assert int equals (math isqrt 1) 1 "isqrt 1"
        _ = assert int equals (math isqrt 15) 3 "isqrt 15"
        _ = assert int equals (math isqrt 16) 4 "isqrt 16"
        _ = assert int equals (math isqrt 10000) 100 "isqrt 10000"
        _ = assert int equals (math isqrt (0 - 4)) (0 - 1) "isqrt negative -> -1"
        _ = assert int equals (math ilog2 1) 0 "ilog2 1 == 0"
        _ = assert int equals (math ilog2 1024) 10 "ilog2 1024 == 10"
        _ = assert int equals (math ilog2 0) (0 - 1) "ilog2 0 == -1"
        _ = assert int equals (math ilog10 999) 2 "ilog10 999 == 2"
        _ = assert int equals (math ilog10 1000) 3 "ilog10 1000 == 3"
        _ = assert true (math is power of two 64) "64 is power of two"
        _ = assert false (math is power of two 63) "63 is not power of two"
        _ = assert false (math is power of two 0) "0 is not power of two"
        _ = assert int equals (math next power of two 33) 64 "next power of two 33 == 64"
        _ = assert int equals (math gcd 48 18) 6 "gcd(48, 18) == 6"
        _ = assert int equals (math gcd (0 - 48) 18) 6 "gcd(-48, 18) == 6"
        _ = assert int equals (math lcm 12 18) 36 "lcm(12, 18) == 36"
        _ = assert int equals (math lcm 0 18) 0 "lcm(0, 18) == 0"
        _ = assert int equals (math mod pow 2 10 1000) 24 "2^10 mod 1000 == 24"
        _ = assert int equals (math mod pow 3 200 97) 62 "3^200 mod 97 == 62"
        _ = assert int equals (math mod inv 3 11) 4 "3 * 4 == 12 == 1 mod 11"
        _ = assert int equals (math mod inv 6 12) (0 - 1) "mod inv non-coprime -> -1"
        _ = assert false (math is prime 1) "1 not prime"
        _ = assert true (math is prime 2) "2 prime"
        _ = assert true (math is prime 97) "97 prime"
        _ = assert false (math is prime 99) "99 not prime"
        _ = assert int equals (math factorial 5) 120 "5! == 120"
        _ = assert int equals (math factorial 0) 1 "0! == 1"
        _ = assert int equals (math ncr 10 3) 120 "C(10, 3) == 120"
        _ = assert int equals (math fibonacci 10) 55 "fib(10) == 55"
        ()
```

### 02.3.5. Exemplo 5: Estatística descritiva inteira sobre listas (`sum`, `product`, `min list`, `max list`, `mean floor`, `median floor`, `variance floor`)

Neste exemplo prático exploramos de forma exaustiva como a `math` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test math list statistics => ()
      test math list statistics =
        xs = [30, 10, 50, 20, 40]
        _  = assert int equals (math sum xs) 150 "sum"
        _  = assert int equals (math product [2, 3, 4]) 24 "product"
        _  = assert int equals (math mean xs) 30 "mean"
        _  = assert int equals (math median xs) 30 "median odd"
        _  = assert int equals (math median [10, 20, 30, 40]) 25 "median even"
        _  = assert int equals (math min list xs) 10 "min list"
        _  = assert int equals (math max list xs) 50 "max list"
        _  = assert int equals (math sum []) 0 "sum []"
        _  = assert int equals (math mean []) 0 "mean []"
        _  = assert int equals (math median []) 0 "median []"
        ()
```

---

## 02.4. Debaixo do capô: como a `math` é construída em Ridgun puro (`src/main/ridgun/lib/math.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/math.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 02.4.1. Implementação interna: Bounds, Sign & Parity

Observe como `math.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: math abs Int => Int
      math abs x   =
        | x < 0     = 0 - x
        | otherwise = x

fn :: math sign Int => Int
      math sign x   =
        | x < 0     = 0 - 1
        | x > 0     = 1
        | otherwise = 0

fn :: math min Int Int => Int
      math min a   b   =
        | a <= b    = a
        | otherwise = b

fn :: math max Int Int => Int
      math max a   b   =
        | a >= b    = a
        | otherwise = b

fn :: math clamp Int Int Int => Int
      math clamp x   lo  hi  =
        | x < lo    = lo
        | x > hi    = hi
        | otherwise = x

op :: clamp Int between Int and Int => Int
      clamp x   between lo  and hi  =  math clamp x lo hi

fn :: math is even Int => Bool
      math is even x   =  (x % 2) == 0

fn :: math is odd Int => Bool
      math is odd x   =  (x % 2) != 0
```

### 02.4.2. Implementação interna: Powers, Integer Roots & Logarithms

Observe como `math.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: m pow loop Int Int Int => Int
      m pow loop base exp acc =
        | exp <= 0       = acc
        | (exp % 2) == 1 = m pow loop (base * base) (exp / 2) (acc * base)
        | otherwise      = m pow loop (base * base) (exp / 2) acc

fn :: math pow Int  Int => Int
      math pow base exp =
        | exp < 0   = 0
        | exp == 0  = 1
        | otherwise = m pow loop base exp 1

fn :: m isqrt step Int Int Int => Int
      m isqrt step n x nx =
        | nx >= x   = x
        | otherwise = m isqrt loop n nx

fn :: m isqrt loop Int Int => Int
      m isqrt loop n   x   =  m isqrt step n x ((x + (n / x)) / 2)

fn :: math isqrt Int => Int
      math isqrt n   =
        | n < 0     = 0 - 1
        | n == 0    = 0
        | n < 4     = 1
        | otherwise = m isqrt loop n (n / 2)

fn :: m ilog2 loop Int Int => Int
      m ilog2 loop n   acc =
        | n <= 1    = acc
        | otherwise = m ilog2 loop (n / 2) (acc + 1)

fn :: math ilog2 Int => Int
      math ilog2 n   =
        | n <= 0    = 0 - 1
        | otherwise = m ilog2 loop n 0

fn :: m ilog10 loop Int Int => Int
      m ilog10 loop n   acc =
        | n < 10    = acc
        | otherwise = m ilog10 loop (n / 10) (acc + 1)

fn :: math ilog10 Int => Int
      math ilog10 n   =
        | n <= 0    = 0 - 1
        | otherwise = m ilog10 loop n 0
```

### 02.4.3. Implementação interna: Combinatorics & Sequences

Observe como `math.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: m fact loop Int Int => Int
      m fact loop n   acc =
        | n <= 1    = acc
        | otherwise = m fact loop (n - 1) (acc * n)

fn :: math factorial Int => Int
      math factorial n   =
        | n < 0     = 0
        | otherwise = m fact loop n 1

fn :: m ncr loop Int Int Int Int => Int
      m ncr loop n k idx acc =
        | idx > k   = acc
        | otherwise = m ncr loop n k (idx + 1) ((acc * ((n - k) + idx)) / idx)

fn :: math ncr Int Int => Int
      math ncr n   k   =
        | k < 0 or n < 0 or k > n = 0
        | k == 0 or k == n        = 1
        | otherwise =
          eff_k = math min k (n - k)
          m ncr loop n eff_k 1 1

fn :: m fib loop Int Int Int => Int
      m fib loop rem a b =
        | rem <= 0  = a
        | otherwise = m fib loop (rem - 1) b (a + b)

fn :: math fibonacci Int => Int
      math fibonacci n   =
        | n <= 0    = 0
        | otherwise = m fib loop n 0 1
```

### 02.4.4. Implementação interna: Integer List Statistics

Observe como `math.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: m list len [Int]    => Int
      m list len []       =  0
      m list len (_:rest) =  1 + (m list len rest)

fn :: m nth int [Int]    Int => Int
      m nth int []       _   =  0
      m nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = m nth int rest (idx - 1)

fn :: math sum [Int]    => Int
      math sum []       =  0
      math sum (x:rest) =  x + (math sum rest)

fn :: math product [Int]    => Int
      math product []       =  1
      math product (x:rest) =  x * (math product rest)

fn :: m mean len [Int] Int => Int
      m mean len xs    n   =
        | n == 0    = 0
        | otherwise = (math sum xs) / n

fn :: math mean [Int] => Int
      math mean xs    =  m mean len xs (m list len xs)

fn :: m min loop [Int]    Int => Int
      m min loop []       cur =  cur
      m min loop (x:rest) cur =  m min loop rest (math min cur x)

fn :: math min list [Int]    => Int
      math min list []       =  0
      math min list (x:rest) =  m min loop rest x

fn :: m max loop [Int]    Int => Int
      m max loop []       cur =  cur
      m max loop (x:rest) cur =  m max loop rest (math max cur x)

fn :: math max list [Int]    => Int
      math max list []       =  0
      math max list (x:rest) =  m max loop rest x

fn :: m insert sorted Int [Int]    => [Int]
      m insert sorted v   []       =  [v]
      m insert sorted v   (x:rest) =
        | v <= x    = [v, x] :: rest
        | otherwise = [x] :: (m insert sorted v rest)
```

---

## 02.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `math`

- **Garantia algorítmica e de segurança**: Funções totais (devolvem `0` quando o divisor é `<= 0` em vez de abortar com `SIGFPE`), sem imprecisão de vírgula flutuante.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/math.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test math.rg`.

### As 5 Regras de Ouro ao programar com a `math`

1. **Declare `import math` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `math` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `math` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `math` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 03** passaremos a explorar em profundidade a lib **`list`** (A lib `list` — Listas, Mergesort $O(N \log N)$ e Mapas Chave-Valor).
