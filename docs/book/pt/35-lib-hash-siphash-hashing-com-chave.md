# Capítulo 35: A lib `hash` — Hashing com Chave SipHash-1-3 para Tabelas de Hash

## 35.1. Por que existe a lib `hash`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `hash` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `hash`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: quando a função de hash de uma tabela de hash é pública, quem controla as chaves pode enviar milhares que caem no mesmo slot, e um pedido passa então a custar o que deveria custar um milhão (hash flooding).

A lib **`hash`** implementa **SipHash-1-3** (Aumasson & Bernstein) com uma chave de 128 bits e um resultado de 64 bits. `siphash13` calcula o hash de uma cadeia inteira; as operações nativas do compilador `siphash13 range` e `siphash13 range low` (ridgunc 1.0.44) calculam o hash de um intervalo de bytes em algumas dezenas de nanossegundos; `siphash13 reference` é o mesmo hash escrito em Ridgun simples, para ler e para testar por comparação; e `siphash new key` obtém do sistema uma chave aleatória de 16 bytes.

Num ecossistema tradicional, resolver as tarefas do domínio **`HASH`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`hash`** (`src/main/ridgun/lib/hash.ridgun`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import hash` (ou `import hash as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: hash` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `hash` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 35.2. Artefactos nativos, importação e catálogo completo da API de `hash`

No `ridgun-libs`, **`hash`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/hash.ridgun` (domínio `HASH`). Ao compilar com `stable bundle`, é empacotada num formato nativo:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hash.ridgunlib` | Distribuição e importação direta com `import hash` |

> Cada lib declara o seu próprio espaço de nomes com `module :: hash`: basta escrever `import hash` (ou `import hash as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 35.2.1. Resumo das famílias funcionais da `hash`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `siphash13` | SipHash-1-3 de uma cadeia inteira sob uma chave de 16 bytes, como um `Int` de 64 bits |
| `siphash13 range / siphash13 range low` | Operações nativas do compilador: os 64 bits, ou os 32 bits baixos, do hash de um intervalo de bytes |
| `siphash13 reference` | O mesmo hash em Ridgun simples, sobre metades de 32 bits: a definição contra a qual a operação nativa é testada |
| `siphash new key` | Uma chave aleatória de 16 bytes obtida da fonte de aleatoriedade do sistema (`""` quando esta não pode ser lida) |

### 35.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/hash.ridgun`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/hash.ridgun` (`0` tipos, `0` operadores e `11` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 35.3. Explorando a `hash` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `hash` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test hash.ridgun`.

### 35.3.1. Exemplo 1: Fluxo principal em estilo tabular com `hash`

Repare como em Ridgun os sinais `=` e os passos de transformação com `hash` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import hash

fn :: cubo de clave String String Int => Int
      cubo de clave semilla clave cubos =
        siphash13 range low semilla clave 0 (str len clave) -> h
        h % cubos
```

### 35.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `hash` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 38 libs do `ridgun-libs`:

```ridgun
import hash

fn :: huella segura String String => Int
      huella segura semilla dato =
        | (str len semilla) != 16 = 0
        | otherwise               = siphash13 semilla dato
```

### 35.3.3. Exemplo 3: Vetores SipHash-1-3 para entradas de 0 a 64 bytes: as metades baixa e alta de 32 bits

Neste exemplo prático exploramos de forma exaustiva como a `hash` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 35.3.4. Exemplo 4: A operação nativa contra a referência em Ridgun simples em qualquer deslocamento

Neste exemplo prático exploramos de forma exaustiva como a `hash` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

## 35.4. Debaixo do capô: como a `hash` é construída em Ridgun puro (`src/main/ridgun/lib/hash.ridgun`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/hash.ridgun` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 35.4.1. Implementação interna: SipRound on 32-Bit Halves: One Message Word per Turn

Observe como `hash.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 35.4.2. Implementação interna: Public API: `siphash13`, the Plain-Ridgun Reference, and Random Keys

Observe como `hash.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

## 35.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `hash`

- **Garantia algorítmica e de segurança**: Uma chave de outro comprimento, ou um intervalo fora dos dados, dá `0` em vez de ler fora dos limites, e a operação nativa devolve os mesmos 64 bits que a referência em Ridgun simples para todos os comprimentos e deslocamentos testados.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/hash.ridgun` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test hash.ridgun`.

### As 5 Regras de Ouro ao programar com a `hash`

1. **Declare `import hash` no início do ficheiro** e chame as suas funções com espaços, tal como estão declaradas, para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `hash` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `hash` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `hash` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 36** passaremos a explorar em profundidade a lib **`hashmap`** (A lib `hashmap` — Um Mapa de Hash de Chaves `String` para Qualquer Valor, sobre Tensores e com Semente SipHash).
